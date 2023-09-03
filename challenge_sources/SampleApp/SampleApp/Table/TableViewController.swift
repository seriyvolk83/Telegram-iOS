//
//  TableViewControlle.swift
//  SampleApp
//
//  Created by Volkov Alexander on 03.09.2023.
//

import Foundation
import UIKit
import SwiftUI

struct CellInfo {
    let title: String
    let subtitle: String
    let icon: UIImage
}

final class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let items: [CellInfo] = previewCells
    
    private var customPullToRefreshView: PullToArchiveView!
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(#function): \(view.frame)")
        
        // Init table
        let view = UITableView()
        view.frame = self.view.bounds
        view.backgroundColor = .white
        self.view.addSubview(view)
        self.tableView = view
        
        view.dataSource = self
        view.delegate = self
        
        initPullToRefresh(tableView: view)
    }
    
    private func initPullToRefresh(tableView: UITableView) {
        let customPullToRefreshView = PullToArchiveView()
        
        var frame = tableView.frame
        frame.size.height = 0
        frame.origin.y = -frame.size.height
        customPullToRefreshView.frame = frame
        customPullToRefreshView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(customPullToRefreshView)
        customPullToRefreshView.doneReleasingCallback = { [weak self] in
            self?.addArchiveCell()
        }
        
        self.customPullToRefreshView = customPullToRefreshView
        hidePullView()
    }
    
    private func hidePullView() {
        guard let view = customPullToRefreshView else { return }
        view.frame.origin.y = -view.frame.size.height
        view.frame.size.width = self.view.frame.width
    }
    
    // MARK: - Scrolling
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let view = customPullToRefreshView else { return }
        let shift: CGFloat = scrollView.bounds.origin.y
        guard shift <= 0 else { hidePullView(); return }
        let offset = -shift
        view.frame.size.width = self.view.frame.width
        view.frame.origin.y = 0
        if self.tableView?.tableHeaderView != nil {
            view.frame.size.height = offset + PullViewSettings.releasedHeight
        }
        else {
            view.frame.size.height = offset
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("\(#function): \(scrollView.bounds)")
        let isReleased = customPullToRefreshView?.tryRelease() ?? false
        if isReleased {
            if let tableView = tableView {
                tableView.contentInset = UIEdgeInsets(top: PullViewSettings.releasedHeight, left: 0, bottom: 0, right: 0)
            }
        }
        print("isReleased: \(isReleased)")
    }
    
    private func addArchiveCell() {
        guard let tableView = self.tableView else { return }
        let placeholder = ArchiveCellView()
        placeholder.frame = tableView.frame
        placeholder.frame.size.height = PullViewSettings.releasedHeight
        tableView.tableHeaderView = placeholder
        tableView.contentInset = .zero
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("\(#function): \(scrollView.bounds)")
    }
    
    // MARK: - Table
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("\(#function): \(view.frame)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("\(#function): \(view.frame)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.imageView?.image = item.icon
        return cell
    }
}

struct CustomTable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> TableViewController {
        TableViewController()
    }
    
    func updateUIViewController(_ uiViewController: TableViewController, context: Context) {
    }
}


private let previewCells: [CellInfo] = [
    CellInfo(title: "John", subtitle: "Everything is ok", icon: UIImage(systemName: "photo")!),
    CellInfo(title: "Sara", subtitle: "Looking for something", icon: UIImage(systemName: "photo")!)
]
