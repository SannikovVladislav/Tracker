//
//  CategoryViewModel.swift
//  Tracker
//
//  Created by Владислав on 16.11.2025.
//
import UIKit

typealias Binding<T> = (T) -> Void

final class CategoryViewModel {
    
    var categoriesDidChange: Binding<[TrackerCategory]>?
    var selectedCategoryDidChange: Binding<String?>?
    var showEmptyState: Binding<Bool>?
    var categories: [TrackerCategory] = [] {
        didSet {
            categoriesDidChange?(categories)
            showEmptyState?(categories.isEmpty)
        }
    }
    
    private var selectedCategory: String? {
        didSet {
            selectedCategoryDidChange?(selectedCategory)
        }
    }
    
    private let trackerCategoryStore: TrackerCategoryStore
    
    init(trackerCategoryStore: TrackerCategoryStore = TrackerCategoryStore()){
        self.trackerCategoryStore = trackerCategoryStore
    }
    
    func loadCategories() {
        do {
            categories = try trackerCategoryStore.fetchAllCategories()
        } catch {
            print("Error loading categories: \(error)")
            categories = []
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
    
    func createNewCategory(_ title: String) {
        let newCategory = TrackerCategory(title: title, trackers: [])
        
        do {
            try trackerCategoryStore.addCategory(newCategory)
            loadCategories()
        } catch {
            print("Error creating category: \(error)")
        }
    }
    
    func deleteCategory(at index: Int){
        guard index < categories.count else { return }
        
        let categoryToDelete = categories[index]
        
        do {
            try trackerCategoryStore.deleteCategory(with: categoryToDelete.title)
            loadCategories()
        } catch {
            print("Error deleting category: \(error)")
        }
    }
    
    func updateCategory(oldTitle: String, newTitle: String) {
        do {
            try trackerCategoryStore.deleteCategory(with: oldTitle)
            let updatedCategory = TrackerCategory(title: newTitle, trackers: [])
            try trackerCategoryStore.addCategory(updatedCategory)
            loadCategories()
        } catch {
            print("Error updating category: \(error)")
        }
    }
    
    func updateCategory(at index: Int, with newTitle: String) {
        guard index < categories.count else { return }
        
        let oldCategory = categories[index]
        updateCategory(oldTitle: oldCategory.title, newTitle: newTitle)
    }
    
    func getCategory(at index: Int) -> TrackerCategory? {
        guard index < categories.count else { return nil }
        return categories[index]
    }
}

