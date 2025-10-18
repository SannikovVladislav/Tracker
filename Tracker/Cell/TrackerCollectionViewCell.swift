//
//  Untitled.swift
//  Tracker
//
//  Created by Владислав on 14.10.2025.
//
import UIKit

class TrackerCollectionViewCell: UICollectionViewCell {
    
    private var tracker: Tracker?
    private var trackerId: UUID?
    private var currentDate: Date = Date()
    private var isCompletedToday: Bool = false
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }()
    
    var onCompletion: ((UUID, Date, Bool) -> Void)?
    static let identifier = "TrackerCollectionViewCell"
    
    private lazy var cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var emojiBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundDay
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.clipsToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .whiteDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dayCounterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .blackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 17
        button.tintColor = .white
        button.backgroundColor = .color5
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubviews()
        setupConstraints()
    }
    
    private func addSubviews() {
        contentView.addSubview(cardView)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(nameLabel)
        contentView.addSubview(dayCounterLabel)
        contentView.addSubview(plusButton)
        cardView.addSubview(emojiBackgroundView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            //Card View
            cardView.heightAnchor.constraint(equalToConstant: 90),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            //Emoji Background View
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: 24),
            emojiBackgroundView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            
            // Emoji Label
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackgroundView.centerYAnchor),
            
            // Name Label
            nameLabel.heightAnchor.constraint(equalToConstant: 34),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            // Day Counter Label
            dayCounterLabel.heightAnchor.constraint(equalToConstant: 18),
            dayCounterLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            dayCounterLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16),
            
            // Plus button
            plusButton.centerYAnchor.constraint(equalTo: dayCounterLabel.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    func configure(with tracker: Tracker, completedDays: Int, isCompletedToday: Bool, currentDate: Date) {
        
        self.tracker = tracker
        self.trackerId = tracker.id
        self.currentDate = currentDate
        self.isCompletedToday = isCompletedToday
        
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name
        dayCounterLabel.text = "\(completedDays) дней"
        cardView.backgroundColor = tracker.color
        updateButtonAppearance(trackerColor: tracker.color)
    }
    
    private func updateButtonAppearance(trackerColor: UIColor) {
        let image = isCompletedToday ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus")
        plusButton.setImage(image, for: .normal)
        plusButton.backgroundColor = isCompletedToday ? trackerColor.withAlphaComponent(0.3) : trackerColor
    }
    
    @objc private func plusButtonTapped() {
        let today = calendar.startOfDay(for: Date())
        let selectedDate = calendar.startOfDay(for: currentDate)
        
        guard let trackerId = trackerId,
              let tracker = tracker else { return }
        
        if tracker.schedule.isEmpty {
            guard calendar.isDate(selectedDate, inSameDayAs: today) else { return }
        } else {
            guard selectedDate <= today else { return }
        }
        isCompletedToday.toggle()
        updateButtonAppearance(trackerColor: cardView.backgroundColor ?? .color5)
        onCompletion?(trackerId, currentDate, isCompletedToday)
    }
}

