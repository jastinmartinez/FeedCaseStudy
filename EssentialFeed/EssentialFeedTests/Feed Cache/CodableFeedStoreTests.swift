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
        let feed: [CodableFeedImage]
        let timestamp: Date
        var localFeed: [LocalFeedImage] {
            return feed.map({ $0.local })
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
        let sut = makeSUT()
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

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let expectedFeed = uniqueImageFeed().locals
        let expectedTimestamp = Date()
        let exp = expectation(description: "wait cache retrieval")

        sut.insert(expectedFeed, timestamp: expectedTimestamp, completion: { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")

            sut.retrieve { firstResult in
                sut.retrieve { secondResult in

                    switch (firstResult ,secondResult) {

                    case  let (.found(firstFound), .found(secondFound)):

                        XCTAssertEqual(firstFound.feed, expectedFeed)
                        XCTAssertEqual(firstFound.timestamp, expectedTimestamp)

                        XCTAssertEqual(secondFound.feed, expectedFeed)
                        XCTAssertEqual(secondFound.timestamp, expectedTimestamp)

                    default:
                        XCTFail("expect found with feed \(expectedFeed) and timestamp \(expectedTimestamp) instead got \(firstResult) and \(secondResult)")
                    }
                    exp.fulfill()
                }
            }
        })

        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT( file: StaticString = #file,
                          line: UInt = #line) -> CodableFeedStore {
        let storeURL = testSpecificStoreURL()
        let store = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(instance: store, file: file, line: line)
        return store
    }
    
    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory,
                                 in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
