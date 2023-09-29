//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Jastin on 25/9/23.
//

import Foundation

internal final class FeedItemMapper {
    private struct Root: Decodable {
        var items: [Item]
        var feedItems: [FeedItem] {
            return items.map({ $0.feedItem })
        }
    }
    
    private struct Item: Decodable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let image: URL
        
        var feedItem: FeedItem {
            return FeedItem(id: id,
                            description: description,
                            location: location,
                            imageURL: image)
        }
    }
    
    private static var ok_200: Int { return 200 }
    
    internal static func map(data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == ok_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feedItems)
    }
}
