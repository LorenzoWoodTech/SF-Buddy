import SwiftUI
import Foundation
import SFBuddyKit

// Import SymbolAction and SymbolActionRecord from SFBuddyKit
// (No need to redefine them here)

// MARK: - Sidebar Navigation

enum SidebarItem: String, CaseIterable, Hashable {
    case sfSymbols = "SF Symbols"
    
    var displayName: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .sfSymbols: return "square.3.layers.3d.middle.filled"
        }
    }
}

// MARK: - Grid Size and Rendering Mode aliases for compatibility
typealias BrowserGridSize = SFBuddyKit.SymbolGridSize
typealias BrowserRenderingMode = SFBuddyKit.SymbolRenderingMode

typealias SymbolGridSize = SFBuddyKit.SymbolGridSize
typealias SymbolRenderingStyle = SFBuddyKit.SymbolRenderingMode

enum SymbolType: String, CaseIterable {
    case system = "system"
    case custom = "custom"
}

// Stub class for compatibility
class IconStore: ObservableObject {
    @Published var symbols: [String] = []
    @Published var symbolConcepts: [SymbolConcept] = []
    
    init() {}
}

// MARK: - Category Enum
enum Category: String, CaseIterable {
    case uiElements = "UI Elements"
    case entityTypes = "Entity Types"
    
    var displayName: String { rawValue }
}

// MARK: - Symbol Concept
struct SymbolConcept: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let primarySymbol: String
    let variants: NSSet?
    let category: Category
    let aiCategory: String? // AI-generated category
    
    init(name: String, primarySymbol: String, variants: NSSet? = nil, category: Category, aiCategory: String? = nil) {
        self.name = name
        self.primarySymbol = primarySymbol
        self.variants = variants
        self.category = category
        self.aiCategory = aiCategory
    }
}

// MARK: - Symbol Variant (local app-specific version)
// Note: SFBuddyKit has its own SymbolVariant - this one is for SwiftData
struct LocalSymbolVariant: Hashable {
    let symbolName: String?
    let context: String?
    
    init(symbolName: String, context: String? = nil) {
        self.symbolName = symbolName
        self.context = context
    }
}

// MARK: - Display Preference
enum DisplayPreference: String, CaseIterable {
    case `default` = "Default"
    case monochrome = "Monochrome"
    case custom = "Custom"
    
    var displayName: String { rawValue }
}