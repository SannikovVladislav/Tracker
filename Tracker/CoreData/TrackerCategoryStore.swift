//
//  TrackerCategoryStore.swift
//  Tracker
//
//  Created by Владислав on 28.10.2025.
//
import CoreData
import UIKit

enum TrackerCategoryStoreError: Error {
    case decodingErrorInvalidTrackerCategory
    case decodingErrorInvalidTitle
    case decodingErrorInvalidTrackers
    case fetchError(Error)
    case saveError(Error)
}

struct TrackerCategoryStoreUpdate {
    struct Move: Hashable {
        let oldIndex: Int
        let newIndex: Int
    }
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
    let movedIndexes: Set<Move>
}

protocol TrackerCategoryStoreDelegate: AnyObject {
    func store(
        _ store: TrackerCategoryStore,
        didUpdate update: TrackerCategoryStoreUpdate
    )
}

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>!
    
    weak var delegate: TrackerCategoryStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerCategoryStoreUpdate.Move>?
    
    var categories: [TrackerCategory] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap{ try? decodeTrackerCategory(from: $0) }
    }
    
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.init(context: context)
    }
    
    init(context: NSManagedObjectContext){
        self.context = context
        super.init()
        
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    func addCategory(_ category: TrackerCategory) throws {
        let trackerCategoryCoreData = TrackerCategoryCoreData(context: context)
        updateCategory(trackerCategoryCoreData, with: category)
        
        for tracker in category.trackers {
            let trackerCoreData = TrackerCoreData(context: context)
            trackerCoreData.id = tracker.id
            trackerCoreData.name = tracker.name
            trackerCoreData.colorHex = tracker.color.hexString
            trackerCoreData.emoji = tracker.emoji
            
            do {
                let scheduleData = try JSONEncoder().encode(tracker.schedule)
                trackerCoreData.schedule = scheduleData
            } catch {
                print("Ошибка кодирования расписания: \(error)")
            }
            
            trackerCoreData.category = trackerCategoryCoreData
        }
        try saveContext()
    }
        
        func updateCategory(_ trackerCategoryCoreData: TrackerCategoryCoreData, with category: TrackerCategory)  {
            trackerCategoryCoreData.title = category.title
        }
        
        func deleteCategory(with title: String) throws {
            let request = TrackerCategoryCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "title == %@", title)
            
            if let category = try context.fetch(request).first {
                context.delete(category)
                try saveContext()
            }
        }
        
        func fetchCategory(with title: String) throws -> TrackerCategory? {
            let request = TrackerCategoryCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "title == %@", title)
            
            if let categoryCoreData = try context.fetch(request).first {
                return try decodeTrackerCategory(from: categoryCoreData)
            }
            return nil
        }
        
        func fetchAllCategories() throws -> [TrackerCategory] {
            guard let categories = fetchedResultsController.fetchedObjects else {
                throw TrackerCategoryStoreError.fetchError(NSError(domain: "", code: -1))
            }
            return try categories.map { try decodeTrackerCategory(from: $0)}
        }
        
        func saveContext() throws {
            guard context.hasChanges else { return }
            
            do {
                try context.save()
            } catch {
                context.rollback()
                throw TrackerCategoryStoreError.saveError(error)
            }
        }
        
        func decodeTrackerCategory(from trackerCategoryCoreData: TrackerCategoryCoreData) throws -> TrackerCategory {
            guard let title = trackerCategoryCoreData.title else {
                throw TrackerCategoryStoreError.decodingErrorInvalidTitle
            }
            
            var trackers: [Tracker] = []
            if let trackerCoreDataSet = trackerCategoryCoreData.trackers as? Set<TrackerCoreData> {
                trackers = trackerCoreDataSet.compactMap { trackerCoreData in
                    do {
                        return try decodeTracker(from: trackerCoreData)
                    } catch {
                        print("Ошибка декодирования трекера: \(error)")
                        return nil
                    }
                }
            }
            
            return TrackerCategory(
                title: title,
                trackers: trackers
            )
        }
    

        func decodeTracker(from trackerCoreData: TrackerCoreData) throws -> Tracker {
            guard let id = trackerCoreData.id,
                  let name = trackerCoreData.name,
                  let colorHex = trackerCoreData.colorHex,
                  let emoji = trackerCoreData.emoji else {
                throw TrackerCategoryStoreError.decodingErrorInvalidTrackers
            }
            
            let color = colorHex.color
            
            var schedule: [Weekday] = []
            if let scheduleData = trackerCoreData.schedule {
                do {
                    schedule = try JSONDecoder().decode([Weekday].self, from: scheduleData)
                } catch {
                    print("Ошибка декодирования расписания: \(error)")
                    throw TrackerCategoryStoreError.decodingErrorInvalidTrackers
                }
            }
            
            return Tracker(
                id: id,
                name: name,
                color: color,
                emoji: emoji,
                schedule: schedule
            )
        }
    }

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerCategoryStoreUpdate.Move>()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let insertedIndexes = insertedIndexes,
              let deletedIndexes = deletedIndexes,
              let updatedIndexes = updatedIndexes,
              let movedIndexes = movedIndexes else {
            return
        }
        
        delegate?.store(
            self,
            didUpdate: TrackerCategoryStoreUpdate(
                insertedIndexes: insertedIndexes,
                deletedIndexes: deletedIndexes,
                updatedIndexes: updatedIndexes,
                movedIndexes: movedIndexes
            )
        )
        self.insertedIndexes = nil
        self.deletedIndexes = nil
        self.updatedIndexes = nil
        self.movedIndexes = nil
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else {
                assertionFailure("Received insert event without newIndexPath")
                print("Error: Received insert event without newIndexPath")
                return
            }
            insertedIndexes?.insert(indexPath.item)
        case .delete:
            guard let indexPath = indexPath else {
                assertionFailure("Received delete event without indexPath")
                print("Error: Received delete event without newIndexPath")
                return
            }
            deletedIndexes?.insert(indexPath.item)
        case .update:
            guard let indexPath = indexPath else {
                assertionFailure("Received update event without indexPath")
                print("Error: Received update event without newIndexPath")
                return
            }
            updatedIndexes?.insert(indexPath.item)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else {
                assertionFailure("Received move event without proper indexPath")
                print("Error: Received move event without proper newIndexPath")
                return
            }
            movedIndexes?.insert(.init(oldIndex: oldIndexPath.item, newIndex: newIndexPath.item))
            
        @unknown default:
            assertionFailure("Received unknown NSFetchedResultsChangeType")
            print("Warning: Received unknown NSFetchedResultsChangeType: \(type)")
        }
    }
}
