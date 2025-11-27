//
//  FiltersViewController.swift
//  Tracker
//
//  Created by Владислав on 26.11.2025.
//
import UIKit


protocol FiltersSelectionDelegate: AnyObject {
    func didSelectFilter(_ filter: FilterType)
}

final class FiltersViewController: UIViewController {
    
    private let filters = FilterType.allCases
    var selectedFilter: FilterType = .allTrackers
    weak var delegate: FiltersSelectionDelegate?
    
    private lazy var filtersTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellFilters")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 16
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    init(selectedFilter: FilterType = .allTrackers) {
        self.selectedFilter = selectedFilter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        configureView()
        view.addSubview(filtersTableView)
        setupConstraints()
        
    }
    
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = LocalizedStrings.filters
        
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            //Category and Schedule TableView
            filtersTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            filtersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filtersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filtersTableView.heightAnchor.constraint(equalToConstant: CGFloat(filters.count * 75)),
        ])
    }
    
    private func createCheckmarkImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .blueYP
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        return imageView
    }
}

extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellFilters", for: indexPath)
        let filter = filters[indexPath.row]
        cell.textLabel?.text = filter.title
        cell.backgroundColor = .backgroundDay
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .blackDay
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        if filter == selectedFilter && (filter == .completed || filter == .incomplete) {
            cell.accessoryView = createCheckmarkImageView()
        } else {
            cell.accessoryView = nil
        }
        
        return cell
    }
}

extension FiltersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFilter = filters[indexPath.row]
        self.selectedFilter = selectedFilter
        
        for (index, filter) in filters.enumerated() {
            let cellIndexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: cellIndexPath) {
                if index == indexPath.row && (filter == .completed || filter == .incomplete) {
                    cell.accessoryView = createCheckmarkImageView()
                } else {
                    cell.accessoryView = nil
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            delegate?.didSelectFilter(selectedFilter)
            dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == filters.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}


