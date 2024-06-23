//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Jastin Martinez on 6/23/24.
//

import XCTest

final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
//    MARK: HELPERS
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
