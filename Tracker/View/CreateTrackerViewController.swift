//
//  CreateTrackerViewController.swift
//  Tracker
//
//  Created by Владислав on 13.10.2025.
//

import UIKit

protocol CreateTrackerViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
}

class CreateTrackerViewController: UIViewController {
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    
    private lazy var habitButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .blackDay
        button.setTitle(LocalizedStrings.habit, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(habitButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var irregularEventButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .blackDay
        button.setTitle(LocalizedStrings.newIrregularEvent, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(irregularEventButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @objc func habitButtonTapped() {
        let habbitVC = NewHabitViewController()
        habbitVC.delegate = self
        let habbitNC = UINavigationController(rootViewController: habbitVC)
        habbitNC.modalPresentationStyle = .pageSheet
        present(habbitNC, animated: true)
        
    }
    
    @objc func irregularEventButtonTapped() {
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
    }
    
    func addSubviews() {
        [habitButton, irregularEventButton].forEach { view.addSubview($0) }
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = LocalizedStrings.creatingNewTracker
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            habitButton.heightAnchor.constraint(equalToConstant: 60),
            habitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 281),
            habitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            irregularEventButton.heightAnchor.constraint(equalToConstant: 60),
            irregularEventButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: 16),
            irregularEventButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            irregularEventButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}

extension CreateTrackerViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        delegate?.didCreateTracker(tracker, categoryTitle: categoryTitle)
        dismiss(animated: true)
    }
}
