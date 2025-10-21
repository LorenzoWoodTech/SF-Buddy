import SwiftUI
import Foundation



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

// MARK: - Symbol Variant
struct SymbolVariant: Hashable {
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
