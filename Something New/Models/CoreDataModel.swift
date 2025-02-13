import Foundation
import CoreData

class CoreDataModel {
    static let shared = CoreDataModel()
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "TodoModel")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Error loading persistent stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
} 