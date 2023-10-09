//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Jastin on 9/10/23.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
