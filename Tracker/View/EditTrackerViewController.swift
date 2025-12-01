//
//  EditTrackerViewController.swift
//  Tracker
//
//  Created by Владислав on 26.11.2025.
//
import UIKit

protocol EditTrackerViewControllerDelegate: AnyObject {
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String)
}

final class EditTrackerViewController: UIViewController {
    
    weak var delegate: EditTrackerViewControllerDelegate?
    private var tracker: Tracker
    private var categoryTitle: String
    private var completedDays: Int
    
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var daysCounterLabel: UILabel = {
        let label = UILabel()
        let dayCountFormat = String.localizedStringWithFormat(NSLocalizedString("dayCounter", comment: "Number of days complected"), completedDays)
        label.text = "\(dayCountFormat)"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .blackDay
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTrackerTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = LocalizedStrings.trackerPlaceholderName
        textField.text = tracker.name
        textField.textColor = .blackDay
        textField.tintColor = .grayYP
        textField.backgroundColor = .lightGrayE6
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.layer.cornerRadius = 16
        textField.leftView = UIView(frame: CGRect (x:16, y: 0, width: 17, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.delegate = self
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    private lazy var categoryAndScheduleTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.clipsToBounds = true
        //tableView.isScrollEnabled = false
        let layer = tableView.layer
        layer.cornerRadius = 16
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.redYP.cgColor
        button.backgroundColor = .clear
        button.setTitle(LocalizedStrings.cancel, for: .normal)
        button.setTitleColor(.redYP, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .grayYP
        button.setTitle(LocalizedStrings.save, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private lazy var emojiCollectionView: EmojiCollectionView = {
        let collectionView = EmojiCollectionView()
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    private lazy var colorCollectionView: ColorCollectionView = {
        let collectionView = ColorCollectionView()
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    
    private lazy var emojiTitleLabel: UILabel = {
        let label = UILabel()
        label.text = LocalizedStrings.emoji
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = LocalizedStrings.color
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    init(tracker: Tracker, categoryTitle: String, completedDays: Int) {
        self.tracker = tracker
        self.categoryTitle = categoryTitle
        self.completedDays = completedDays
        super.init(nibName: nil, bundle: nil)
        
        self.selectedCategory = categoryTitle
        self.selectedSchedule = tracker.schedule
        self.selectedEmoji = tracker.emoji
        self.selectedColor = tracker.color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTapGesture()
        
        if let emoji = selectedEmoji {
            emojiCollectionView.selectEmoji(emoji)
        }
        if let color = selectedColor {
            colorCollectionView.selectColor(color)
        }
        updateCreateButtonState()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Позволяет одновременно обрабатывать другие тапы
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = LocalizedStrings.editScreenTitle
        
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
        
    }
    
    func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [daysCounterLabel, nameTrackerTextField, categoryAndScheduleTableView, emojiTitleLabel, emojiCollectionView, colorTitleLabel, colorCollectionView, cancelButton, saveButton].forEach { contentView.addSubview($0) }
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            //Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Days Counter Label
            daysCounterLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            daysCounterLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Name Tracker Text Field
            nameTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTrackerTextField.topAnchor.constraint(equalTo: daysCounterLabel.bottomAnchor, constant: 40),
            nameTrackerTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTrackerTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            //Category and Schedule TableView
            categoryAndScheduleTableView.heightAnchor.constraint(equalToConstant: 150),
            categoryAndScheduleTableView.topAnchor.constraint(equalTo: nameTrackerTextField.bottomAnchor, constant: 24),
            categoryAndScheduleTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryAndScheduleTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            //Emoji Title Label
            emojiTitleLabel.topAnchor.constraint(equalTo: categoryAndScheduleTableView.bottomAnchor, constant: 32),
            emojiTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            // Emoji Collection View
            emojiCollectionView.topAnchor.constraint(equalTo: emojiTitleLabel.bottomAnchor, constant: 24),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            //Color Title Label
            colorTitleLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 16),
            colorTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            // Color Collection View
            colorCollectionView.topAnchor.constraint(equalTo: colorTitleLabel.bottomAnchor, constant: 24),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 204),
            colorCollectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -24),
            
            // Cancel Button
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalToConstant: 166),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            //Create Button
            saveButton.heightAnchor.constraint(equalToConstant: 60),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            saveButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func categoryButtonTapped() {
        let categoryVC = CategoryViewController()
        categoryVC.delegate = self
        categoryVC.selectedCategory = selectedCategory
        let categoryNC = UINavigationController(rootViewController: categoryVC)
        categoryNC.modalPresentationStyle = .pageSheet
        present(categoryNC, animated: true)
    }
    
    private func scheduleButtonTapped() {
        let scheduleVC = ScheduleViewController()
        scheduleVC.delegate = self
        scheduleVC.selectedDays = selectedSchedule
        let scheduleNC = UINavigationController(rootViewController: scheduleVC)
        scheduleNC.modalPresentationStyle = .pageSheet
        present(scheduleNC, animated: true)
    }
    
    private func updateCreateButtonState() {
        let isNameTextField = !(nameTrackerTextField.text?.isEmpty ?? true)
        let isSelectedCategory = selectedCategory != nil
        let isSelectedSchedule = !selectedSchedule.isEmpty
        let isSelectedEmoji = selectedEmoji != nil
        let isSelectedColor = selectedColor != nil
        
        let isResultEmpty = isNameTextField && isSelectedCategory && isSelectedSchedule && isSelectedEmoji && isSelectedColor
        saveButton.isEnabled = isResultEmpty
        saveButton.backgroundColor = isResultEmpty ? .blackDay : .grayYP
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func saveButtonTapped () {
        guard let name = nameTrackerTextField.text, !name.isEmpty,
              let category = selectedCategory, !selectedSchedule.isEmpty,
              let emoji = selectedEmoji,
              let color = selectedColor else { return }
        
        let newTracker = Tracker(id: tracker.id,
                                 name: name,
                                 color: color,
                                 emoji: emoji,
                                 schedule: selectedSchedule)
        delegate?.didUpdateTracker(newTracker, categoryTitle: category)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped () {
        dismiss(animated: true)
    }
    
    @objc private func textFieldChanged() {
        updateCreateButtonState()
    }
}

extension EditTrackerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.backgroundColor = .lightGrayE6
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .blackDay
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.row == 0 {
            cell.textLabel?.text = LocalizedStrings.category
            configureCategoryCell(cell)
        } else {
            cell.textLabel?.text = LocalizedStrings.schedule
            configureScheduleCell(cell)
        }
        return cell
    }
}

extension EditTrackerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            categoryButtonTapped()
        } else {
            scheduleButtonTapped()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
}

extension EditTrackerViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension EditTrackerViewController: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: [Weekday]) {
        selectedSchedule = schedule
        categoryAndScheduleTableView.reloadData()
        
        if let cell = categoryAndScheduleTableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
            configureScheduleCell(cell)
        }
        updateCreateButtonState()
    }
    
