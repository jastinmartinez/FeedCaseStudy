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
    
    @objc private var onLoad: (() -> Void)?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getter: onLoad), for: .valueChanged)
        onLoad = { [weak self] in
            self?.refreshControl?.beginRefreshing()
            self?.loader?.load { [weak self] _ in
                self?.refreshControl?.endRefreshing()
            }
        }
        onLoad?()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onLoad?()
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
        sut.replaceWithFakeRefreshControl()
        sut.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulatePullDownRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.simulateAppereance()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    
    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.simulateAppereance()
        
        loader.completeFeedLoader()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    func test_pullRefresh_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.simulatePullDownRefresh()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    
    func test_pullRefresh_hidesLoadingIndicatorOnLoadCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        sut.replaceWithFakeRefreshControl()
        sut.simulatePullDownRefresh()
        loader.completeFeedLoader()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
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
        
        private var messages = [(FeedLoader.Result) -> Void]()
        
        var loadCallCount: Int {
            return messages.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            messages.append(completion)
        }
        
        func completeFeedLoader() {
            messages[0](.success([]))
        }
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
    
    func simulateAppereance() {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func simulatePullDownRefresh() {
        onLoad?()
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
