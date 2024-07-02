//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Jastin Martinez on 7/1/24.
//

import Foundation
import UIKit
import EssentialFeed

public final class FeedViewController: UITableViewController {
    
    private var tableModel = [FeedImage]()
    private var loader: FeedLoader?
    @objc public private(set) var onLoad: (() -> Void)?
    
    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        onCreate()
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onLoad?()
    }
    
    private func onCreate() {
        setRefreshControl()
        setOnLoad()
        onLoad?()
    }
    
    private func setRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getter: onLoad), for: .valueChanged)
    }
    
    private func setOnLoad() {
        onLoad = { [weak self] in
            self?.refreshControl?.beginRefreshing()
            self?.loader?.load { [weak self] result in
                self?.tableModel = (try? result.get()) ?? []
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
            }
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (cellModel.location == nil)
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        return cell
    }
}
