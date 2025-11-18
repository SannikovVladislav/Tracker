//
//  TrackerSectionHeaderView.swift
//  Tracker
//
//  Created by Владислав on 16.11.2025.
//
import UIKit

final class TrackerSectionHeaderView: UICollectionReusableView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

