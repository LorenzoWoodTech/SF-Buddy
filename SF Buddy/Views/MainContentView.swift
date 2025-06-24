//
//  MainContentView.swift
//  SF Buddy
//
//  Modern NavigationSplitView implementation following HIG guidelines
//

import SwiftUI
import CoreData

struct MainContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var iconStore = IconStore(context: PersistenceController.shared.container.viewContext)
    
    // Navigation state
    @State private var selectedSidebarItem: SidebarItem? = .sfSymbols
    @State private var selectedSymbolConcept: SymbolConcept?
    @State private var selectedIcon: Icon?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Sheets and overlays
    @State private var showingAddConceptSheet = false
    @State private var showingSymbolPicker = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar
            SidebarView(
                selectedItem: $selectedSidebarItem,
                iconStore: iconStore,
                showingAddConceptSheet: $showingAddConceptSheet,
                showingSettings: $showingSettings
            )
        } content: {
            // MARK: - Content View
                            ContentListView(
                    selectedSidebarItem: selectedSidebarItem,
                    selectedSymbolConcept: $selectedSymbolConcept,
                    selectedIcon: $selectedIcon,
                    iconStore: iconStore,
                    showingSymbolPicker: $showingSymbolPicker,
                    showingAddConceptSheet: $showingAddConceptSheet
                )
        } detail: {
            // MARK: - Detail View
            DetailView(
                iconStore: iconStore,
                selectedItem: selectedSidebarItem,
                selectedSymbolConcept: $selectedSymbolConcept
            )
        }
        .navigationSplitViewStyle(.balanced)
        // .searchable(text: $iconStore.searchText, prompt: "Search symbols and concepts...")
        .sheet(isPresented: $showingAddConceptSheet) {
            QuickAddConceptView(iconStore: iconStore, onConceptCreated: { concept in
                selectedSymbolConcept = concept
                showingAddConceptSheet = false
            })
        }
        .sheet(isPresented: $showingSymbolPicker) {
            SFSymbolBrowserView(selectedSymbol: .constant(nil))
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            iconStore.updateContext(viewContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Handle keyboard shortcuts through the app delegate or commands
        }
    }
}

// MARK: - Types are now imported from SharedTypes.swift

// MARK: - Icon Store

