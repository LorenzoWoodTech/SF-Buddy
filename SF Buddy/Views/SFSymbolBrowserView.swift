//
//  SFSymbolBrowserView.swift
//  SF Buddy
//
//  Comprehensive SF Symbol browser combining systematic browsing with AI-powered search
//  Following Human Interface Guidelines for optimal user experience
//

import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct SFSymbolBrowserView: View {
    @Binding var selectedSymbol: String?
    @Environment(\.dismiss) private var dismiss
    
    // Integration with existing AI functionality
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var appSettings = AppSettings.shared
    
    // Browser state
    @State private var searchText = ""
    @State private var selectedCategory: SFSymbolCategory = .all
    @State private var showingAISearch = false
    @State private var aiSearchText = ""
    @State private var gridSize: GridSize = .medium
    @State private var showingCategoryPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top toolbar with search modes and controls
                topToolbar
                
                Divider()
                
                // Category picker (collapsible)
                if showingCategoryPicker {
                    categoryPicker
                    Divider()
                }
                
                // Main content area
                Group {
                    if showingAISearch && !symbolService.suggestedSymbols.isEmpty {
                        // AI-powered symbol suggestions
                        aiSuggestionsView
                    } else {
                        // Systematic symbol browsing
                        systematicBrowsingView
                    }
                }
            }
            .navigationTitle("SF Symbols")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search symbols...")
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
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, idealWidth: 800, maxWidth: 900,
               minHeight: 600, idealHeight: 700, maxHeight: 800)
        #endif
        .onChange(of: searchText) { _, newValue in
            // Auto-switch to AI search for natural language queries
            updateSearchMode(for: newValue)
        }
    }
    
    // MARK: - Top Toolbar
    
    @ViewBuilder
    private var topToolbar: some View {
        HStack(spacing: 12) {
            // Search mode toggle
            HStack(spacing: 8) {
                Button(action: { showingAISearch.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingAISearch ? "brain.head.profile" : "magnifyingglass")
                            .font(.caption)
                        Text(showingAISearch ? "AI Search" : "Browse")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(showingAISearch ? Color.blue.opacity(0.2) : backgroundColorForPlatform)
                    .foregroundColor(showingAISearch ? .blue : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Toggle between AI-powered search and systematic browsing")
            }
            
            Spacer()
            
            // Category toggle
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingCategoryPicker.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: selectedCategory.systemImage)
                        .font(.caption)
                    Text(selectedCategory.displayName)
                        .font(.caption)
                    Image(systemName: showingCategoryPicker ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColorForPlatform)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            // Grid size control
            Menu {
                ForEach(GridSize.allCases) { size in
                    Button(action: { gridSize = size }) {
                        HStack {
                            Image(systemName: size.iconName)
                            Text(size.displayName)
                            if gridSize == size {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: gridSize.iconName)
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColorForPlatform)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Adjust grid size")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Category Picker
    
    @ViewBuilder
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SFSymbolCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - AI Suggestions View
    
    @ViewBuilder
    private var aiSuggestionsView: some View {
        VStack(spacing: 16) {
            // AI search input
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                TextField("Describe what you're looking for...", text: $aiSearchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        performAISearch()
                    }
                
                Button("Search", action: performAISearch)
                    .disabled(aiSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            
            // AI suggestions grid
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize.columnCount),
                    spacing: 12
                ) {
                    ForEach(symbolService.suggestedSymbols) { suggestion in
                        SFSymbolCell(
                            symbolName: suggestion.name,
                            isSelected: selectedSymbol == suggestion.name,
                            gridSize: gridSize,
                            showAIBadge: true
                        ) {
                            selectedSymbol = suggestion.name
                        }
                    }
                }
                .padding()
            }
            
            // Invalid symbols notice
            if !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Some suggested symbols were invalid:")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Text(symbolService.invalidSymbolNamesFromClaude.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Systematic Browsing View
    
    @ViewBuilder
    private var systematicBrowsingView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize.columnCount),
                spacing: 12
            ) {
                ForEach(filteredSymbols, id: \.self) { symbolName in
                    SFSymbolCell(
                        symbolName: symbolName,
                        isSelected: selectedSymbol == symbolName,
                        gridSize: gridSize
                    ) {
                        selectedSymbol = symbolName
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Symbols filtered by category and search text
    private var filteredSymbols: [String] {
        let categorySymbols = selectedCategory == .all ? SFSymbolRegistry.allSymbols : SFSymbolRegistry.symbolsByCategory[selectedCategory] ?? []
        
        if searchText.isEmpty {
            return categorySymbols
        } else {
            return categorySymbols.filter { symbol in
                symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Platform-appropriate background color
    private var backgroundColorForPlatform: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.secondarySystemGroupedBackground)
        #endif
    }
    
    // MARK: - Methods
    
    /// Determine if search text looks like natural language (for AI search)
    private func updateSearchMode(for searchText: String) {
        let isNaturalLanguage = searchText.contains(" ") || 
                               searchText.count > 15 ||
                               searchText.localizedCaseInsensitiveContains("icon") ||
                               searchText.localizedCaseInsensitiveContains("symbol")
        
        if isNaturalLanguage && !showingAISearch {
            showingAISearch = true
            aiSearchText = searchText
        }
    }
    
    /// Perform AI-powered symbol search
    private func performAISearch() {
        guard !aiSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            // Use existing AI functionality
            await symbolService.processText(aiSearchText)
        }
    }
}

// MARK: - SF Symbol Cell

struct SFSymbolCell: View {
    let symbolName: String
    let isSelected: Bool
    let gridSize: GridSize
    var showAIBadge: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Symbol display
                    Group {
                        if symbolExists {
                            Image(systemName: symbolName)
                                .font(.system(size: gridSize.symbolSize))
                                .symbolRenderingMode(.hierarchical)
                        } else {
                            Image(systemName: "questionmark.square.dashed")
                                .font(.system(size: gridSize.symbolSize))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: gridSize.symbolSize + 12, height: gridSize.symbolSize + 12)
                    .foregroundStyle(isSelected ? .white : (isHovered ? .primary : .primary))
                    
                    // AI badge
                    if showAIBadge {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "brain.head.profile")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(2)
                                    .background(Circle().fill(.blue.opacity(0.2)))
                            }
                            Spacer()
                        }
                    }
                }
                
                // Symbol name (if showing names)
                if gridSize.showNames {
                    Text(symbolName)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: gridSize.buttonSize.min,
            maxWidth: gridSize.buttonSize.max,
            minHeight: gridSize.buttonSize.height,
            maxHeight: gridSize.buttonSize.height
        )
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : (isHovered ? backgroundColorForPlatform : Color.clear))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(symbolName)
    }
    
    /// Check if the symbol actually exists in SF Symbols
    private var symbolExists: Bool {
        #if os(macOS)
        return !symbolName.isEmpty && NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil
        #else
        return !symbolName.isEmpty && UIImage(systemName: symbolName) != nil
        #endif
    }
    
    /// Platform-appropriate background color
    private var backgroundColorForPlatform: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.secondarySystemGroupedBackground)
        #endif
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: SFSymbolCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor : backgroundColorForPlatform,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    /// Platform-appropriate background color
    private var backgroundColorForPlatform: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.secondarySystemGroupedBackground)
        #endif
    }
}

