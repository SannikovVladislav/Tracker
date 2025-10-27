//
//  EmojiCollectionView.swift
//  Tracker
//
//  Created by Владислав on 25.10.2025.
//

import UIKit

protocol EmojiSelectionDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
}

final class EmojiCollectionView: UIView {
    private var selectedIndexPath: IndexPath?
    weak var delegate: EmojiSelectionDelegate?
    
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 204)
        ])
    }
    
    func resetSelection() {
        selectedIndexPath = nil
        collectionView.reloadData()
    }
}

extension EmojiCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Emojies.emojiesCollection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as? EmojiCollectionViewCell else {
            return UICollectionViewCell()
        }
        let emoji = Emojies.emojiesCollection[indexPath.row]
        let isSelected = indexPath == selectedIndexPath
        cell.configure(with: emoji, isSelected: isSelected)
        return cell
    }
}

extension EmojiCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let previousIndexPath = selectedIndexPath {
            if let previousCell = collectionView.cellForItem(at: previousIndexPath) as? EmojiCollectionViewCell {
                previousCell.configure(with: Emojies.emojiesCollection[previousIndexPath.row], isSelected: false)
            }
        }
        selectedIndexPath = indexPath
        if let cell = collectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell {
            cell.configure(with: Emojies.emojiesCollection[indexPath.row], isSelected: true)
        }
        delegate?.didSelectEmoji(Emojies.emojiesCollection[indexPath.row])
    }
}
