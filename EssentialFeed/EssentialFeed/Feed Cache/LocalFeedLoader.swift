//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Jastin on 9/10/23.
//

import Foundation

public final class LocalFeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
 
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionResult in
            guard let self = self else {
                return
            }
            switch deletionResult {
            case .success:
                self.cache(feed, with: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] InsertionResult in
            guard self != nil else {
                return
            }
            completion(InsertionResult)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case let .success(.some((feed: feed, timestamp: timestamp))) where FeedCachePolicy.validate(timestamp,
                                                                                              against: currentDate()) :
                completion(.success(feed.toModel()))
                
            case let .failure(  failure):
                completion(.failure(failure))
                
            case .success:
                completion(.success([]))
            }
        }
    }
}


extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve(completion: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(.some((_, timestamp))) where !FeedCachePolicy.validate(timestamp,
                                                                           against: currentDate()):
                self.store.deleteCachedFeed(completion: {_ in })
            case .failure:
                self.store.deleteCachedFeed(completion: {_ in})
            case .success: break
            }
        })
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map({ LocalFeedImage(id: $0.id,
                                    description: $0.description,
                                    location: $0.location,
                                    url: $0.url) })
    }
}

private extension Array where Element == LocalFeedImage {
    func toModel() -> [FeedImage] {
        return map({ FeedImage(id: $0.id,
                               description: $0.description,
                               location: $0.location,
                               url: $0.url) })
    }
}
