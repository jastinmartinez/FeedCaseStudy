//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 15/10/23.
//

import XCTest
import EssentialFeed


final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        deleteStoreArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        deleteStoreArtifacts()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let expectedFeed = uniqueImageFeed().locals
        let expectedTimestamp = Date()
        
        insert((expectedFeed, expectedTimestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: expectedFeed, timestamp: expectedTimestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let expectedFeed = uniqueImageFeed().locals
        let expectedTimestamp = Date()
        
        insert((expectedFeed, expectedTimestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: expectedFeed, timestamp: expectedTimestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_insert_overridesPreviousInsertedCacheValues() {
        let sut = makeSUT()
        
        let firstInsertionError = insert((uniqueImageFeed().locals, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "expect to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().locals
        let latesTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latesTimestamp), to: sut)
        
        XCTAssertNil(latestInsertionError, "expect to insert cache successfully")
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latesTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(insertionError)
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expect empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_DeliversErrorOnDeletionError() {
        let notDeletePermissionURL = cacheDirectory()
        let sut = makeSUT(storeURL: notDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion fail")
        expect(sut, toRetrieve: .empty)
    }
    
    //    MARK: HELPERS
    
    private func makeSUT(storeURL: URL? = nil,
                         file: StaticString = #file,
                         line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: FeedStore,
                        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }
    
    private func deleteCache(from sut: FeedStore) -> Error? {
        var capturedError: Error? = nil
        
        let exp = expectation(description: "wait for deletion")
        sut.deleteCachedFeed { deletionError in
            capturedError = deletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }
    
    @discardableResult private func insert(_ expect: (feed: [LocalFeedImage], timestamp: Date),
                                           to sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait cache retrieval")
        var capturedError: Error? = nil
        
        sut.insert(expect.feed, timestamp: expect.timestamp, completion: { insertionError in
            capturedError = insertionError
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }
    
    private func expect(_ sut: FeedStore,
                        toRetrieve expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "wait cache retrieval")
        
        sut.retrieve { capturedResult in
            switch (capturedResult, expectedResult) {
            case let (.empty, .empty): break
            case let (.failure, .failure): break
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(expected.feed,
                               retrieved.feed,
                               file: file,
                               line: line)
                XCTAssertEqual(expected.timestamp,
                               retrieved.timestamp,
                               file: file,
                               line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(capturedResult) instead"
                        ,file: file,
                        line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func testSpecificStoreURL() -> URL {
        cacheDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cacheDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory,
                                 in: .userDomainMask).first!
    }
    
    private func deleteStoreArtifacts() {
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory,
                                 in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func deleteStoreArtifacts() {
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
}
