import SwiftData
import Foundation
import SF_Buddy_Package

// MARK: - SwiftData Models

@Model
final class SFIcon {
    var semanticName: String = ""
    var baseSymbol: String = ""
    var isCustomAsset: Bool = false
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \SFVariant.icon)
    var variants: [SFVariant] = []
    
    @Relationship(inverse: \SFTag.icons)
    var tags: [SFTag] = []
    
    init(semanticName: String, baseSymbol: String, isCustomAsset: Bool = false) {
        self.semanticName = semanticName
        self.baseSymbol = baseSymbol
        self.isCustomAsset = isCustomAsset
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

@Model
final class SFTag {
    var name: String = ""
    var color: String?
    
    @Relationship
    var icons: [SFIcon] = []
    
    init(name: String, color: String? = nil) {
        self.name = name
        self.color = color
    }
}

@Model
final class SFVariant {
    var context: String = ""
    var symbolName: String = ""
    
    @Relationship
    var icon: SFIcon?
    
    init(context: String, symbolName: String) {
        self.context = context
        self.symbolName = symbolName
    }
}

@Model 
final class RecentSearch {
    @Attribute(.unique) var searchTerm: String = ""
    var dateSearched: Date = Date()
    var selectedSymbol: String?
    var lastActionDate: Date?
    var actionType: String? // "copied" or "exported"
    var timesUsed: Int = 0
    var actionLog: [SymbolActionRecord] = []
    
    init(searchTerm: String, selectedSymbol: String? = nil) {
        self.searchTerm = searchTerm
        self.selectedSymbol = selectedSymbol
        self.dateSearched = Date()
        self.timesUsed = 0
        self.actionLog = []
    }
    
    func recordAction(_ action: SymbolAction) {
        lastActionDate = Date()
        actionType = action.rawValue
        timesUsed += 1
        actionLog.append(SymbolActionRecord(action: action, date: Date()))
    }
}

// MARK: - Legacy Support (keeping old SymbolAction for compatibility)

enum LegacySymbolAction: String, CaseIterable {
    case copied = "copied"
    case exported = "exported"
    
    var displayName: String {
        switch self {
        case .copied: return "Copied"
        case .exported: return "Exported"
        }
    }
    
    var systemImage: String {
        switch self {
        case .copied: return "doc.on.clipboard"
        case .exported: return "square.and.arrow.up"
        }
    }
}

// MARK: - SwiftData Container Configuration

struct SwiftDataContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            SFIcon.self,
            SFTag.self,
            SFVariant.self,
            RecentSearch.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Can be enabled later: .private("iCloud.com.yourcompany.sfbuddy")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    static var preview: ModelContainer = {
        let schema = Schema([
            SFIcon.self,
            SFTag.self,
            SFVariant.self,
            RecentSearch.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Create preview data
            Task { @MainActor in
                createPreviewData(in: container.mainContext)
            }
            
            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }()
    
    private static func createPreviewData(in context: ModelContext) {
        // Create sample tags
        let uiTag = SFTag(name: "UI", color: "blue")
        let navigationTag = SFTag(name: "Navigation", color: "green")
        let statusTag = SFTag(name: "Status", color: "orange")
        let businessTag = SFTag(name: "Business", color: "purple")
        
        context.insert(uiTag)
        context.insert(navigationTag)
        context.insert(statusTag)
        context.insert(businessTag)
        
        // Create sample icons
        let homeIcon = SFIcon(semanticName: "home", baseSymbol: "house")
        homeIcon.tags = [uiTag, navigationTag]
        
        // Add variant for home icon
        let homeSidebarVariant = SFVariant(context: "sidebar", symbolName: "house.fill")
        homeSidebarVariant.icon = homeIcon
        homeIcon.variants = [homeSidebarVariant]
        
        let settingsIcon = SFIcon(semanticName: "settings", baseSymbol: "gear")
        settingsIcon.tags = [uiTag]
        
        let searchIcon = SFIcon(semanticName: "search", baseSymbol: "magnifyingglass")
        searchIcon.tags = [uiTag]
        
        let successIcon = SFIcon(semanticName: "success", baseSymbol: "checkmark.circle")
        successIcon.tags = [statusTag]
        
        let errorIcon = SFIcon(semanticName: "error", baseSymbol: "xmark.circle")
        errorIcon.tags = [statusTag]
        
        let invoicesIcon = SFIcon(semanticName: "invoices", baseSymbol: "doc.text.image")
        invoicesIcon.tags = [businessTag]
        
        // Insert icons
        [homeIcon, settingsIcon, searchIcon, successIcon, errorIcon, invoicesIcon].forEach { icon in
            context.insert(icon)
        }
        
        // Insert variant
        context.insert(homeSidebarVariant)
        
        // Create sample recent searches
        let searchHome = RecentSearch(searchTerm: "home screen icon", selectedSymbol: "house.fill")
        searchHome.recordAction(.copied)
        
        let searchUser = RecentSearch(searchTerm: "user profile", selectedSymbol: "person.circle")
        searchUser.recordAction(.exported)
        
        let searchSettings = RecentSearch(searchTerm: "app settings", selectedSymbol: "gear")
        searchSettings.recordAction(.copied)
        
        [searchHome, searchUser, searchSettings].forEach { search in
            context.insert(search)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }
    }
}