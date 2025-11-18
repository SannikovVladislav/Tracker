//
//  Untitled.swift
//  Tracker
//
//  Created by Владислав on 13.10.2025.
//
import UIKit

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

final class CategoryViewController: UIViewController {
    
    weak var delegate: CategorySelectionDelegate?
    weak var createDelegate: CreateCategoryControllerDelegate?
    weak var editDelegate: EditCategoryControllerDelegate?
    var selectedCategory: String?
    
    private var viewModel: CategoryViewModel
    
    init(viewModel: CategoryViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .trackerPlaceholder)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.numberOfLines = 2
        label.textAlignment = .center
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
    
    private lazy var categoryTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CategoryCell.self, forCellReuseIdentifier: "cellCategory")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = true
        tableView.layer.cornerRadius = 16
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .blackDay
        button.setTitle("Добавить категорию", for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadCategories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadCategories()
        categoryTableView.reloadData()
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = "Категория"
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
        updatePlaceholderVisibility()
    }
    
    func addSubviews() {
        [placeholderStack, categoryTableView, addCategoryButton].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),

            placeholderStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            categoryTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            categoryTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryTableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -16),
            
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func updatePlaceholderVisibility() {
        let hasCategories = !viewModel.categories.isEmpty
        placeholderStack.isHidden = hasCategories
        categoryTableView.isHidden = !hasCategories
    }
    
    private func setupBindings() {
        viewModel.categoriesDidChange = { [weak self] categories in
            self?.categoryTableView.reloadData()
            self?.updatePlaceholderVisibility()
        }
    }
    
    @objc private func addButtonTapped() {
        let addCategoryVC = AddCategoryViewController()
        addCategoryVC.createDelegate = self
        let addCategoryNC = UINavigationController(rootViewController: addCategoryVC)
        present(addCategoryNC, animated: true)
    }
    
    @objc private func categorySelected(_ sender: UIButton) {
        guard let categoryTitle = sender.titleLabel?.text else { return }
        selectedCategory = categoryTitle
        categoryTableView.reloadData()
    }
}

extension CategoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellCategory", for: indexPath) as? CategoryCell else
        { return UITableViewCell()}
        let category = viewModel.categories[indexPath.row].title
        let isSelected = (category == selectedCategory)
        
        cell.configure(with: category, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        var corners: CACornerMask = []
        if indexPath.row == 0 {
            corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        if indexPath.row == numberOfRows - 1 {
            corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            if let categoryCell = cell as? CategoryCell {
                categoryCell.hideSeparator()
            }
        } else {
            if let categoryCell = cell as? CategoryCell {
                categoryCell.showSeparator()
            }
        }
        cell.layer.maskedCorners = corners
        cell.layer.cornerRadius = !corners.isEmpty ? 16 : 0
        cell.layer.masksToBounds = !corners.isEmpty
        cell.backgroundColor = .lightGrayYP
    }
    
}


extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedCategory = viewModel.categories[indexPath.row].title
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, let selectedCategory = self.selectedCategory else { return }
            self.delegate?.didSelectCategory(selectedCategory)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            return self?.createContextMenu(for: indexPath)
        }
    }
    
    private func createContextMenu(for indexPath: IndexPath) -> UIMenu {
        let category = viewModel.categories[indexPath.row]
        let editAction = UIAction(
            title: "Редактировать") { [weak self] _ in
                self?.navigateToEditCategory(category, at: indexPath)}
        let deleteAction = UIAction(
            title: "Удалить", attributes: .destructive) { [weak self] _ in
                self?.deleteCategory(category, at: indexPath)}
        return UIMenu(children: [editAction, deleteAction])
    }
    
    private func navigateToEditCategory(_ category: TrackerCategory, at indexPath: IndexPath) {
        let editCategoryVC = AddCategoryViewController(categoryToEdit: category.title, index: indexPath.row)
        editCategoryVC.editDelegate = self
        editCategoryVC.createDelegate = nil
        
        let navigationController = UINavigationController(rootViewController: editCategoryVC)
        present(navigationController, animated: true)
    }
    
    private func deleteCategory(_ category: TrackerCategory, at indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: nil,
            message: "Эта категория точно не нужна?",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: indexPath.row)
            
            if self?.selectedCategory == category.title {
                self?.selectedCategory = nil
            }
            self?.categoryTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

extension CategoryViewController: CreateCategoryControllerDelegate {
    func didCreateCategory(_ categoryTitle: String) {
        viewModel.createNewCategory(categoryTitle)
        selectedCategory = categoryTitle
        categoryTableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.delegate?.didSelectCategory(categoryTitle)
            
            if self.navigationController != nil {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension CategoryViewController: EditCategoryControllerDelegate {
    func didUpdateCategory(_ categoryTitle: String, at index: Int) {
        viewModel.updateCategory(at: index, with: categoryTitle)
        categoryTableView.reloadData()
        
        if selectedCategory == viewModel.categories[index].title {
            selectedCategory = categoryTitle
        }
    }
}
