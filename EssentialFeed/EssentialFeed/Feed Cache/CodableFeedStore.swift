//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Jastin on 11/3/24.
//

import Foundation

public final class CodableFeedStore: FeedStore {
    
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
    
    private let queue = DispatchQueue(label: "\(String(describing: CodableFeedStore.self)).com",
                                      qos: .userInitiated,
                                      attributes: .concurrent)
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        queue.async { [storeURL] in
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.success(.none))
            }
            do {
                let cache = try JSONDecoder().decode(Cache.self, from: data)
                completion(.success((feed: cache.localFeed, timestamp: cache.timestamp)))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
                let encode = try JSONEncoder().encode(cache)
                try encode.write(to: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                }
                completion(.success(()))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
}
