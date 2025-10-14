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

class CategoryViewController: UIViewController {
    //private var selectedCategory: String?
    weak var delegate: CategorySelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