// MARK: - SF Symbol Categories

enum SFSymbolCategory: String, CaseIterable {
    case all = "All"
    case communication = "Communication"
    case weather = "Weather"
    case objectsTools = "Objects & Tools"
    case devices = "Devices"
    case gaming = "Gaming"
    case connectivity = "Connectivity"
    case transportation = "Transportation"
    case automotive = "Automotive"
    case accessibility = "Accessibility"
    case privacy = "Privacy & Security"
    case human = "Human"
    case home = "Home"
    case fitness = "Fitness"
    case nature = "Nature"
    case editing = "Editing"
    case textFormatting = "Text Formatting"
    case media = "Media"
    case keyboard = "Keyboard"
    case commerce = "Commerce"
    case time = "Time"
    case health = "Health"
    case shapes = "Shapes"
    case arrows = "Arrows"
    case indices = "Indices"
    case math = "Math"
    
    var displayName: String {
        rawValue
    }
    
    var systemImage: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .communication: return "bubble.left.and.bubble.right"
        case .weather: return "cloud.sun"
        case .objectsTools: return "wrench.and.screwdriver"
        case .devices: return "laptopcomputer"
        case .gaming: return "gamecontroller"
        case .connectivity: return "wifi"
        case .transportation: return "car"
        case .automotive: return "car.front.waves.up"
        case .accessibility: return "accessibility"
        case .privacy: return "lock.shield"
        case .human: return "person"
        case .home: return "house"
        case .fitness: return "figure.run"
        case .nature: return "leaf"
        case .editing: return "pencil"
        case .textFormatting: return "textformat"
        case .media: return "play.rectangle"
        case .keyboard: return "keyboard"
        case .commerce: return "cart"
        case .time: return "clock"
        case .health: return "heart"
        case .shapes: return "circle.square"
        case .arrows: return "arrow.right"
        case .indices: return "a.circle"
        case .math: return "plus.forwardslash.minus"
        }
    }
}

