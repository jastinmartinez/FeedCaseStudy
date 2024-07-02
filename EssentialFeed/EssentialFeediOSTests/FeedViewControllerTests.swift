//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Jastin Martinez on 6/23/24.
//

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        XCTAssertEqual(loader.loadCallCount, 1)
        
        sut.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.simulateAppereance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true)
        
        loader.completeFeedLoader(at: 0)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)
        
        sut.simulatePullDownRefresh()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true)
        
        loader.completeFeedLoader(at: 1)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)
    }
    
    func test_loadFeedCompletion_redendersSuccesfullyLoadedFeed() throws {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "a location")
        let image2 = makeImage(description: "a description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.numberOfRenderedFeedImageView(), 0)
        
        loader.completeFeedLoader(with: [image0])
        XCTAssertEqual(sut.numberOfRenderedFeedImageView(), 1)
        
        sut.simulatePullDownRefresh()
        
        let feedImages: [FeedImage] = [image0, image1, image2, image3]
        loader.completeFeedLoader(with: feedImages)
        XCTAssertEqual(sut.numberOfRenderedFeedImageView(), 4)
        continueAfterFailure = false
        try feedImages.enumerated().forEach { (index, feed) in
            try assert(sut, hasViewConfigureFor: feed, at: index)
        }
    }
    
    
    // MARK: HELPERS
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: loader, file: file, line: line)
        return (sut, loader)
    }
    
    private func assert(_ sut: FeedViewController,
                        hasViewConfigureFor image: FeedImage,
                        at index: Int,
                        file: StaticString = #filePath,
                        line: UInt = #line) throws {
        let view = try XCTUnwrap( sut.feedViewImage(at: index) as? FeedImageCell)
        XCTAssertEqual(view.isShowingLocation, image.location != nil, file: file, line: line)
        XCTAssertEqual(view.locationText, image.location, file: file, line: line)
        XCTAssertEqual(view.descriptionText, image.description, file: file, line: line)
    }
    
    private func makeImage(description: String? = nil
                           , location: String? = nil
                           ,ulr: URL = URL(string: "http://any-url.com")!) -> FeedImage {
        return FeedImage(id: UUID(),
                         description: description,
                         location: location,
                         url: ulr)
    }
    
    class LoaderSpy: FeedLoader {
        
        private var messages = [(FeedLoader.Result) -> Void]()
        
        var loadCallCount: Int {
            return messages.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            messages.append(completion)
        }
        
        func completeFeedLoader(with feed: [FeedImage] = [],at index: Int = 0) {
            messages[index](.success(feed))
        }
    }
}

private extension FeedViewController {
    
    var isShowingLoadingIndicator: Bool? {
        return self.refreshControl?.isRefreshing
    }
    
    func replaceWithFakeRefreshControl() {
        let fakeRefreshControl = FakeRefreshControl()
        refreshControl?.allTargets.forEach({ target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ action in
                fakeRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
            })
        })
        refreshControl = fakeRefreshControl
    }
    
    func simulateAppereance() {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func numberOfRenderedFeedImageView() -> Int {
        return tableView.numberOfRows(inSection: feedImageSection)
    }
    
    private var feedImageSection: Int {
        return 0
    }
    
    func feedViewImage(at row: Int = 0) -> UITableViewCell? {
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: row, section: feedImageSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    func simulatePullDownRefresh() {
        onLoad?()
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
}

private class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { return _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}
