//
//  StatisticsViewController.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//
import UIKit

final class StatisticsViewController: UIViewController {
    
    private var completedTrackersCount: Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    private lazy var trackerRecordStore: TrackerRecordStore = {
        let store = TrackerRecordStore()
        return store
    }()
    
    private lazy var statisticsLabel: UILabel = {
        let label = UILabel()
        label.text = LocalizedStrings.statistics
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var statisticsCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .whiteDay
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var gradientBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 17
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var statisticsValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .blackDay
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statisticsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .blackDay
        label.text = LocalizedStrings.completedTrackers
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .noFoundStatistics)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .blackDay
        label.text = LocalizedStrings.statisticsPlaceholder
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
        setupGradientBorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStatistics()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }
    
    private func setupUI() {
        configureView()
        addSubviews()
        setupConstraints()
    }
    
    private func configureView() {
        view.backgroundColor = .whiteDay
        addSubviews()
        updateUI()
    }
    
    private func addSubviews() {
        view.addSubview(gradientBorderView)
        [statisticsLabel, statisticsCardView, placeholderStack].forEach { view.addSubview($0) }
        statisticsCardView.addSubview(statisticsValueLabel)
        statisticsCardView.addSubview(statisticsTitleLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            // Statistics label
            statisticsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            //Statistics Card View
            statisticsCardView.topAnchor.constraint(equalTo: statisticsLabel.bottomAnchor, constant: 77),
            statisticsCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticsCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statisticsCardView.heightAnchor.constraint(equalToConstant: 90),
            
            //Statistics Value Label
            statisticsValueLabel.leadingAnchor.constraint(equalTo: statisticsCardView.leadingAnchor, constant: 12),
            statisticsValueLabel.topAnchor.constraint(equalTo: statisticsCardView.topAnchor, constant: 12),
            
            // Statistics Title Label
            statisticsTitleLabel.leadingAnchor.constraint(equalTo: statisticsCardView.leadingAnchor, constant: 12),
            statisticsTitleLabel.topAnchor.constraint(equalTo: statisticsValueLabel.bottomAnchor, constant: 7),
            
            //Placeholder Image
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            
            // Placeholder stack
            placeholderStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            placeholderStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 331)
            
        ])
    }
    
    private func setupGradientBorder() {
        view.insertSubview(gradientBorderView, belowSubview: statisticsCardView)
        
        NSLayoutConstraint.activate([
            gradientBorderView.topAnchor.constraint(equalTo: statisticsCardView.topAnchor, constant: -1),
            gradientBorderView.leadingAnchor.constraint(equalTo: statisticsCardView.leadingAnchor, constant: -1),
            gradientBorderView.trailingAnchor.constraint(equalTo: statisticsCardView.trailingAnchor, constant: 1),
            gradientBorderView.bottomAnchor.constraint(equalTo: statisticsCardView.bottomAnchor, constant: 1)
        ])
        
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.color1.cgColor,
            UIColor.color9.cgColor,
            UIColor.color3.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 17
        gradient.name = "borderGradient"
        
        gradientBorderView.layer.addSublayer(gradient)
    }
    
    private func updateGradientFrame() {
        if let gradientLayer = gradientBorderView.layer.sublayers?
            .first(where: { $0.name == "borderGradient" }) as? CAGradientLayer {
            gradientLayer.frame = gradientBorderView.bounds
        }
    }
    
    private func loadStatistics() {
        do {
            let records = try trackerRecordStore.fetchAllTrackerRecords()
            let uniqueCompletedTrackerIDs = Set(records.map { $0.trackerId })
            completedTrackersCount = uniqueCompletedTrackerIDs.count
        } catch {
            print("Error loading statistics: \(error)")
            completedTrackersCount = 0
        }
    }
    
    private func updateUI() {
        let hasStatistics = completedTrackersCount > 0
        
        statisticsCardView.isHidden = !hasStatistics
        gradientBorderView.isHidden = !hasStatistics
        placeholderStack.isHidden = hasStatistics
        
        if hasStatistics {
            statisticsValueLabel.text = "\(completedTrackersCount)"
        }
    }
}
