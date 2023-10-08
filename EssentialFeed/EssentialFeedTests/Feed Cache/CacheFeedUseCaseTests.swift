//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 8/10/23.
//

import Foundation
import XCTest
import EssentialFeed

class FeedStore {
    
    private (set) var deleteCachedFeedCallCount = 0
    private (set) var insertCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        
    }
}

class LocalFeedLoader {
    
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_RequestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError) 
        
        XCTAssertEqual(store.insertCount, 0)
    }
    
    //   MARK: Helpers
    private func makeSUT(file: StaticString = #file,
                          line: UInt = #line) -> (sut: LocalFeedLoader,
                               store: FeedStore) {
        let store = FeedStore()
        let localFeedLoader = LocalFeedLoader(store: store)
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: localFeedLoader, file: file, line: line)
        return (localFeedLoader, store)
    }
    
    private func uniqueItems() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
}
