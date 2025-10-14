//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//

import UIKit

protocol TrackerCreationDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
}

class TrackersViewController: UIViewController {
    
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Понедельник — первый день недели
        return calendar
    }()
    private var currentDate = Date()
    private var visibleCategories: [TrackerCategory] = []
    private var categories: [TrackerCategory] = [] {
        didSet {
            showPlaceholder()
            collectionView.reloadData()
        }
    }
    
    private var completedTrackers: [TrackerRecord] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var trackerAddingButton: UIButton!
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        return picker
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
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 167, height: 90)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: TrackerCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = Date()
        addSubviews()
        setupUI()
    }
    
    func addTrackerCategory(_ tracker: Tracker, to categoryTitle: String) {
        var updatedCategories = categories
        
        if let index = updatedCategories.firstIndex(where: {$0.title == categoryTitle }) {
            let updatedTrackers = updatedCategories[index].trackers + [tracker]
            updatedCategories[index] = TrackerCategory(title: categoryTitle, trackers: updatedTrackers)
        } else {
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            updatedCategories.append(newCategory)
        }
        categories = updatedCategories
    }
    
    private func adjustedWeekday(from calendarWeekday: Int) -> Int {
        let firstWeekday = calendar.firstWeekday // 2 — понедельник
        let shifted = calendarWeekday - firstWeekday + 1
        return shifted <= 0 ? shifted + 7 : shifted
    }
    
    
    
    func toggleCompletion(for trackerID: UUID, date: Date, isCompleted: Bool) {
        let dateStart = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        guard let tracker = (visibleCategories.flatMap { $0.trackers }).first(where: { $0.id == trackerID }) else { return }
        
        // Для нерегулярных событий разрешаем отметку только на сегодня
        if tracker.schedule.isEmpty {
            guard dateStart == today else { return }
        } else {
            // Для регулярных событий проверяем день недели и что дата не в будущем
            let dayOfWeek = calendar.component(.weekday, from: date)
            let currentWeekday = Weekday(rawValue: adjustedWeekday(from: dayOfWeek)) ?? .monday
            guard tracker.schedule.contains(currentWeekday) && dateStart <= today else {
                return
            }
        }
        
        if isCompleted {
            let record = TrackerRecord(trackerId: trackerID, date: dateStart)
            if !completedTrackers.contains(where: {
                $0.trackerId == trackerID && calendar.isDate($0.date, inSameDayAs: dateStart)
            }) {
                completedTrackers.append(record)
            }
        } else {
            completedTrackers.removeAll {
                $0.trackerId == trackerID && calendar.isDate($0.date, inSameDayAs: dateStart)
            }
        }
        
        collectionView.reloadData()
    }
    
    private func filterTrackers(for date: Date) -> [TrackerCategory] {
        let dayOfWeek = calendar.component(.weekday, from: date)
        let adjustedDayOfWeek = adjustedWeekday(from: dayOfWeek)
        let currentWeekday = Weekday(rawValue: adjustedDayOfWeek) ?? .monday
        let isToday = calendar.isDate(date, inSameDayAs: Date())
        
        return categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                if tracker.schedule.isEmpty {
                    // Нерегулярные события показываем только для сегодняшней даты
                    return isToday
                } else {
                    // Регулярные события показываем по расписанию
                    return tracker.schedule.contains(currentWeekday)
                }
            }
            return filteredTrackers.isEmpty ? nil :
            TrackerCategory(title: category.title, trackers: filteredTrackers)
        }
    }

    private func setupUI() {
        configureView()
        setupBarButtonItem()
        addSubviews()
        //setupDate()
        
        setupConstraints()
        
        visibleCategories = filterTrackers(for: datePicker.date)
        showPlaceholder()
        collectionView.reloadData()
        
    }
    
    func addSubviews() {
        [trackersLabel, searchField, placeholderStack, collectionView].forEach { view.addSubview($0) }
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        
    }
    
    private func setupBarButtonItem() {
        guard let trackerAddingImage = UIImage(named: "trackerAddingImage") else {
            assertionFailure("Failed to load tracker adding image")
            return
        }
        trackerAddingButton = UIButton.systemButton(
            with: trackerAddingImage,
            target: self,
            action: #selector(Self.addTrackersButton))
        trackerAddingButton.tintColor = .blackDay
        
        trackerAddingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trackerAddingButton)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: trackerAddingButton)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }
    
    private func showPlaceholder() {
        let isEmpty = visibleCategories.flatMap{$0.trackers}.isEmpty
        placeholderStack.isHidden = !isEmpty
    }
    
   private func setupConstraints() {
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
            placeholderStack.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 220),
            
            //Collection view
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func addTrackersButton(_ sender: UIButton) {
        let createTrackerVC = CreateTrackerViewController()
        createTrackerVC.delegate = self
        
        let createTrackerNC = UINavigationController(rootViewController: createTrackerVC)
        createTrackerNC.modalPresentationStyle = .pageSheet
        present(createTrackerNC, animated: true)
        
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        visibleCategories = filterTrackers(for: currentDate)
        collectionView.reloadData()
        showPlaceholder()
        // dateTextField.text = formatDate(sender.date)
    }
}

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard visibleCategories.indices.contains(section) else { return 0 }
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCollectionViewCell.identifier, for: indexPath) as? TrackerCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let selectedDate = datePicker.date
        
        let isCompletedToday = completedTrackers.contains { record in
            record.trackerId == tracker.id &&
            Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }
        
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure( with: tracker, completedDays: completedDays, isCompletedToday: isCompletedToday, currentDate: selectedDate)
        
        cell.onCompletion = { [weak self] trackerId, date, isCompleted in
            self?.toggleCompletion(for: trackerId, date: date, isCompleted: isCompleted)
        }
        
        return cell
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let availableWidth = collectionView.bounds.width - (padding * 3)
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
}

extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        addTrackerCategory(tracker, to: categoryTitle)
        visibleCategories = filterTrackers(for: datePicker.date)
        collectionView.reloadData()
        showPlaceholder()
        dismiss(animated: true)
    }
}
