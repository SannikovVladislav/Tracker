//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//

import UIKit

class TrackerViewController: UIViewController {
    
    private lazy var datePicker: UIDatePicker = {
            let picker = UIDatePicker()
            picker.datePickerMode = .date
            picker.locale = Locale(identifier: "ru_RU")
            picker.preferredDatePickerStyle = .automatic
        picker.backgroundColor = .clear
        picker.translatesAutoresizingMaskIntoConstraints = false
            
            return picker
        }()
    
    private lazy var trackerAddingButton: UIButton = {
        let button = UIButton.systemButton(
            with: UIImage(resource: .trackerAdding),
            target: self,
            action: #selector(addTrackersButton)
        )
        button.tintColor = .blackDay
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchField: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Поиск"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        return searchBar
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .trackerPlaceholder)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var placeholderStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [placeholderImageView, placeholderLabel])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        addSubviews()
        configureView()
        setupConstraints()
        setupBarButtonItem()
    }
    
    func addSubviews() {
        [trackersLabel, searchField, placeholderStack].forEach { view.addSubview($0) }
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        
    }
    
    private func setupBarButtonItem() {
        setupNavigationBarButton()
    }
    
    private func setupNavigationBarButton() {
        
        let button = UIBarButtonItem(
            image: UIImage(resource: .trackerAdding),
            style: .plain,
            target: self,
            action: #selector(addTrackersButton)
        )
        button.tintColor = .blackDay
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        
        navigationItem.leftBarButtonItem = button
        navigationItem.rightBarButtonItem = datePickerItem
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            
            // Trackers label
            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackersLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            // Search Field
            searchField.heightAnchor.constraint(equalToConstant: 36),
            searchField.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchField.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),
            
            //Placeholder Image
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            
            // Placeholder stack
            placeholderStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            placeholderStack.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 220)
        ])
    }
    
    @objc private func addTrackersButton() {
        print("Add button tapped")
    }
}

