//
//  ArchiveCellView.swift
//  SampleApp
//
//  Created by Volkov Alexander on 03.09.2023.
//

import Foundation
import UIKit

/// The view that mimics archive cell
final class ArchiveCellView: UIView {
    
    struct Info {
        let title: String
        let subtitle: String
        let more: String
        let count: Int
    }
    
    public var info: Info = Info(
        title: "Archived Chats",
        subtitle: "Morton Robbins, Jordan Conner, Richard Mitchel, ",
        more: "Dane Blake",
        count: 34
    ) { didSet { updateUI() } }
    private let leftShift: CGFloat = 80
    private let rightPadding: CGFloat = 50
    
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var countLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if titleLabel == nil {
            titleLabel = UILabel()
            titleLabel.text = info.title
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            addSubview(titleLabel)
        }
        
        if subtitleLabel == nil {
            subtitleLabel = UILabel()
            subtitleLabel.numberOfLines = 2
            subtitleLabel.text = info.subtitle + info.more
            // TODO need to apply attributed string. For animation demo it's ok to have single color for the subtitle
            subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
            addSubview(subtitleLabel)
        }
        
        if countLabel == nil {
            countLabel = UILabel()
            countLabel.text = info.count.description
            countLabel.textColor = .white
            countLabel.backgroundColor = .lightGray.withAlphaComponent(0.8)
            countLabel.layer.masksToBounds = true
            countLabel.textAlignment = .center
            countLabel.font = .systemFont(ofSize: 12, weight: .regular)
            addSubview(countLabel)
        }
        let padding: CGFloat = 3
        let width = self.bounds.width - leftShift - rightPadding
        var frame = CGRect(origin: CGPoint(x: leftShift, y: 8), size: CGSize(width: width, height: 32))
        let titleLabelBounds = titleLabel.sizeThatFits(frame.size)
        frame.size.height = titleLabelBounds.height
        titleLabel.frame = frame
        do {
            let bounds = subtitleLabel.sizeThatFits(frame.size)
            subtitleLabel.frame = frame
            subtitleLabel.frame.origin.y = frame.origin.y + frame.height + padding
            subtitleLabel.frame.size.height = bounds.height
        }
        countLabel.frame = CGRect(origin: CGPoint(x: self.bounds.width - 36, y: self.bounds.height - 36), size: CGSize(width: 28, height: 20))
        countLabel.layer.cornerRadius = countLabel.frame.height / 2
    }
    
    private func updateUI() {
        titleLabel?.text = info.title
        subtitleLabel?.text = info.subtitle
        countLabel?.text = info.count.description
    }
}
