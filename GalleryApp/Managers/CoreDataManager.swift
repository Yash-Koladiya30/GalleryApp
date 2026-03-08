//
//  CoreDataManager.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import UIKit
import CoreData

class CoreDataManager {
    // MARK: - Singleton
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GalleryApp")
        
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // If migration fails due to programmatic model mismatch, safely wipe the old cache and recreate
                if let url = storeDescription.url {
                    try? FileManager.default.removeItem(at: url)
                    container.loadPersistentStores { _, _ in }
                }
            }
        })
        return container
    }()
    
    // MARK: - Context Operations
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    func savePhoto(id: String, author: String, data: Data) {
        DispatchQueue.main.async {
            let fetchRequest: NSFetchRequest<SavedPhoto> = NSFetchRequest(entityName: "SavedPhoto")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let results = try self.context.fetch(fetchRequest)
                let savedPhoto: SavedPhoto
                
                if let existing = results.first {
                    savedPhoto = existing
                } else {
                    savedPhoto = SavedPhoto(context: self.context)
                    savedPhoto.id = id
                    savedPhoto.createdAt = Date() // Persist order securely
                }
                
                savedPhoto.author = author
                savedPhoto.imageData = data
                
                self.saveContext()
            } catch {
                print("Error saving photo: \(error)")
            }
        }
    }
    
    func fetchSavedPhotos(page: Int = 1, limit: Int = 20) -> [SavedPhoto] {
        let fetchRequest: NSFetchRequest<SavedPhoto> = NSFetchRequest(entityName: "SavedPhoto")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        fetchRequest.fetchOffset = (page - 1) * limit
        fetchRequest.fetchLimit = limit
        
        var results: [SavedPhoto] = []
        context.performAndWait {
            do {
                results = try context.fetch(fetchRequest)
            } catch {
                print("Error fetching photos: \(error)")
            }
        }
        return results
    }
    
    func deleteAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SavedPhoto")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error deleting all: \(error)")
        }
    }
}
