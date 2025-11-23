//
//  ScheduleViewController.swift
//  Tracker
//
//  Created by Владислав on 13.10.2025.
//
import UIKit

protocol ScheduleSelectionDelegate: AnyObject {
    func didSelectSchedule(_ schedule: [Weekday])
}

class ScheduleViewController: UIViewController {
    
    var selectedDays: [Weekday] = []
    weak var delegate: ScheduleSelectionDelegate?
    
    private lazy var scheduleTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellSchedule")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 16
        tableView.translatesAutoresizingMaskIntoConstraints = false        
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 16
        button.backgroundColor = .blackDay
        button.setTitle(LocalizedStrings.done, for: .normal)
        button.setTitleColor(.whiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        title = LocalizedStrings.schedule
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
    }
    
    func addSubviews() {
        [scheduleTableView, doneButton].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            //Category and Schedule TableView
            scheduleTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scheduleTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scheduleTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scheduleTableView.heightAnchor.constraint(equalToConstant: CGFloat(Weekday.allCases.count * 75)),
            
            // Cancel Button
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func doneButtonTapped() {
        let sortedDays = selectedDays.sorted { $0.rawValue < $1.rawValue }
        delegate?.didSelectSchedule(sortedDays)
        dismiss(animated: true)
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Weekday.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellSchedule", for: indexPath)
        let weekday = Weekday.allCases[indexPath.row]
        cell.textLabel?.text = weekday.fullName
        cell.backgroundColor = .lightGrayYP
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .blackDay
        
        let switchView = UISwitch()
        switchView.tag = weekday.rawValue
        switchView.onTintColor = .blueYP
        switchView.isOn = selectedDays.contains(weekday)
        switchView.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        cell.accessoryView = switchView
        return cell
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        guard let weekday = Weekday(rawValue: sender.tag) else { return }
        
        if sender.isOn {
            if !selectedDays.contains(weekday) {
                selectedDays.append(weekday)
            }
        } else {
            selectedDays.removeAll { $0 == weekday }
        }
        selectedDays.sort { $0.rawValue < $1.rawValue }
    }
}

extension ScheduleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == Weekday.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}

