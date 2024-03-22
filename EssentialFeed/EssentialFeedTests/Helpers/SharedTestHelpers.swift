//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Jastin on 14/10/23.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
}

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}
