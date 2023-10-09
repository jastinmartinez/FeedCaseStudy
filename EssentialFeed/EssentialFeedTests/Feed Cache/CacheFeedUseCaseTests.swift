//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 8/10/23.
//

import Foundation
import XCTest
import EssentialFeed

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
    
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItems(), uniqueItems()]
        let localItems = items.map({ LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)})
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) {_ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(localItems, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (localFeedLoader, store) = makeSUT()
        let deletionError = anyNSError()
        expect(localFeedLoader, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (localFeedLoader, store) = makeSUT()
        let insertionError = anyNSError()
        expect(localFeedLoader, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (localFeedLoader, store) = makeSUT()
        expect(localFeedLoader, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItems()], completion: { receivedResults.append($0) })
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItems()], completion: { receivedResults.append($0) })
        
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //   MARK: Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader,
                                                 store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let localFeedLoader = LocalFeedLoader(store: store,
                                              currentDate: currentDate)
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: localFeedLoader, file: file, line: line)
        return (localFeedLoader, store)
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithError expectedError: Error?,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        
        let exp = expectation(description: "wait for save")
        let items = [uniqueItems(), uniqueItems()]
        
        var capturedError: Error?
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(capturedError as? NSError, expectedError as? NSError)
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
    
    private class FeedStoreSpy: FeedStore {
        
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        private(set) var deletions = [DeletionCompletion]()
        private(set) var insertions = [InsertionCompletion]()
        private(set) var receivedMessages = [ReceivedMessage]()
        
        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert([LocalFeedItem], Date)
        }
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletions[index](error)
        }
        
        func  completeDeletionSuccessfully(at index: Int = 0) {
            deletions[index](nil)
        }
        
        func  completeInsertionSuccessfully(at index: Int = 0) {
            insertions[index](nil)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertions[index](error)
        }
        
        func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            receivedMessages.append(.insert(items, timestamp))
            insertions.append(completion)
        }
    }
}
