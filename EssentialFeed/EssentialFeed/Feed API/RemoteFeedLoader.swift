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
    
    public typealias Result = LoadFeedResult
    
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
                completion(FeedItemMapper.map(data: data, response: response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