// MARK: - SF Symbol Registry

/// Registry of SF Symbols organized by category
/// In a production app, this would be generated from the actual SF Symbols catalog
enum SFSymbolRegistry {
    static let symbolsByCategory: [SFSymbolCategory: [String]] = [
        .communication: [
            "phone", "phone.fill", "phone.circle", "phone.circle.fill",
            "envelope", "envelope.fill", "envelope.circle", "envelope.circle.fill",
            "message", "message.fill", "message.circle", "message.circle.fill",
            "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
            "text.bubble", "text.bubble.fill", "quote.bubble", "quote.bubble.fill"
        ],
        .weather: [
            "sun.max", "sun.max.fill", "sun.min", "sun.min.fill",
            "moon", "moon.fill", "moon.stars", "moon.stars.fill",
            "cloud", "cloud.fill", "cloud.rain", "cloud.rain.fill",
            "cloud.snow", "cloud.snow.fill", "cloud.bolt", "cloud.bolt.fill"
        ],
        .objectsTools: [
            "hammer", "hammer.fill", "wrench", "wrench.fill",
            "screwdriver", "screwdriver.fill", "scissors", "scissors.circle",
            "paperclip", "paperclip.circle", "link", "link.circle",
            "key", "key.fill", "lock", "lock.fill"
        ],
        .devices: [
            "iphone", "ipad", "laptopcomputer", "desktopcomputer",
            "applewatch", "tv", "homepod", "airpods",
            "keyboard", "mouse", "trackpad", "display"
        ],
        .transportation: [
            "car", "car.fill", "car.circle", "car.circle.fill",
            "bus", "bus.fill", "airplane", "airplane.circle",
            "bicycle", "bicycle.circle", "train.side.front.car", "ferry"
        ],
        .home: [
            "house", "house.fill", "house.circle", "house.circle.fill",
            "building", "building.fill", "building.2", "building.2.fill",
            "door.left.hand.closed", "door.right.hand.closed", "window.ceiling",
            "bed.double", "sofa", "chair", "table.furniture"
        ],
        .nature: [
            "leaf", "leaf.fill", "tree", "tree.fill",
            "flower", "flame", "flame.fill", "drop", "drop.fill",
            "snowflake", "sun.max", "moon", "star", "star.fill"
        ],
        .shapes: [
            "circle", "circle.fill", "square", "square.fill",
            "triangle", "triangle.fill", "diamond", "diamond.fill",
            "hexagon", "hexagon.fill", "octagon", "octagon.fill",
            "oval", "oval.fill", "capsule", "capsule.fill"
        ],
        .arrows: [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.up.circle", "arrow.down.circle", "arrow.left.circle", "arrow.right.circle",
            "chevron.up", "chevron.down", "chevron.left", "chevron.right",
            "arrow.clockwise", "arrow.counterclockwise"
        ]
    ]
    
    static let allSymbols: [String] = {
        symbolsByCategory.values.flatMap { $0 }.sorted()
    }()
}

#Preview {
    SFSymbolBrowserView(selectedSymbol: .constant(nil))
        .environmentObject(SFSymbolService.shared)
        .environmentObject(AppSettings.shared)
}