    private func configureScheduleCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = LocalizedStrings.schedule
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .grayYP
        
        if selectedSchedule.isEmpty {
            cell.detailTextLabel?.text = nil
        } else if selectedSchedule.count == Weekday.allCases.count {
            cell.detailTextLabel?.text = LocalizedStrings.everyDay
        } else {
            let shortNames = selectedSchedule.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }
            cell.detailTextLabel?.text = shortNames.joined(separator: ", ")
        }
    }
}

extension EditTrackerViewController: CategorySelectionDelegate {
    func didSelectCategory(_ category: String) {
        selectedCategory = category
        categoryAndScheduleTableView.reloadData()
        
        if let cell = categoryAndScheduleTableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            configureCategoryCell(cell)
        }
        updateCreateButtonState()
    }
    
    func configureCategoryCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = LocalizedStrings.category
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .grayYP
        
        if let selectedCategory = selectedCategory, !selectedCategory.isEmpty {
            cell.detailTextLabel?.text = selectedCategory
        } else {
            cell.detailTextLabel?.text = nil
            
        }
    }
}

extension EditTrackerViewController: EmojiSelectionDelegate {
    func didSelectEmoji(_ emoji: String) {
        selectedEmoji = emoji
        updateCreateButtonState()
    }
}

extension EditTrackerViewController: ColorSelectionDelegate {
    func didSelectColor(_ color: UIColor) {
        selectedColor = color
        updateCreateButtonState()
    }
}

