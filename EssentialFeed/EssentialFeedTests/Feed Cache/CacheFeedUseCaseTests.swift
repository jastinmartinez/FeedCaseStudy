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
    
    typealias Deletion = (Error?) -> Void
    typealias Insertion = (Error?) -> Void
    private(set) var deletions = [Deletion]()
    private(set) var insertions = [Insertion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    func deleteCachedFeed(completion: @escaping Deletion) {
        deletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletions[index](error)
    }
    
    func  completeDeletionSuccesfully(at index: Int = 0) {
        deletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertions[index](error)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping Insertion) {
        receivedMessages.append(.insert(items, timestamp))
        insertions.append(completion)
    }
}

class LocalFeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessagesStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_RequestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        
        sut.save(items) {_ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        
        sut.save(items) {_ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    
    func test_save_requestNewCacheInsertionWithTimestapmOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItems(), uniqueItems()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) {_ in }
        store.completeDeletionSuccesfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        let exp = expectation(description: "wait for save")
        var capturedError: Error?
        
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as? NSError, deletionError)
    }
    
    func test_save_failsOnInsetionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        let exp = expectation(description: "wait for save")
        var capturedError: Error?
        
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        store.completeDeletionSuccesfully()
        store.completeInsertion(with: deletionError)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as? NSError, deletionError)
    }
    
    //   MARK: Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                          line: UInt = #line) -> (sut: LocalFeedLoader,
                               store: FeedStore) {
        let store = FeedStore()
        let localFeedLoader = LocalFeedLoader(store: store,
                                              currentDate: currentDate)
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
