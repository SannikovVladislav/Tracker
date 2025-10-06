//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//

import UIKit

class TrackerViewController: UIViewController {
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupUI()
    }
    
    func setupUI() {
        
        configureView()
        setupConstraints()
        addSubviews()
    }
    
    func addSubviews() {
        [trackersLabel].forEach { view.addSubview($0) }
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // Trackers label
            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackersLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
    ])
    }
    
    
}
