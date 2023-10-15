//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 15/10/23.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)
            .first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)
            .first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for retrieve")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("expect empty but instead got \(result)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait cache retrieval")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("expect empty but instead got \(firstResult) and \(secondResult)")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let expectedFeed = uniqueImageFeed().locals
        let expectedTimestamp = Date()
        let exp = expectation(description: "wait cache retrieval")
        
        sut.insert(expectedFeed, timestamp: expectedTimestamp, completion: { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
           
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                    
                case  let .found(capturedFeed, capturedTimestamp):
                    XCTAssertEqual(capturedFeed, expectedFeed)
                    XCTAssertEqual(capturedTimestamp, expectedTimestamp)
                    
                default:
                    XCTFail("expect found with feed \(expectedFeed) and timestamp \(expectedTimestamp) instead got \(retrieveResult)")
                }
                exp.fulfill()
            }
        })
        
        wait(for: [exp], timeout: 1.0)
    }
}
