//
//  PersistenceController.swift
//  SF Buddy
//
//  Core Data stack manager with CloudKit support and preview data
//

import CoreData
import Foundation

/// Manages the Core Data stack for SFBuddy with CloudKit sync capability
struct PersistenceController {
    /// Shared instance for the main app
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        createPreviewData(in: viewContext)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error creating preview data \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    /// The Core Data persistent container
    let container: NSPersistentCloudKitContainer

    /// Initialize the persistence controller
    /// - Parameter inMemory: Whether to use in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SFBuddy")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit (but keep disabled initially as per plan)
            let storeDescription = container.persistentStoreDescriptions.first!
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit configuration - uncomment when ready to enable sync
            // storeDescription.setOption(true as NSNumber, forKey: NSPersistentCloudKitContainerOptionsKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In production, handle this more gracefully
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Save the view context if there are changes
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Preview Data Creation
private extension PersistenceController {
    static func createPreviewData(in context: NSManagedObjectContext) {
        // Create sample tags
        let uiTag = Tag(context: context)
        uiTag.name = "UI"
        uiTag.color = "blue"
        
        let navigationTag = Tag(context: context)
        navigationTag.name = "Navigation"
        navigationTag.color = "green"
        
        let statusTag = Tag(context: context)
        statusTag.name = "Status"
        statusTag.color = "orange"
        
        let businessTag = Tag(context: context)
        businessTag.name = "Business"
        businessTag.color = "purple"
        
        // Create sample icons
        let homeIcon = Icon(context: context)
        homeIcon.semanticName = "home"
        homeIcon.baseSymbol = "house"
        homeIcon.isCustomAsset = false
        homeIcon.dateCreated = Date()
        homeIcon.dateModified = Date()
        homeIcon.tags = NSSet(array: [uiTag, navigationTag])
        
        // Add variant for home icon
        let homeSidebarVariant = Variant(context: context)
        homeSidebarVariant.context = "sidebar"
        homeSidebarVariant.symbolName = "house.fill"
        homeSidebarVariant.icon = homeIcon
        
        let settingsIcon = Icon(context: context)
        settingsIcon.semanticName = "settings"
        settingsIcon.baseSymbol = "gear"
        settingsIcon.isCustomAsset = false
        settingsIcon.dateCreated = Date()
        settingsIcon.dateModified = Date()
        settingsIcon.tags = NSSet(array: [uiTag])
        
        let searchIcon = Icon(context: context)
        searchIcon.semanticName = "search"
        searchIcon.baseSymbol = "magnifyingglass"
        searchIcon.isCustomAsset = false
        searchIcon.dateCreated = Date()
        searchIcon.dateModified = Date()
        searchIcon.tags = NSSet(array: [uiTag])
        
        let successIcon = Icon(context: context)
        successIcon.semanticName = "success"
        successIcon.baseSymbol = "checkmark.circle"
        successIcon.isCustomAsset = false
        successIcon.dateCreated = Date()
        successIcon.dateModified = Date()
        successIcon.tags = NSSet(array: [statusTag])
        
        let errorIcon = Icon(context: context)
        errorIcon.semanticName = "error"
        errorIcon.baseSymbol = "xmark.circle"
        errorIcon.isCustomAsset = false
        errorIcon.dateCreated = Date()
        errorIcon.dateModified = Date()
        errorIcon.tags = NSSet(array: [statusTag])
        
        let invoicesIcon = Icon(context: context)
        invoicesIcon.semanticName = "invoices"
        invoicesIcon.baseSymbol = "doc.text.image"
        invoicesIcon.isCustomAsset = false
        invoicesIcon.dateCreated = Date()
        invoicesIcon.dateModified = Date()
        invoicesIcon.tags = NSSet(array: [businessTag])
    }
}
