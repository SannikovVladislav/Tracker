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
        calendar.firstWeekday = 2
        return calendar
    }()
    private var trackerAddingButton: UIButton!
    private var currentDate = Date()
    private var visibleCategories: [TrackerCategory] = []
    private var categories: [TrackerCategory] = [] {
        didSet {
            applyFilters()
        }
    }
    
    private var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    
    private var currentFilter: FilterType = .allTrackers {
        didSet {
            applyFilters()
        }
    }
    
    private var completedTrackers: [TrackerRecord] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private lazy var trackerStore: TrackerStore = {
        let store = TrackerStore()
        store.delegate = self
        return store
    }()
    
    private lazy var trackerRecordStore: TrackerRecordStore =  {
        let store = TrackerRecordStore()
        store.delegate = self
        return store
    }()
    
    private lazy var trackerCategoryStore: TrackerCategoryStore = {
        let store = TrackerCategoryStore()
        store.delegate = self
        return store
    }()
    
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
        label.text = LocalizedStrings.trackers
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchField: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = LocalizedStrings.search
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
        label.text = LocalizedStrings.noTrackers
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
        layout.itemSize = CGSize(width: 167, height: 148)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TrackerCollectionViewCell.self,
                                forCellWithReuseIdentifier: TrackerCollectionViewCell.identifier)
        collectionView.register(TrackerSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "SectionHeader")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var filtersButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 16
        button.backgroundColor = .blueYP
        button.setTitle(LocalizedStrings.filters, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = Date()
        addSubviews()
        setupUI()
        loadInitialData()
        AnalyticsService.reportMainScreenOpen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            AnalyticsService.reportMainScreenClose()
        }
    }
    
    private func loadInitialData() {
        do {
            categories = try trackerCategoryStore.fetchAllCategories()
            completedTrackers = try trackerRecordStore.fetchAllTrackerRecords()
            applyFilters()
        } catch {
            print("Error loading data: \(error)")
        }
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
        let firstWeekday = calendar.firstWeekday
        let shifted = calendarWeekday - firstWeekday + 1
        return shifted <= 0 ? shifted + 7 : shifted
    }
    
    func toggleCompletion(for trackerID: UUID, date: Date, isCompleted: Bool) {
        let dateStart = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        guard let tracker = (visibleCategories.flatMap { $0.trackers }).first(where: { $0.id == trackerID }) else { return }
        
        if tracker.schedule.isEmpty {
            guard dateStart == today else { return }
        } else {
            let dayOfWeek = calendar.component(.weekday, from: date)
            let currentWeekday = Weekday(rawValue: adjustedWeekday(from: dayOfWeek)) ?? .monday
            guard tracker.schedule.contains(currentWeekday) && dateStart <= today else {
                return
            }
        }
        do {
            if isCompleted {
                let record = TrackerRecord(trackerId: trackerID, date: dateStart)
                try trackerRecordStore.addTrackerRecord(record)
            } else {
                try trackerRecordStore.deleteTracker(with: trackerID, date: dateStart)
            }
        } catch {
            print("Error toggling completion: \(error)")
        }
    }
    
    private func filterTrackers(for date: Date, searchText: String) -> [TrackerCategory] {
        let dayOfWeek = calendar.component(.weekday, from: date)
        let adjustedDayOfWeek = adjustedWeekday(from: dayOfWeek)
        let currentWeekday = Weekday(rawValue: adjustedDayOfWeek) ?? .monday
        let isToday = calendar.isDate(date, inSameDayAs: Date())
        
        return categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                let dayFilter: Bool
                if tracker.schedule.isEmpty {
                    // Нерегулярные события показываем только для сегодняшней даты
                    dayFilter = isToday
                } else {
                    // Регулярные события показываем по расписанию
                    dayFilter = tracker.schedule.contains(currentWeekday)
                }
                
                let searchFilter = searchText.isEmpty || tracker.name.lowercased().contains(searchText.lowercased())
                
                let completionFilter: Bool
                switch currentFilter {
                case .allTrackers:
                    completionFilter = true
                case .trackersToday:
                    completionFilter = true
                case .completed:
                    let isCompleted = completedTrackers.contains { record in
                        record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: date)
                    }
                    completionFilter = isCompleted
                case .incomplete:
                    let isCompleted = completedTrackers.contains { record in
                        record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: date)
                    }
                    completionFilter = !isCompleted
                }
                
                return dayFilter && searchFilter && completionFilter
            }
            
            return filteredTrackers.isEmpty ? nil :
            TrackerCategory(title: category.title, trackers: filteredTrackers)
        }
    }
    
    private func applyFilters() {
        if currentFilter == .trackersToday {
            datePicker.date = Date()
            currentDate = Date()
        }
        
        visibleCategories = filterTrackers(for: datePicker.date, searchText: searchText)
        showPlaceholder()
        collectionView.reloadData()
        
        updateFiltersButtonVisibility()
    }
    
    private func setupUI() {
        configureView()
        setupBarButtonItem()
        addSubviews()
        setupConstraints()
        searchField.delegate = self
        applyFilters()
    }
    
    func addSubviews() {
        [trackersLabel, searchField, placeholderStack, collectionView, filtersButton].forEach { view.addSubview($0) }
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
       
        let hasVisibleTrackers =  visibleCategories.contains { !$0.trackers.isEmpty }
        let isSearching = !searchText.isEmpty
        
        let hasTrackersForSelectedDate = categories.contains { category in
            category.trackers.contains { tracker in
                let dayOfWeek = calendar.component(.weekday, from: datePicker.date)
                let adjustedDayOfWeek = adjustedWeekday(from: dayOfWeek)
                let currentWeekday = Weekday(rawValue: adjustedDayOfWeek) ?? .monday
                let isToday = calendar.isDate(datePicker.date, inSameDayAs: Date())
                
                let dayFilter: Bool
                if tracker.schedule.isEmpty {
                    dayFilter = isToday
                } else {
                    dayFilter = tracker.schedule.contains(currentWeekday)
                }
                return dayFilter
            }
        }
        
        filtersButton.isHidden = !hasTrackersForSelectedDate
        placeholderStack.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
        
        if !hasVisibleTrackers {
            if isSearching {
                placeholderLabel.text = LocalizedStrings.noSearchResult
                placeholderImageView.image = UIImage(named: "noFoundImage")
            } else if currentFilter != .allTrackers {
                placeholderLabel.text = LocalizedStrings.noSearchResult
                placeholderImageView.image = UIImage(named: "noFoundImage")
            } else {
                placeholderLabel.text = LocalizedStrings.noTrackers
                placeholderImageView.image = UIImage(named: "trackerPlaceholderImage")
            }
        }
        placeholderImageView.isHidden = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([

            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackersLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            searchField.heightAnchor.constraint(equalToConstant: 36),
            searchField.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchField.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),

            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),

            placeholderStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            placeholderStack.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 220),

            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    
    
    private func updateFiltersButtonVisibility() {
        let hasTrackersForSelectedDate = categories.contains { category in
            category.trackers.contains { tracker in
                let dayOfWeek = calendar.component(.weekday, from: datePicker.date)
                let adjustedDayOfWeek = adjustedWeekday(from: dayOfWeek)
                let currentWeekday = Weekday(rawValue: adjustedDayOfWeek) ?? .monday
                let isToday = calendar.isDate(datePicker.date, inSameDayAs: Date())
                
                let dayFilter: Bool
                if tracker.schedule.isEmpty {
                    dayFilter = isToday
                } else {
                    dayFilter = tracker.schedule.contains(currentWeekday)
                }
                return dayFilter
            }
        }
        
        filtersButton.isHidden = !hasTrackersForSelectedDate
    }
    
    @objc private func addTrackersButton(_ sender: UIButton) {
        AnalyticsService.reportAddTrack()
        
        let createTrackerVC = CreateTrackerViewController()
        createTrackerVC.delegate = self
        
        let createTrackerNC = UINavigationController(rootViewController: createTrackerVC)
        createTrackerNC.modalPresentationStyle = .pageSheet
        present(createTrackerNC, animated: true)
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        applyFilters()
    }
    
    @objc private func filtersButtonTapped() {
        AnalyticsService.reportFilterTap()
        
        let filtersVC = FiltersViewController()
        filtersVC.delegate = self
        let filtersNC = UINavigationController(rootViewController: filtersVC)
        filtersNC.modalPresentationStyle = .pageSheet
        present(filtersNC, animated: true)
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
            if isCompleted {
                AnalyticsService.reportTrackTap()
            }
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "SectionHeader",
                for: indexPath
            ) as? TrackerSectionHeaderView else {
                return UICollectionReusableView()
            }
            let category = visibleCategories[indexPath.section]
            header.configure(with: category.title)
            return header
        }
        return UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            return self?.createContextMenu(for: indexPath)
        }
    }
    
    private func createContextMenu(for indexPath: IndexPath) -> UIMenu {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        let editAction = UIAction(
            title: LocalizedStrings.edit) { [weak self] _ in
                AnalyticsService.reportEditContext()
                self?.editTracker(tracker, at: indexPath)}
        let deleteAction = UIAction(
            title: LocalizedStrings.delete, attributes: .destructive) { [weak self] _ in
                AnalyticsService.reportDeleteContext()
                self?.confirmDeleteTracker(tracker, at: indexPath)}
        return UIMenu(children: [editAction, deleteAction])
        
    }
    
    private func editTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        let categoryTitle = visibleCategories[indexPath.section].title
        
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        let editVC = EditTrackerViewController(
            tracker: tracker,
            categoryTitle: categoryTitle,
            completedDays: completedDays
        )
        
        editVC.delegate = self
        let editNC = UINavigationController(rootViewController: editVC)
        present(editNC, animated: true)
    }
    
    private func confirmDeleteTracker(_ tracker: Tracker, at indexPath: IndexPath) {
    
        let alert = UIAlertController(
            title: nil,
            message: LocalizedStrings.confirmDelete,
            preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(
            title: LocalizedStrings.delete,
            style: .destructive
        ){ [weak self] _ in
            guard let self = self else { return }
            self.deleteTracker(tracker, at: indexPath)
        }
        
        let cancelAction = UIAlertAction(
            title: LocalizedStrings.cancel,
            style: .cancel
        )
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
        
    }
    
    private func deleteTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        do {
            try trackerStore.deleteTracker(with: tracker.id)
        } catch {
            print("Error delete tracker: \(error)")
        }
    }
}

extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            if let _ = try trackerCategoryStore.fetchCategory(with: categoryTitle) {
                try trackerStore.addTracker(tracker, categoryTitle: categoryTitle)
            } else {
                let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
                try trackerCategoryStore.addCategory(newCategory)
            }
            loadInitialData()
            dismiss(animated: true)
        } catch {
            print("Error creating tracker: \(error)")
        }
    }
}

extension TrackersViewController: TrackerStoreDelegate {
    func store(_ store: TrackerStore, didUpdate update: TrackerStoreUpdate) {
        loadInitialData()
    }
}

extension TrackersViewController: TrackerRecordStoreDelegate {
    func store(_ store: TrackerRecordStore, didUpdate update: TrackerRecordStoreUpdate) {
        do {
            completedTrackers = try trackerRecordStore.fetchAllTrackerRecords()
            collectionView.reloadData()
            print("Записей после обновления: \(completedTrackers.count)")
        } catch {
            print("Error loading records: \(error)")
        }
    }
}

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func store(_ store: TrackerCategoryStore, didUpdate update: TrackerCategoryStoreUpdate) {
        loadInitialData()
    }
}

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            searchText = ""
            searchBar.resignFirstResponder()
            applyFilters()
        }
}

extension TrackersViewController: EditTrackerViewControllerDelegate {
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            try trackerStore.updateTracker(tracker, categoryTitle: categoryTitle)
        } catch {
            print("Error updating tracker: \(error)")
        }
    }
}

extension TrackersViewController: FiltersSelectionDelegate {
    func didSelectFilter(_ filter: FilterType) {
        currentFilter = filter
    }
}
