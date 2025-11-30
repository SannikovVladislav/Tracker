//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Владислав on 28.10.2025.
//
import CoreData
import UIKit

enum TrackerRecordStoreError: Error {
    case decodingErrorInvalidTrackerRecord
    case decodingErrorInvalidTrackerId
    case decodingErrorInvalidDate
    case fetchError(Error)
    case saveError(Error)
}

struct TrackerRecordStoreUpdate {
    struct Move: Hashable {
        let oldIndex: Int
        let newIndex: Int
    }
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
    let movedIndexes: Set<Move>
}

protocol TrackerRecordStoreDelegate: AnyObject {
    func store(
        _ store: TrackerRecordStore,
        didUpdate update: TrackerRecordStoreUpdate
    )
}

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>!
    
    weak var delegate: TrackerRecordStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerRecordStoreUpdate.Move>?
    
    var records: [TrackerRecord] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap{ try? decodeTrackerRecord(from: $0) }
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
        
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
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
    
    func addTrackerRecord(_ record: TrackerRecord) throws {
        let trackerRecordCoreData = TrackerRecordCoreData(context: context)
        updateTrackerRecord(trackerRecordCoreData, with: record)
        
        try saveContext()
    }
    
    func updateTrackerRecord(_ trackerRecordCoreData: TrackerRecordCoreData, with record: TrackerRecord)  {
        trackerRecordCoreData.trackerId = record.trackerId
        trackerRecordCoreData.date = record.date
    }
    
    func deleteTracker(with trackerId: UUID, date: Date) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@",
                                        trackerId as CVarArg,
                                        date as CVarArg)
        if let record = try context.fetch(request).first {
            context.delete(record)
            try saveContext()
        }
    }
    
    func fetchTrackerRecord(with trackerId: UUID) throws -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
        let trackerRecordCoreData = try context.fetch(request)
        
        return try trackerRecordCoreData.map { try decodeTrackerRecord(from: $0) }
    }
    
    func fetchAllTrackerRecords() throws -> [TrackerRecord] {
        guard let records = fetchedResultsController.fetchedObjects else {
            throw TrackerRecordStoreError.fetchError(NSError(domain: "", code: -1))
        }
        return try records.map { try decodeTrackerRecord(from: $0)}
    }
    
    private func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw TrackerRecordStoreError.saveError(error)
        }
    }
    
    func decodeTrackerRecord(from trackerRecordCoreData: TrackerRecordCoreData) throws -> TrackerRecord {
        guard let trackerId = trackerRecordCoreData.trackerId else {
            throw TrackerRecordStoreError.decodingErrorInvalidTrackerId
        }
        guard let date = trackerRecordCoreData.date else {
            throw TrackerRecordStoreError.decodingErrorInvalidDate
        }
        return TrackerRecord(
            trackerId: trackerId,
            date: date
        )
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerRecordStoreUpdate.Move>()
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
            didUpdate: TrackerRecordStoreUpdate(
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
