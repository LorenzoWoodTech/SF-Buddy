//
//  MainContentView.swift
//  SF Buddy
//
//  Three-column layout with actual functional views
//

import SwiftUI
import CoreData

enum MainSidebarItem: String, CaseIterable {
    case search = "Search"
    case registry = "Registry"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .search: return "magnifyingglass"
        case .registry: return "cylinder.split.1x2"
        case .settings: return "gear"
        }
    }
}

struct MainContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var iconStore = IconStore(context: PersistenceController.shared.container.viewContext)
    
    @State private var selectedSidebarItem: MainSidebarItem? = .search
    @State private var selectedIcon: Icon?
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with actual functional sections
            List(selection: $selectedSidebarItem) {
                Section("SF Buddy") {
                    ForEach(MainSidebarItem.allCases, id: \.self) { item in
                        Label(item.rawValue, systemImage: item.systemImage)
                            .tag(item)
                    }
                }
                
                if !symbolService.suggestedSymbols.isEmpty {
                    Section("Recent Searches") {
                        if !symbolService.lastProcessedText.isEmpty {
                            Label(symbolService.lastProcessedText, systemImage: "clock")
                        }
                    }
                }
            }
            .navigationTitle("SF Buddy")
        } content: {
            // Content area shows different views based on sidebar selection
            Group {
                switch selectedSidebarItem {
                case .search:
                    SearchContentView()
                case .registry:
                    IconRegistryContentView(selectedIcon: $selectedIcon)
                case .settings:
                    SettingsContentView()
                case .none:
                    SearchContentView()
                }
            }
        } detail: {
            // Detail area shows symbol picker or icon details
            Group {
                if selectedSidebarItem == .search {
                    if !symbolService.suggestedSymbols.isEmpty || !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                        SymbolPickerView()
                            .navigationTitle("Symbol Results")
                    } else {
                        SearchPlaceholderView()
                    }
                } else if selectedSidebarItem == .registry, let selectedIcon = selectedIcon {
                    IconDetailForm(icon: selectedIcon, iconStore: iconStore)
                } else {
                    DefaultDetailView(selectedSidebarItem: selectedSidebarItem)
                }
            }
        }
        .onAppear {
            iconStore.updateContext(viewContext)
            if selectedSidebarItem == nil {
                selectedSidebarItem = .search
            }
        }
    }
}

// MARK: - Content Views

struct SearchContentView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                Text("Symbol Search")
                    .font(.headline)
            }
            .padding(.top)

            // API Key section
            if symbolService.claudeAPIKey.isEmpty && !symbolService.isProcessing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude API Key Required:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        SecureField("Enter your Anthropic API Key...", text: $symbolService.claudeAPIKey)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    Link("Get an API Key from Anthropic", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                        .font(.caption)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !searchText.isEmpty {
                            Task {
                                await symbolService.searchSymbols(for: searchText)
                            }
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            // Status area
            Group {
                if symbolService.isProcessing {
                    ProcessingView()
                } else if symbolService.apiKeyMissingOrInvalid && !symbolService.claudeAPIKey.isEmpty {
                    APIKeyErrorView(lastProcessedText: symbolService.lastProcessedText)
                } else if symbolService.claudeAPIKey.isEmpty {
                    APIKeyNeededView()
                } else {
                    ReadyView()
                }
            }

            Spacer()
        }
        .navigationTitle("Search")
    }
}

struct IconRegistryContentView: View {
    @Binding var selectedIcon: Icon?
    @StateObject private var iconStore = IconStore(context: PersistenceController.shared.container.viewContext)
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            if iconStore.icons.isEmpty {
                IconRegistryPreview()
            } else {
                List(iconStore.icons, id: \.self, selection: $selectedIcon) { icon in
                    VStack(alignment: .leading) {
                        Text(icon.semanticName ?? "Unknown")
                            .font(.headline)
                        Text(icon.baseSymbol ?? "No symbol")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Registry")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Create new icon and select it
                    let newIcon = Icon(context: viewContext)
                    newIcon.semanticName = ""
                    newIcon.baseSymbol = ""
                    newIcon.dateCreated = Date()
                    selectedIcon = newIcon
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            iconStore.updateContext(viewContext)
        }
    }
}

struct SettingsContentView: View {
    var body: some View {
        SettingsView()
    }
}

// MARK: - Detail Views

struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Search for Symbols")
                .font(.title2)
            Text("Enter a search term to find SF Symbols using AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Symbol Search")
    }
}

struct DefaultDetailView: View {
    let selectedSidebarItem: MainSidebarItem?
    
    var body: some View {
        VStack(spacing: 12) {
            if let item = selectedSidebarItem {
                Image(systemName: item.systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text(item.rawValue)
                    .font(.title2)
                Text("Select an item to view details")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("Select a category")
                    .font(.title2)
            }
        }
        .padding()
    }
}

// MARK: - Status Views

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3 + Double(index) * 0.5) * 0.3)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                }
            }
            
            Text("Finding magical symbols...")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(0.7 + sin(Date().timeIntervalSince1970 * 2) * 0.3)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
        }
        .padding()
    }
}

struct APIKeyErrorView: View {
    let lastProcessedText: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text("Claude API Key Invalid or Issue")
                .font(.headline)
            Text("There was an issue with your API key or the service. Please check your key and internet connection.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if !lastProcessedText.isEmpty {
                Text("Tried for: \"\(lastProcessedText)\"")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

struct APIKeyNeededView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.slash.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text("API Key Needed")
                .font(.headline)
            Text("Please enter your Anthropic API key above to start finding symbols.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ReadyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
            Text("Ready to Find Symbols")
                .font(.headline)
            Text("Enter text in the search bar above, or press ⌃⌥⌘Space to find symbols for selected text in other apps.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct IconDetailForm: View {
    let icon: Icon
    let iconStore: IconStore
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingPicker = false
    
    var body: some View {
        Form {
            TextField("Name", text: Binding(
                get: { icon.semanticName ?? "" },
                set: { 
                    icon.semanticName = $0.isEmpty ? nil : $0
                    icon.dateModified = Date()
                    try? viewContext.save()
                    iconStore.updateContext(viewContext)
                }
            ))
            
            HStack {
                TextField("Symbol", text: Binding(
                    get: { icon.baseSymbol ?? "" },
                    set: { 
                        icon.baseSymbol = $0.isEmpty ? nil : $0
                        icon.dateModified = Date()
                        try? viewContext.save()
                        iconStore.updateContext(viewContext)
                    }
                ))
                
                Button("Pick") {
                    showingPicker = true
                }
            }
        }
        .navigationTitle("Icon")
        .sheet(isPresented: $showingPicker) {
            SFSymbolBrowserView(selectedSymbol: Binding(
                get: { icon.baseSymbol },
                set: { 
                    icon.baseSymbol = $0
                    icon.dateModified = Date()
                    try? viewContext.save()
                    iconStore.updateContext(viewContext)
                }
            ))
        }
    }
}

// MARK: - Icon Store

/// Simple IconStore
class IconStore: ObservableObject {
    @Published var icons: [Icon] = []
    @Published var searchText = ""
    @Published var displayPreference: DisplayPreference = .default
    
    // Add symbolConcepts for compatibility with ContentListView and DetailView
    @Published var symbolConcepts: [SymbolConcept] = []
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchIcons()
        loadSymbolConcepts()
    }
    
    func updateContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        fetchIcons()
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
    
    private func loadSymbolConcepts() {
        // Load the same symbol concepts as ModernIconStore
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
}

#Preview {
    MainContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}