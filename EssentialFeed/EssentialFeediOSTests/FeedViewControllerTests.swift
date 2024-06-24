//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Jastin Martinez on 6/23/24.
//

import XCTest
import UIKit
import EssentialFeed


final class FeedViewController: UITableViewController {
    
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        refreshControl?.beginRefreshing()
    }
    
    @objc private func load() {
        loader?.load { _ in }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullRefresh_loadFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.refreshControl?.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
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
    
    class LoaderSpy: FeedLoader {
        
        private(set) var loadCallCount = 0
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            loadCallCount += 1
        }
    }
}

private extension UIRefreshControl {
    func simulatePullDownRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ action in
                (target as NSObject).perform(Selector(action))
            })
        })
    }
}

private extension FeedViewController {
    func replaceWithFakeRefreshControl() {
        let fakeRefreshControl = FakeRefreshControl()
        refreshControl?.allTargets.forEach({ target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ action in
                fakeRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
            })
        })
        refreshControl = fakeRefreshControl
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
