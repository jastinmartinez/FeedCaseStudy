//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Jastin on 25/9/23.
//

import Foundation

enum FeedItemMapper {
    private struct Root: Decodable {
        var items: [RemoteFeedItem]
    }
    
    private static var ok_200: Int { return 200 }
    
    internal static func map(data: Data, response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == ok_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw  RemoteFeedLoader.Error.invalidData
        }
        return root.items
    }
}
