//
//  ColorCollectionView.swift
//  Tracker
//
//  Created by Владислав on 25.10.2025.
//

import UIKit

protocol ColorSelectionDelegate: AnyObject {
    func didSelectColor(_ color: UIColor)
}

final class ColorCollectionView: UIView {
    private var selectedIndexPath: IndexPath?
    weak var delegate: ColorSelectionDelegate?
    
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: "ColorCell")
        collectionView.dataSource = self
        collectionView.delegate = self
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
}

extension ColorCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        UIColor.colorYP.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as? ColorCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: UIColor.colorYP[indexPath.row])
        return cell
    }
}

extension ColorCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for selectedIndex in collectionView.indexPathsForSelectedItems ?? [] where selectedIndex != indexPath {
            collectionView.deselectItem(at: selectedIndex, animated: false)
            if let cell = collectionView.cellForItem(at: selectedIndex) as? ColorCollectionViewCell {
                cell.isSelected = false
            }
        }
        delegate?.didSelectColor(UIColor.colorYP[indexPath.row])
    }
}
