//
//  NewHabitViewController.swift
//  Tracker
//
//  Created by Владислав on 13.10.2025.
//
import UIKit

class NewHabitViewController: UIViewController {
    
    weak var delegate: CreateTrackerViewControllerDelegate?
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
    
    private lazy var nameTrackerTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.textColor = .blackDay
        textField.tintColor = .grayYP
        textField.backgroundColor = .lightGrayYP
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
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.redYP, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .grayYP
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
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
    
    private lazy var emojiTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorCollectionView: ColorCollectionView = {
        let collectionView = ColorCollectionView()
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedCategory = "Здоровье❤️"
        setupUI()
        setupTapGesture()
        updateCreateButtonState()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = "Новая привычка"
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
        
    }
    
    func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [nameTrackerTextField, categoryAndScheduleTableView, emojiTitleLabel, emojiCollectionView, colorTitleLabel, colorCollectionView, cancelButton, createButton].forEach { contentView.addSubview($0) }
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
            
            // Name Tracker Text Field
            nameTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTrackerTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
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
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            createButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)        ])
    }
    
    private func categoryButtonTapped() {
        let categoryVC = CategoryViewController()
        categoryVC.delegate = self
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
        createButton.isEnabled = isResultEmpty
        createButton.backgroundColor = isResultEmpty ? .blackDay : .grayYP
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func createButtonTapped () {
        guard let name = nameTrackerTextField.text, !name.isEmpty,
              let category = selectedCategory, !selectedSchedule.isEmpty,
        let emoji = selectedEmoji,
            let color = selectedColor else { return }
        
        let newTracker = Tracker(id: UUID(),
                                 name: name,
                                 color: color,
                                 emoji: emoji,
                                 schedule: selectedSchedule)
        delegate?.didCreateTracker(newTracker, categoryTitle: category)
        presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped () {
        dismiss(animated: true)
    }
    
    @objc private func textFieldChanged() {
        updateCreateButtonState()
    }
}

extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.backgroundColor = .lightGrayYP
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .blackDay
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Категория"
        } else {
            cell.textLabel?.text = "Расписание"
            
            configureScheduleCell(cell)
        }
        return cell
    }
}

extension NewHabitViewController: UITableViewDelegate {
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

extension NewHabitViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension NewHabitViewController: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: [Weekday]) {
        selectedSchedule = schedule
        categoryAndScheduleTableView.reloadData()
        
        if let cell = categoryAndScheduleTableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
            configureScheduleCell(cell)
        }
        updateCreateButtonState()
    }
    
    private func configureScheduleCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = "Расписание"
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .grayYP
        
        if selectedSchedule.isEmpty {
            cell.detailTextLabel?.text = nil
        } else if selectedSchedule.count == Weekday.allCases.count {
            cell.detailTextLabel?.text = "Каждый день"
        } else {
            let shortNames = selectedSchedule.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }
            cell.detailTextLabel?.text = shortNames.joined(separator: ", ")
        }
    }
}

extension NewHabitViewController: CategorySelectionDelegate {
    func didSelectCategory(_ category: String) {
        selectedCategory = category
        categoryAndScheduleTableView.reloadData()
        updateCreateButtonState()
    }
}

extension NewHabitViewController: EmojiSelectionDelegate {
    func didSelectEmoji(_ emoji: String) {
        selectedEmoji = emoji
        updateCreateButtonState()
    }
}

extension NewHabitViewController: ColorSelectionDelegate {
    func didSelectColor(_ color: UIColor) {
        selectedColor = color
        updateCreateButtonState()
    }
}


//#Preview {NewHabitViewController()}
