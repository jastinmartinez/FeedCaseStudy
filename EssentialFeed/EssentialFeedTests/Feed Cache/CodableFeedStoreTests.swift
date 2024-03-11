//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 15/10/23.
//

import XCTest
import EssentialFeed


final class CodableFeedStore {
    
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
    
    private var storeURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let cache = try! JSONDecoder().decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encode = try! JSONEncoder().encode(cache)
        try! encode.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.retrieve  { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, but instead got \(result)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "wait for cache retrieval")
        
        sut.retrieve  { firstResult in
            sut.retrieve  { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, but instead got \(firstResult), \(secondResult)")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let exp = expectation(description: "wait for cache retrieval")
        let feed = uniqueImageFeed().locals
        let timeStamp = Date()
        
        sut.insert(feed, timestamp: timeStamp)  { insertedResult in
            XCTAssertNil(insertedResult, "Expected feed to be inserted successfully.")
            sut.retrieve  { retrieveResult in
                switch (retrieveResult) {
                case let .found(feed: retrievedFeed, timestamp: retrievedTimeStamp):
                    XCTAssertEqual(retrievedFeed, feed)
                    XCTAssertEqual(retrievedTimeStamp, timeStamp)
                default:
                    XCTFail("Expected found twice result with feed \(feed) and timestamp \(timeStamp), but instead got \(retrieveResult)")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    // - MARK: Helpers
    
    private func makeSUT() -> CodableFeedStore {
        let sut = CodableFeedStore()
        return sut
    }
}