/// Comprehensive IconStore following modern SwiftUI patterns
class IconStore: ObservableObject {
    @Published var icons: [Icon] = []
    @Published var symbolConcepts: [SymbolConcept] = []
    @Published var tags: [Tag] = []
    @Published var searchText = ""
    @Published var aiGeneratedCategories: [String] = [] // AI-generated categories
    @Published var displayPreference: DisplayPreference = .default // Display preference for concept colors
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchAllData()
    }
    
    func updateContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        fetchAllData()
    }
    
    private func fetchAllData() {
        fetchIcons()
        fetchSymbolConcepts()
        fetchTags()
    }
    
    private func fetchIcons() {
        let request: NSFetchRequest<Icon> = Icon.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Icon.semanticName, ascending: true)]
        
        do {
            icons = try viewContext.fetch(request)
        } catch {
            print("Error fetching icons: \(error)")
            icons = []
        }
    }
    
    private func fetchSymbolConcepts() {
        // Enhanced with categorized examples
        symbolConcepts = [
            // UI Elements
            SymbolConcept(name: "Delete", primarySymbol: "trash", category: .uiElements),
            SymbolConcept(name: "Share", primarySymbol: "square.and.arrow.up", category: .uiElements),
            SymbolConcept(name: "Add", primarySymbol: "plus", category: .uiElements),
            SymbolConcept(name: "Settings", primarySymbol: "gear", category: .uiElements),
            SymbolConcept(name: "Search", primarySymbol: "magnifyingglass", category: .uiElements),
            SymbolConcept(name: "Edit", primarySymbol: "pencil", category: .uiElements),
            
            // Entity Types  
            SymbolConcept(name: "User", primarySymbol: "person", category: .entityTypes),
            SymbolConcept(name: "Project", primarySymbol: "folder", category: .entityTypes),
            SymbolConcept(name: "Document", primarySymbol: "doc", category: .entityTypes),
            SymbolConcept(name: "Message", primarySymbol: "message", category: .entityTypes),
            SymbolConcept(name: "Event", primarySymbol: "calendar", category: .entityTypes),
        ]
    }
    
    private func fetchTags() {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            tags = try viewContext.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
            tags = []
        }
    }
    
    // MARK: - Computed Properties for Counts
    var symbolConceptsCount: Int { symbolConcepts.count }
    var uiCategoriesCount: Int { symbolConcepts.filter { $0.category == .uiElements }.count }
    var entityCategoriesCount: Int { symbolConcepts.filter { $0.category == .entityTypes }.count }
    var allIconsCount: Int { icons.count }
    var recentCount: Int { recentIcons.count }
    var favoritesCount: Int { favoriteIcons.count }
    var customAssetsCount: Int { customAssets.count }
    var variantsCount: Int { iconsWithVariants.count }
    
    // MARK: - Filtered Collections
    var recentIcons: [Icon] {
        icons
            .filter { $0.dateModified != nil }
            .sorted { ($0.dateModified ?? Date.distantPast) > ($1.dateModified ?? Date.distantPast) }
            .prefix(20)
            .map { $0 }
    }
    
    var favoriteIcons: [Icon] {
        // For now, return empty array until we add favorite functionality
        []
    }
    
    var allIcons: [Icon] {
        icons
    }
    
    var variantIcons: [Icon] {
        // Icons that have variants
        icons.filter { _ in false } // Placeholder - no variants yet
    }
    
    var customAssets: [Icon] {
        icons.filter { $0.isCustomAsset }
    }
    
    var iconsWithVariants: [Icon] {
        icons.filter { ($0.variants?.count ?? 0) > 0 }
    }
    
    func icons(for tag: Tag) -> [Icon] {
        guard let tagIcons = tag.icons?.allObjects as? [Icon] else { return [] }
        return tagIcons.sorted { ($0.semanticName ?? "") < ($1.semanticName ?? "") }
    }
    
    // MARK: - AI Category Generation
    func generateAICategories() {
        // Simulate AI analysis of symbol concepts
        let conceptNames = symbolConcepts.map { $0.name.lowercased() }
        
        // AI-powered categorization logic (placeholder - replace with actual AI)
        var categories: Set<String> = []
        
        for name in conceptNames {
            if name.contains("navigation") || name.contains("arrow") || name.contains("chevron") {
                categories.insert("Navigation")
            } else if name.contains("media") || name.contains("play") || name.contains("pause") {
                categories.insert("Media Controls")
            } else if name.contains("communication") || name.contains("message") || name.contains("mail") {
                categories.insert("Communication")
            } else if name.contains("file") || name.contains("document") || name.contains("folder") {
                categories.insert("File Management")
            } else if name.contains("system") || name.contains("settings") || name.contains("gear") {
                categories.insert("System")
            }
        }
        
        // Add some intelligent default categories
        categories.insert("Actions")
        categories.insert("Status Indicators")
        categories.insert("Data Visualization")
        
        aiGeneratedCategories = Array(categories).sorted()
        
        // Update concepts with AI categories (simplified logic)
        updateConceptsWithAICategories()
    }
    
    private func updateConceptsWithAICategories() {
        symbolConcepts = symbolConcepts.map { concept in
            let name = concept.name.lowercased()
            guard !name.isEmpty else { return concept }
            
            var aiCategory: String?
            
            if name.contains("delete") || name.contains("trash") || name.contains("add") || name.contains("plus") {
                aiCategory = "Actions"
            } else if name.contains("settings") || name.contains("gear") {
                aiCategory = "System"
            } else if name.contains("user") || name.contains("person") {
                aiCategory = "User Management"
            } else if name.contains("message") || name.contains("mail") {
                aiCategory = "Communication"
            }
            
                    return SymbolConcept(
            name: concept.name,
            primarySymbol: concept.primarySymbol,
            variants: concept.variants,
            category: concept.category,
            aiCategory: aiCategory
        )
        }
    }
}

// MARK: - Quick Add Concept View (Streamlined HIG-Compliant)
struct QuickAddConceptView: View {
    @ObservedObject var iconStore: IconStore
    let onConceptCreated: (SymbolConcept) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var conceptName = ""
    @State private var selectedCategory: Category = .uiElements
    @State private var showingSymbolPicker = false
    @State private var selectedSymbol = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    Text("New Symbol Concept")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)
                
                // Input Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Concept Name")
                            .font(.headline)
                        
                        TextField("Enter concept name", text: $conceptName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !conceptName.isEmpty {
                                    createAndOpenConcept()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                Button("Create & Choose Symbol") {
                    createAndOpenConcept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(conceptName.isEmpty)
                .padding()
            }
            .navigationTitle("Add Symbol Concept")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func createAndOpenConcept() {
        let newConcept = SymbolConcept(
            name: conceptName,
            primarySymbol: "questionmark.square.dashed",
            category: selectedCategory
        )
        
        // Add to store (placeholder - will integrate with Core Data)
        iconStore.symbolConcepts.append(newConcept)
        
        // Notify parent and auto-open detail + symbol picker
        onConceptCreated(newConcept)
        
        // Auto-open symbol picker after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingSymbolPicker = true
        }
    }
}

// MARK: - Preview
#Preview {
    MainContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 