//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Jastin on 9/10/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessagesStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
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
    
    private class FeedStoreSpy: FeedStore {
        
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        private(set) var deletions = [DeletionCompletion]()
        private(set) var insertions = [InsertionCompletion]()
        private(set) var receivedMessages = [ReceivedMessage]()
        
        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert([LocalFeedImage], Date)
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
        
        func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            receivedMessages.append(.insert(items, timestamp))
            insertions.append(completion)
        }
    }
}
