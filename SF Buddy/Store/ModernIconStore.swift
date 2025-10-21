import SwiftUI
import SwiftData
import Observation

// MARK: - Modern IconStore with @Observable and SwiftData

@Observable
@MainActor
class ModernIconStore {
    private var modelContext: ModelContext
    
    var searchText = ""
    var displayPreference: DisplayPreference = .default
    var aiGeneratedCategories: [String] = []
    
    // For symbol concepts (these are computed/hardcoded for now)
    private(set) var symbolConcepts: [SymbolConcept] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSymbolConcepts()
    }
    
    private func loadSymbolConcepts() {
        // Enhanced with categorized examples following the user's memories
        symbolConcepts = [
            // UI Elements
            SymbolConcept(name: "Delete", primarySymbol: "trash", category: .uiElements),
            SymbolConcept(name: "Share", primarySymbol: "square.and.arrow.up", category: .uiElements),
            SymbolConcept(name: "Add", primarySymbol: "plus", category: .uiElements),
            SymbolConcept(name: "Settings", primarySymbol: "gear", category: .uiElements),
            SymbolConcept(name: "Search", primarySymbol: "magnifyingglass", category: .uiElements),
            SymbolConcept(name: "Edit", primarySymbol: "pencil", category: .uiElements),
            SymbolConcept(name: "View", primarySymbol: "eye", category: .uiElements),
            
            // Entity Types  
            SymbolConcept(name: "User", primarySymbol: "person", category: .entityTypes),
            SymbolConcept(name: "Project", primarySymbol: "folder", category: .entityTypes),
            SymbolConcept(name: "Document", primarySymbol: "doc", category: .entityTypes),
            SymbolConcept(name: "Message", primarySymbol: "message", category: .entityTypes),
            SymbolConcept(name: "Event", primarySymbol: "calendar", category: .entityTypes),
            SymbolConcept(name: "Task", primarySymbol: "checkmark.square", category: .entityTypes),
            SymbolConcept(name: "Contact", primarySymbol: "person.crop.circle", category: .entityTypes),
        ]
    }
    
    // MARK: - Icon Management
    
    func fetchIcons() -> [SFIcon] {
        let descriptor = FetchDescriptor<SFIcon>(sortBy: [SortDescriptor(\.semanticName)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching icons: \(error)")
            return []
        }
    }
    
    func fetchTags() -> [SFTag] {
        let descriptor = FetchDescriptor<SFTag>(sortBy: [SortDescriptor(\.name)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
    
    func createIcon(semanticName: String, baseSymbol: String, isCustomAsset: Bool = false) {
        let icon = SFIcon(semanticName: semanticName, baseSymbol: baseSymbol, isCustomAsset: isCustomAsset)
        modelContext.insert(icon)
        save()
    }
    
    func createTag(name: String, color: String? = nil) -> SFTag {
        let tag = SFTag(name: name, color: color)
        modelContext.insert(tag)
        save()
        return tag
    }
    
    func createVariant(context: String, symbolName: String, for icon: SFIcon) {
        let variant = SFVariant(context: context, symbolName: symbolName)
        variant.icon = icon
        icon.variants.append(variant)
        modelContext.insert(variant)
        save()
    }
    
    func deleteIcon(_ icon: SFIcon) {
        modelContext.delete(icon)
        save()
    }
    
    func deleteTag(_ tag: SFTag) {
        modelContext.delete(tag)
        save()
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // MARK: - Symbol Concept Management
    
    func createSymbolConcept(name: String, primarySymbol: String, category: Category) {
        let concept = SymbolConcept(name: name, primarySymbol: primarySymbol, category: category)
        symbolConcepts.append(concept)
        // In a real implementation, you might want to persist these as well
    }
    
    func deleteSymbolConcept(_ concept: SymbolConcept) {
        symbolConcepts.removeAll { $0.id == concept.id }
    }
    
    func updateSymbolConcept(_ concept: SymbolConcept, name: String? = nil, primarySymbol: String? = nil) {
        if let index = symbolConcepts.firstIndex(where: { $0.id == concept.id }) {
            let updatedConcept = SymbolConcept(
                name: name ?? concept.name,
                primarySymbol: primarySymbol ?? concept.primarySymbol,
                category: concept.category,
                aiCategory: concept.aiCategory
            )
            symbolConcepts[index] = updatedConcept
        }
    }
}



// MARK: - SwiftUI View Extensions for SwiftData

extension View {
    func withIconStore(_ store: ModernIconStore) -> some View {
        self.environment(store)
    }
} 