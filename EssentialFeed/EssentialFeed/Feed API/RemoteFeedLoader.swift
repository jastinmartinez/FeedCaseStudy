//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Jastin on 20/9/23.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result =  FeedLoader.Result
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        self.client.get(from:  url) { [weak self] result  in
            guard self != nil else {
                return
            }
            switch result {
            case let .success(data, response):
                completion(RemoteFeedLoader.map(data, from: response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let feed = try FeedItemMapper.map(data: data, response: response)
            return .success(feed.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map({ FeedImage(id: $0.id,
                              description: $0.description,
                              location: $0.location,
                              url: $0.image)})
    }
}
