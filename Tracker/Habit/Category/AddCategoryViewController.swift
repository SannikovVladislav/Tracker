//
//  AddCategoryViewController.swift
//  Tracker
//
//  Created by Владислав on 16.11.2025.
//
import UIKit

protocol CreateCategoryControllerDelegate: AnyObject {
    func didCreateCategory(_ categoryTitle: String)
}

protocol EditCategoryControllerDelegate: AnyObject {
    func didUpdateCategory(_ categoryTitle: String, at index: Int)
}

final class AddCategoryViewController: UIViewController {
    
    weak var createDelegate: CreateCategoryControllerDelegate?
    weak var editDelegate: EditCategoryControllerDelegate?
    
    private var categoryToEdit: String?
    private var categoryIndex: Int?
    private var isEditMode: Bool {
        categoryToEdit != nil
    }
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .grayYP
        button.setTitle(LocalizedStrings.done, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var nameCategoryTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = LocalizedStrings.categoryTextFieldPlaceholder
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
    
    convenience init(categoryToEdit: String?, index: Int? = nil) {
        self.init()
        self.categoryToEdit = categoryToEdit
        self.categoryIndex = index
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nameCategoryTextField.becomeFirstResponder()
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Позволяет одновременно обрабатывать другие тапы
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = isEditMode ? LocalizedStrings.editingCategory: LocalizedStrings.newCategory
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
        
        if let categoryEdit = categoryToEdit {
            nameCategoryTextField.text = categoryEdit
            updateDoneButtonState()
        }
    }
    
    private func updateDoneButtonState() {
        let trimmedText = nameCategoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isNameValid = !trimmedText.isEmpty
        
        if isEditMode {
            let isTextChanged = trimmedText != categoryToEdit
            doneButton.isEnabled = isNameValid && isTextChanged
        } else {
            doneButton.isEnabled = isNameValid
        }
        doneButton.backgroundColor = doneButton.isEnabled ? .blackDay : .grayYP
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            nameCategoryTextField.heightAnchor.constraint(equalToConstant: 75),
            nameCategoryTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameCategoryTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameCategoryTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func addSubviews() {
        [nameCategoryTextField, doneButton].forEach { view.addSubview($0) }
    }
    
    @objc private func doneButtonTapped() {
        let trimmedText = nameCategoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isNameValid = !trimmedText.isEmpty
        
        guard isNameValid else { return }
        
        if isEditMode, let index = categoryIndex {
            editDelegate?.didUpdateCategory(trimmedText, at: index)
        } else {
            createDelegate?.didCreateCategory(trimmedText)
        }
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        updateDoneButtonState()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AddCategoryViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if doneButton.isEnabled {
            doneButtonTapped()
        }
        return true
    }
}

