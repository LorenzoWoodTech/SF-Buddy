//
//  MainContentView.swift
//  SF Buddy
//
//  Platform-adaptive main content view using NavigationSplitView on larger screens
//  and NavigationStack on iPhone
//

import SwiftUI
import CoreData
import SFSafeSymbols

struct MainContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Simple UI state
    @State private var selectedIcon: Icon?
    @State private var searchText = ""
    @State private var selectedSidebarItem: SidebarItem?
    @State private var showingAddIconSheet = false
    @State private var showingPublishSheet = false
    
    // Create IconStore for managing icons
    @StateObject private var iconStore: IconStore
    
    init() {
        // Initialize IconStore with the view context
        // Note: This will be properly injected via environment in production
        self._iconStore = StateObject(wrappedValue: IconStore(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationSplitView {
            // Use the existing SidebarView
            SidebarView(
                iconStore: iconStore,
                selectedItem: $selectedSidebarItem
            )
        } content: {
            // Use the existing IconGridView with filtered icons
            IconGridView(
                icons: filteredIcons,
                selectedIcon: $selectedIcon,
                onAddIcon: { showingAddIconSheet = true },
                onPublish: { showingPublishSheet = true }
            )
        } detail: {
            // Inspector view for selected icon
            if let selectedIcon = selectedIcon {
                IconInspectorView(icon: selectedIcon)
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "sidebar.right",
                    description: Text("Select an icon to view details")
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search icons...")
        .sheet(isPresented: $showingAddIconSheet) {
            AddIconSheet(iconStore: iconStore)
        }
        .sheet(isPresented: $showingPublishSheet) {
            NavigationStack {
                VStack {
                    Text("Publish Registry")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Code generation and publishing features coming soon.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .navigationTitle("Publish")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingPublishSheet = false
                        }
                    }
                }
            }
        }
        .onAppear {
            // Set up the iconStore with the current view context
            iconStore.updateContext(viewContext)
        }
        .onChange(of: searchText) { _, newValue in
            iconStore.searchText = newValue
        }
    }
    
    /// Filter icons based on search text and selected sidebar item
    private var filteredIcons: [Icon] {
        var filtered = iconStore.icons
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { icon in
                icon.semanticName?.localizedCaseInsensitiveContains(searchText) == true ||
                icon.baseSymbol?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by selected sidebar item
        if let selectedSidebarItem = selectedSidebarItem {
            switch selectedSidebarItem {
            case .smartGroup(let group):
                filtered = filterBySmartGroup(filtered, group: group)
            case .tag(let tag):
                filtered = filtered.filter { icon in
                    icon.tags?.contains(tag) == true
                }
            }
        }
        
        return filtered
    }
    
    /// Filter icons by smart group criteria
    private func filterBySmartGroup(_ icons: [Icon], group: SmartGroup) -> [Icon] {
        switch group.type {
        case .all:
            return icons
        case .recent:
            // Return icons modified in the last 7 days
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return icons.filter { icon in
                icon.dateModified?.compare(weekAgo) == .orderedDescending
            }
        case .favorites:
            // TODO: Implement favorites system
            return icons
        case .custom:
            return icons.filter { $0.isCustomAsset }
        case .sfSymbols:
            return icons.filter { !$0.isCustomAsset }
        }
    }
}

// MARK: - Supporting Types

/// Represents different types of sidebar items
enum SidebarItem: Hashable {
    case smartGroup(SmartGroup)
    case tag(Tag)
}

/// Smart group definition
struct SmartGroup: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let systemImage: String
    let type: SmartGroupType
    let count: Int
    
    static func == (lhs: SmartGroup, rhs: SmartGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Types of smart groups
enum SmartGroupType {
    case all
    case recent
    case favorites
    case custom
    case sfSymbols
}

// MARK: - Icon Store

/// ObservableObject to manage icons and app state
class IconStore: ObservableObject {
    @Published var icons: [Icon] = []
    @Published var tags: [Tag] = []
    @Published var searchText = ""
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    /// Update the managed object context
    func updateContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    /// Fetch all data from Core Data
    private func fetchData() {
        fetchIcons()
        fetchTags()
    }
    
    /// Fetch icons from Core Data
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
    
    /// Fetch tags from Core Data
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
    
    /// Create a new tag
    func createTag(name: String, color: String) {
        let tag = Tag(context: viewContext)
        tag.name = name
        tag.color = color
        
        do {
            try viewContext.save()
            fetchTags()
        } catch {
            print("Error creating tag: \(error)")
        }
    }
    
    /// Delete a tag
    func deleteTag(_ tag: Tag) {
        viewContext.delete(tag)
        
        do {
            try viewContext.save()
            fetchTags()
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
    
    /// Smart groups computed property
    var smartGroups: [SmartGroup] {
        [
            SmartGroup(name: "All Icons", systemImage: "square.grid.3x3", type: .all, count: icons.count),
            SmartGroup(name: "Recent", systemImage: "clock", type: .recent, count: recentIconsCount),
            SmartGroup(name: "SF Symbols", systemImage: "app.badge", type: .sfSymbols, count: sfSymbolsCount),
            SmartGroup(name: "Custom Assets", systemImage: "photo.badge.plus", type: .custom, count: customAssetsCount)
        ]
    }
    
    private var recentIconsCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return icons.filter { icon in
            icon.dateModified?.compare(weekAgo) == .orderedDescending
        }.count
    }
    
    private var sfSymbolsCount: Int {
        icons.filter { !$0.isCustomAsset }.count
    }
    
    private var customAssetsCount: Int {
        icons.filter { $0.isCustomAsset }.count
    }
}

// MARK: - Inspector View

struct IconInspectorView: View {
    let icon: Icon
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Semantic Name", value: icon.semanticName ?? "Unknown")
                LabeledContent("Base Symbol", value: icon.baseSymbol ?? "Unknown")
                LabeledContent("Type", value: icon.isCustomAsset ? "Custom Asset" : "SF Symbol")
                
                if let dateCreated = icon.dateCreated {
                    LabeledContent("Created", value: dateCreated.formatted(date: .abbreviated, time: .shortened))
                }
                
                if let dateModified = icon.dateModified {
                    LabeledContent("Modified", value: dateModified.formatted(date: .abbreviated, time: .shortened))
                }
            }
            
            Section("Tags") {
                if let tags = icon.tags as? Set<Tag>, !tags.isEmpty {
                    ForEach(Array(tags), id: \.self) { tag in
                        Text(tag.name ?? "Unknown Tag")
                    }
                } else {
                    Text("No tags")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Variants") {
                if let variants = icon.variants as? Set<Variant>, !variants.isEmpty {
                    ForEach(Array(variants), id: \.self) { variant in
                        VStack(alignment: .leading) {
                            Text(variant.symbolName ?? "Unknown")
                                .font(.headline)
                            Text(variant.context ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No variants")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Inspector")
        #if os(macOS)
        .navigationSubtitle(icon.semanticName ?? "Unknown Icon")
        #endif
    }
}

// MARK: - Add Icon Sheet

struct AddIconSheet: View {
    let iconStore: IconStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    // Icon creation state
    @State private var selectedSymbol: String?
    @State private var semanticName: String = ""
    @State private var isCustomAsset: Bool = false
    @State private var selectedTags: Set<Tag> = []
    @State private var showingSymbolBrowser = false
    
    // Form validation
    private var canSave: Bool {
        !semanticName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSymbol != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Improved form sections with proper HIG spacing and layout
                Section {
                    // Semantic name input with proper label alignment
                    LabeledContent("Name") {
                        TextField("Enter semantic name (e.g., 'home', 'settings')", text: $semanticName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Symbol selection with better visual hierarchy
                    LabeledContent("Symbol") {
                        if let selectedSymbol = selectedSymbol {
                            // Show selected symbol with HIG-compliant design
                            HStack(spacing: 12) {
                                // Symbol preview
                                Image(systemName: selectedSymbol)
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                
                                // Symbol info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedSymbol)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("SF Symbol")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Change button with proper styling
                                Button("Change") {
                                    showingSymbolBrowser = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            // No symbol selected state
                            Button("Choose Symbol") {
                                showingSymbolBrowser = true
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Custom asset toggle with help text
                    Toggle("Custom Asset", isOn: $isCustomAsset)
                } header: {
                    Text("Icon Details")
                } footer: {
                    if isCustomAsset {
                        Text("This icon represents a custom asset from your app bundle rather than an SF Symbol.")
                    }
                }
                
                // Tags section with improved layout
                Section {
                    if iconStore.tags.isEmpty {
                        ContentUnavailableView(
                            "No Tags Available",
                            systemImage: "tag",
                            description: Text("Create tags in the sidebar to organize your icons.")
                        )
                        .frame(minHeight: 60)
                    } else {
                        // Tag selection with proper grid layout
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                            spacing: 8
                        ) {
                            ForEach(iconStore.tags, id: \.self) { tag in
                                TagSelectionButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    if !iconStore.tags.isEmpty {
                        Text("Select tags to help organize and categorize this icon.")
                    }
                }
                
                // Preview section with better visual design
                if let selectedSymbol = selectedSymbol {
                    Section {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                // Large icon preview
                                Image(systemName: selectedSymbol)
                                    .font(.system(size: 48))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.primary)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.accentColor.opacity(0.1))
                                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Preview labels
                                VStack(spacing: 4) {
                                    Text(semanticName.isEmpty ? "Icon Name" : semanticName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(selectedSymbol)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle("Add Icon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Icon") {
                        saveIcon()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingSymbolBrowser) {
            HiGCompliantSymbolPickerView(selectedSymbol: $selectedSymbol)
        }
        .onAppear {
            updateSemanticNameFromSymbol()
        }
        .onChange(of: selectedSymbol) { _, _ in
            updateSemanticNameFromSymbol()
        }
    }
    
    // MARK: - Methods
    
    private func saveIcon() {
        guard let selectedSymbol = selectedSymbol,
              !semanticName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let icon = Icon(context: viewContext)
        icon.semanticName = semanticName.trimmingCharacters(in: .whitespacesAndNewlines)
        icon.baseSymbol = selectedSymbol
        icon.isCustomAsset = isCustomAsset
        icon.dateCreated = Date()
        icon.dateModified = Date()
        
        // Add selected tags
        if !selectedTags.isEmpty {
            icon.tags = NSSet(set: selectedTags)
        }
        
        do {
            try viewContext.save()
            iconStore.updateContext(viewContext)
            dismiss()
        } catch {
            print("Error saving icon: \(error)")
            // TODO: Show error alert
        }
    }
    
    private func updateSemanticNameFromSymbol() {
        guard let selectedSymbol = selectedSymbol,
              semanticName.isEmpty else { return }
        
        let baseName = selectedSymbol.components(separatedBy: ".").first ?? selectedSymbol
        
        let mappings: [String: String] = [
            "house": "home",
            "gear": "settings",
            "magnifyingglass": "search",
            "plus": "add",
            "minus": "remove",
            "xmark": "close",
            "checkmark": "confirm",
            "trash": "delete",
            "pencil": "edit",
            "square.and.arrow.up": "share",
            "square.and.arrow.down": "download",
            "folder": "files",
            "doc": "document",
            "envelope": "mail",
            "phone": "call",
            "message": "chat"
        ]
        
        semanticName = mappings[baseName] ?? baseName
    }
}

// MARK: - HIG-Compliant Symbol Picker

struct HiGCompliantSymbolPickerView: View {
    @Binding var selectedSymbol: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var selectedCategory: SymbolCategory = .all
    @StateObject private var symbolProvider = SFSymbolProvider()
    
    // Organized symbol categories following HIG
    private let symbolCategories: [SymbolCategory] = [
        .all, .communication, .weather, .objects, .human, .nature, .symbols, .arrows, .math, .keyboard
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar with HIG-compliant styling
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search symbols", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColorForSearch)
                )
                
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(symbolCategories, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            Divider()
            
            // Symbol grid with proper spacing and HIG layout
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                    spacing: 16
                ) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        SymbolSelectionCell(
                            symbol: symbol,
                            isSelected: selectedSymbol == symbol
                        ) {
                            selectedSymbol = symbol
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Choose Symbol")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Select") {
                    dismiss()
                }
                .disabled(selectedSymbol == nil)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            symbolProvider.loadSymbols()
        }
    }
    
    var filteredSymbols: [String] {
        let categorySymbols = symbolProvider.symbols(for: selectedCategory)
        
        if searchText.isEmpty {
            return categorySymbols
        } else {
            return categorySymbols.filter { symbol in
                symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Platform-specific background colors
    private var backgroundColorForSearch: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.systemGray6)
        #endif
    }
}

// MARK: - Symbol Selection Cell

struct SymbolSelectionCell: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Symbol icon with proper sizing
                Image(systemName: symbol)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(width: 40, height: 40)
                
                // Symbol name with proper typography
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : backgroundColorForCell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColorForCell: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.systemGray6)
        #endif
    }
}

// MARK: - Tag Selection Button

struct TagSelectionButton: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Tag color indicator
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)
                
                Text(tag.name ?? "Unknown")
                    .font(.subheadline)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : backgroundColorForTag)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
    
    var tagColor: Color {
        guard let colorString = tag.color else { return .gray }
        
        switch colorString.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
    
    private var backgroundColorForTag: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.systemGray6)
        #endif
    }
}

// MARK: - SF Symbol Provider

class SFSymbolProvider: ObservableObject {
    @Published var availableSymbols: [String] = []
    @Published var isLoading = false
    
    private var symbolsByCategory: [SymbolCategory: [String]] = [:]
    
    /// Load all available SF Symbols using SFSafeSymbols complete catalog
    func loadSymbols() {
        guard availableSymbols.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let symbols = await loadAllSFSymbols()
            
            await MainActor.run {
                self.availableSymbols = symbols
                self.categorizeSymbols()
                self.isLoading = false
            }
        }
    }
    
    /// Get symbols for a specific category
    func symbols(for category: SymbolCategory) -> [String] {
        if category == .all {
            return availableSymbols
        }
        return symbolsByCategory[category] ?? []
    }
    
    /// Load all SF Symbols using SFSafeSymbols complete catalog
    private func loadAllSFSymbols() async -> [String] {
        // SFSafeSymbols already ensures compatibility with the current platform
        let allSFSymbols = SFSymbol.allCases.map { $0.rawValue }
        
        print("🎉 Loaded \(allSFSymbols.count) SF Symbols from SFSafeSymbols!")
        
        return allSFSymbols.sorted()
    }
    
    /// Check if a symbol is available by attempting to create a UIImage
    private func isSymbolAvailable(_ symbolName: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                #if os(macOS)
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
                continuation.resume(returning: image != nil)
                #else
                let image = UIImage(systemName: symbolName)
                continuation.resume(returning: image != nil)
                #endif
            }
        }
    }
    
    /// Categorize loaded symbols based on their names using SFSafeSymbols categories
    private func categorizeSymbols() {
        symbolsByCategory = [:]
        
        for symbol in availableSymbols {
            let categories = categoriesForSymbol(symbol)
            for category in categories {
                if symbolsByCategory[category] == nil {
                    symbolsByCategory[category] = []
                }
                symbolsByCategory[category]?.append(symbol)
            }
        }
        
        // Sort each category
        for key in symbolsByCategory.keys {
            symbolsByCategory[key]?.sort()
        }
    }
    
    /// Determine which categories a symbol belongs to based on SFSafeSymbols categories
    private func categoriesForSymbol(_ symbol: String) -> [SymbolCategory] {
        var categories: [SymbolCategory] = []
        let lowercased = symbol.lowercased()
        
        // Communication symbols - expanded patterns
        if lowercased.contains("phone") || lowercased.contains("envelope") || lowercased.contains("message") ||
           lowercased.contains("bubble") || lowercased.contains("video") || lowercased.contains("mic") ||
           lowercased.contains("wifi") || lowercased.contains("antenna") || lowercased.contains("airplay") ||
           lowercased.contains("bluetooth") || lowercased.contains("network") || lowercased.contains("signal") ||
           lowercased.contains("broadcast") || lowercased.contains("radiowaves") || lowercased.contains("mail") ||
           lowercased.contains("iphone") || lowercased.contains("ipad") || lowercased.contains("phone.connection") ||
           lowercased.contains("teletype") || lowercased.contains("fax") || lowercased.contains("voicemail") {
            categories.append(.communication)
        }
        
        // Weather symbols - expanded patterns
        if lowercased.contains("sun") || lowercased.contains("moon") || lowercased.contains("cloud") ||
           lowercased.contains("snow") || lowercased.contains("thermometer") || lowercased.contains("wind") ||
           lowercased.contains("rain") || lowercased.contains("storm") || lowercased.contains("tornado") ||
           lowercased.contains("hurricane") || lowercased.contains("humidity") || lowercased.contains("climate") ||
           lowercased.contains("weather") || lowercased.contains("temperature") || lowercased.contains("barometer") ||
           lowercased.contains("frost") || lowercased.contains("haze") || lowercased.contains("mist") {
            categories.append(.weather)
        }
        
        // Objects - greatly expanded patterns
        if lowercased.contains("house") || lowercased.contains("car") || lowercased.contains("trash") ||
           lowercased.contains("folder") || lowercased.contains("doc") || lowercased.contains("pencil") ||
           lowercased.contains("book") || lowercased.contains("bag") || lowercased.contains("box") ||
           lowercased.contains("package") || lowercased.contains("cart") || lowercased.contains("basket") ||
           lowercased.contains("suitcase") || lowercased.contains("briefcase") || lowercased.contains("backpack") ||
           lowercased.contains("cup") || lowercased.contains("mug") || lowercased.contains("bottle") ||
           lowercased.contains("fork") || lowercased.contains("knife") || lowercased.contains("spoon") ||
           lowercased.contains("plate") || lowercased.contains("bowl") || lowercased.contains("wineglass") ||
           lowercased.contains("bicycle") || lowercased.contains("airplane") || lowercased.contains("train") ||
           lowercased.contains("bus") || lowercased.contains("ferry") || lowercased.contains("sailboat") ||
           lowercased.contains("scooter") || lowercased.contains("motorcycle") || lowercased.contains("truck") ||
           lowercased.contains("scissors") || lowercased.contains("wrench") || lowercased.contains("hammer") ||
           lowercased.contains("screwdriver") || lowercased.contains("key") || lowercased.contains("lock") ||
           lowercased.contains("camera") || lowercased.contains("tv") || lowercased.contains("display") ||
           lowercased.contains("computer") || lowercased.contains("laptop") || lowercased.contains("keyboard") ||
           lowercased.contains("mouse") || lowercased.contains("printer") || lowercased.contains("scanner") ||
           lowercased.contains("phone") || lowercased.contains("watch") || lowercased.contains("clock") ||
           lowercased.contains("timer") || lowercased.contains("calendar") || lowercased.contains("bookmark") ||
           lowercased.contains("newspaper") || lowercased.contains("magazine") || lowercased.contains("journal") {
            categories.append(.objects)
        }
        
        // Human - expanded patterns
        if lowercased.contains("person") || lowercased.contains("figure") || lowercased.contains("eye") ||
           lowercased.contains("hand") || lowercased.contains("heart") || lowercased.contains("brain") ||
           lowercased.contains("ear") || lowercased.contains("nose") || lowercased.contains("mouth") ||
           lowercased.contains("foot") || lowercased.contains("lungs") || lowercased.contains("face") ||
           lowercased.contains("head") || lowercased.contains("body") || lowercased.contains("torso") ||
           lowercased.contains("arm") || lowercased.contains("leg") || lowercased.contains("finger") ||
           lowercased.contains("thumb") || lowercased.contains("wrist") || lowercased.contains("shoulder") ||
           lowercased.contains("medical") || lowercased.contains("health") || lowercased.contains("bandage") ||
           lowercased.contains("pills") || lowercased.contains("syringe") || lowercased.contains("stethoscope") ||
           lowercased.contains("cross") || lowercased.contains("medical.thermometer") {
            categories.append(.human)
        }
        
        // Nature - expanded patterns
        if lowercased.contains("leaf") || lowercased.contains("tree") || lowercased.contains("flame") ||
           lowercased.contains("drop") || lowercased.contains("star") || lowercased.contains("mountain") ||
           lowercased.contains("globe") || lowercased.contains("rainbow") || lowercased.contains("flower") ||
           lowercased.contains("plant") || lowercased.contains("forest") || lowercased.contains("water") ||
           lowercased.contains("ocean") || lowercased.contains("river") || lowercased.contains("lake") ||
           lowercased.contains("beach") || lowercased.contains("desert") || lowercased.contains("volcano") ||
           lowercased.contains("earth") || lowercased.contains("nature") || lowercased.contains("environment") ||
           lowercased.contains("park") || lowercased.contains("garden") || lowercased.contains("seed") ||
           lowercased.contains("branch") || lowercased.contains("root") || lowercased.contains("grass") ||
           lowercased.contains("rock") || lowercased.contains("stone") || lowercased.contains("crystal") {
            categories.append(.nature)
        }
        
        // Symbols - expanded patterns
        if lowercased.contains("plus") || lowercased.contains("minus") || lowercased.contains("checkmark") ||
           lowercased.contains("xmark") || lowercased.contains("asterisk") || lowercased.contains("at") ||
           lowercased.contains("hashtag") || lowercased.contains("number") || lowercased.contains("percent") ||
           lowercased.contains("dollar") || lowercased.contains("euro") || lowercased.contains("yen") ||
           lowercased.contains("pound") || lowercased.contains("exclamationmark") || lowercased.contains("questionmark") ||
           lowercased.contains("ellipsis") || lowercased.contains("period") || lowercased.contains("comma") ||
           lowercased.contains("quote") || lowercased.contains("apostrophe") || lowercased.contains("slash") ||
           lowercased.contains("backslash") || lowercased.contains("parenthesis") || lowercased.contains("bracket") ||
           lowercased.contains("brace") || lowercased.contains("flag") || lowercased.contains("tag") ||
           lowercased.contains("bookmark") || lowercased.contains("diamond") || lowercased.contains("circle") ||
           lowercased.contains("square") || lowercased.contains("triangle") || lowercased.contains("hexagon") ||
           lowercased.contains("octagon") || lowercased.contains("oval") || lowercased.contains("rectangle") {
            categories.append(.symbols)
        }
        
        // Arrows - expanded patterns
        if lowercased.contains("arrow") || lowercased.contains("chevron") || lowercased.contains("triangle") &&
           (lowercased.contains("up") || lowercased.contains("down") || lowercased.contains("left") || lowercased.contains("right")) ||
           lowercased.contains("direction") || lowercased.contains("forward") || lowercased.contains("backward") ||
           lowercased.contains("return") || lowercased.contains("reply") || lowercased.contains("share") ||
           lowercased.contains("export") || lowercased.contains("import") || lowercased.contains("download") ||
           lowercased.contains("upload") || lowercased.contains("refresh") || lowercased.contains("reload") ||
           lowercased.contains("rotate") || lowercased.contains("flip") || lowercased.contains("sort") ||
           lowercased.contains("move") || lowercased.contains("drag") || lowercased.contains("shuffle") {
            categories.append(.arrows)
        }
        
        // Math - expanded patterns
        if lowercased.contains("function") || lowercased.contains("sum") || lowercased.contains("infinity") ||
           lowercased.contains("pi") || lowercased.contains("equal") || lowercased.contains("percent") ||
           lowercased.contains("multiply") || lowercased.contains("divide") || lowercased.contains("plus") ||
           lowercased.contains("minus") || lowercased.contains("plusminus") || lowercased.contains("squareroot") ||
           lowercased.contains("power") || lowercased.contains("superscript") || lowercased.contains("subscript") ||
           lowercased.contains("fraction") || lowercased.contains("radical") || lowercased.contains("angle") ||
           lowercased.contains("calculator") || lowercased.contains("graph") || lowercased.contains("chart") ||
           lowercased.contains("statistics") || lowercased.contains("number") || lowercased.contains("digit") ||
           lowercased.contains("mathematical") || lowercased.contains("algebra") || lowercased.contains("geometry") {
            categories.append(.math)
        }
        
        // Keyboard - expanded patterns
        if lowercased.contains("keyboard") || lowercased.contains("return") || lowercased.contains("delete") ||
           lowercased.contains("shift") || lowercased.contains("command") || lowercased.contains("option") ||
           lowercased.contains("control") || lowercased.contains("capslock") || lowercased.contains("tab") ||
           lowercased.contains("escape") || lowercased.contains("space") || lowercased.contains("backspace") ||
           lowercased.contains("enter") || lowercased.contains("clear") || lowercased.contains("eject") ||
           lowercased.contains("power") || lowercased.contains("sleep") || lowercased.contains("wake") ||
           lowercased.contains("volume") || lowercased.contains("brightness") || lowercased.contains("key") {
            categories.append(.keyboard)
        }
        
        return categories
    }
}

// MARK: - Symbol Categories

enum SymbolCategory: CaseIterable {
    case all, communication, weather, objects, human, nature, symbols, arrows, math, keyboard
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .communication: return "Communication"
        case .weather: return "Weather"
        case .objects: return "Objects"
        case .human: return "Human"
        case .nature: return "Nature"
        case .symbols: return "Symbols"
        case .arrows: return "Arrows"
        case .math: return "Math"
        case .keyboard: return "Keyboard"
        }
    }
}

#Preview {
    MainContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
