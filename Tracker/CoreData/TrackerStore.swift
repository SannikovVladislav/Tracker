//
//  TrackerStore.swift
//  Tracker
//
//  Created by Владислав on 28.10.2025.
//
import CoreData
import UIKit

enum TrackerStoreError: Error {
    case decodingErrorInvalidTracker
    case decodingErrorInvalidId
    case decodingErrorInvalidName
    case decodingErrorInvalidColorHex
    case decodingErrorInvalidEmoji
    case decodingErrorInvalidSchedule
    case fetchError(Error)
    case saveError(Error)
}

struct TrackerStoreUpdate {
    struct Move: Hashable {
        let oldIndex: Int
        let newIndex: Int
    }
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
    let movedIndexes: Set<Move>
}

protocol TrackerStoreDelegate: AnyObject {
    func store(
        _ store: TrackerStore,
        didUpdate update: TrackerStoreUpdate
    )
}

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    
    weak var delegate: TrackerStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerStoreUpdate.Move>?
    
    var tracker: [Tracker] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap{ try? decodeTracker(from: $0) }
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
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
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
    
    func addTracker(_ tracker: Tracker, categoryTitle: String) throws {
        let categoryRequest = TrackerCategoryCoreData.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "title == %@", categoryTitle)
        
        guard let category = try context.fetch(categoryRequest).first else {
            throw TrackerStoreError.fetchError(NSError(domain: "TrackerStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Категория не найдена"]))
        }
        let trackerCoreData = TrackerCoreData(context: context)
        updateTracker(trackerCoreData, with: tracker)
        trackerCoreData.category = category
        
        try saveContext()
    }
    
    func updateTracker(_ trackerCoreData: TrackerCoreData, with tracker: Tracker)  {
        
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.colorHex = tracker.color.hexString
        trackerCoreData.emoji = tracker.emoji
        
        do {
            let scheduleData = try JSONEncoder().encode(tracker.schedule)
            trackerCoreData.schedule = scheduleData
        } catch {
            print("Ошибка кодирования расписания: \(error)")
            trackerCoreData.schedule = nil
        }
    }
    
    func deleteTracker(with id: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let tracker = try context.fetch(request).first {
            context.delete(tracker)
            try saveContext()
        }
    }
    
    func fetchTracker(with id: UUID) throws -> Tracker {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let trackerCoreData = try context.fetch(request).first else {
            throw TrackerStoreError.decodingErrorInvalidTracker
        }
        return try decodeTracker(from: trackerCoreData)
    }
    
    func fetchAllTrackers() throws -> [Tracker] {
        guard let trackers = fetchedResultsController.fetchedObjects else {
            throw TrackerStoreError.fetchError(NSError(domain: "", code: -1))
        }
        return try trackers.map { try decodeTracker(from: $0)}
    }
    
    private func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw TrackerStoreError.saveError(error)
        }
    }
    
    func decodeTracker(from trackerCoreData: TrackerCoreData) throws -> Tracker {
        guard let id = trackerCoreData.id else {
            throw TrackerStoreError.decodingErrorInvalidId
        }
        guard let name = trackerCoreData.name else {
            throw TrackerStoreError.decodingErrorInvalidName
        }
        guard let colorHex = trackerCoreData.colorHex else {
            throw TrackerStoreError.decodingErrorInvalidColorHex
        }
        guard let emoji = trackerCoreData.emoji else {
            throw TrackerStoreError.decodingErrorInvalidEmoji
        }
        var schedule: [Weekday] = []
        
        if let scheduleData = trackerCoreData.schedule {
            do {
                schedule = try JSONDecoder().decode([Weekday].self, from: scheduleData)
            } catch {
                print("Ошибка декодирования расписания: \(error)")
                throw TrackerStoreError.decodingErrorInvalidSchedule
            }
        }
        
        let color = colorHex.color
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerStoreUpdate.Move>()
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
            didUpdate: TrackerStoreUpdate(
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
            guard let indexPath = newIndexPath else { fatalError() }
            insertedIndexes?.insert(indexPath.item)
        case .delete:
            guard let indexPath = indexPath else { fatalError() }
            deletedIndexes?.insert(indexPath.item)
        case .update:
            guard let indexPath = indexPath else { fatalError() }
            updatedIndexes?.insert(indexPath.item)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else { fatalError() }
            movedIndexes?.insert(.init(oldIndex: oldIndexPath.item, newIndex: newIndexPath.item))
        @unknown default:
            fatalError()
        }
    }
}

