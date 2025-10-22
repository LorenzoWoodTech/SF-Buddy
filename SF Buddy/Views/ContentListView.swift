////
////  ContentListView.swift
////  SF Buddy
////
////  HIG-compliant content filtering with unified symbol display system
////
//
//import SwiftUI
//import CoreData
//
//// MARK: - Symbol Types (Not Categories!)
//enum SymbolType: String, CaseIterable {
//    case all = "All"
//    case entities = "Entities"
//    case uiElements = "UI Elements" 
//    case system = "System"
//    
//    var description: String {
//        switch self {
//        case .all:
//            return "All symbol concepts"
//        case .entities:
//            return "Things and objects in your app"
//        case .uiElements:
//            return "Interface components and actions"
//        case .system:
//            return "App states and system functions"
//        }
//    }
//}
//
//// MARK: - Content List View with Unified Display System
//struct ContentListView: View {
//    let selectedSidebarItem: SidebarItem?
//    @Binding var selectedSymbolConcept: SymbolConcept?
//    @Binding var selectedIcon: Icon?
//    @ObservedObject var iconStore: IconStore
//    @Binding var showingSymbolPicker: Bool
//    @Binding var showingAddConceptSheet: Bool
//    
//    // Unified display controls (same as symbol picker)
//    @State private var selectedRenderingMode: BrowserRenderingMode = .hierarchical
//    @State private var gridSize: BrowserGridSize = .medium
//    @State private var selectedColor: Color = .primary
//    @State private var vegasMode = false
//    @State private var showingStylePopover = false
//    @State private var showingColorPopover = false
//    @State private var showingGridSizePopover = false
//    
//    // Filtering state - now uses actual categories
//    @State private var selectedCategory: String? = nil // Now actual category names
//    @State private var showingCategoryManager = false
//    
//    var body: some View {
//        Group {
//            switch selectedSidebarItem {
//            case .sfSymbols:
//                VStack(spacing: 0) {
//                    // MARK: - Unified Control Bar (same as symbol picker)
//                    controlBar
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 12)
//                    
//                    Divider()
//                    
//                    // MARK: - Header with Categories
//                    HeaderView(
//                        filteredCount: filteredConcepts.count,
//                        selectedCategory: $selectedCategory,
//                        availableCategories: availableCategories
//                    )
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 16)
//                    
//                    Divider()
//                    
//                    // MARK: - Content
//                    if filteredConcepts.isEmpty {
//                        ContentUnavailableView(
//                            selectedCategory == nil ? "No Symbol Concepts" : "No Concepts in Category",
//                            systemImage: "square.3.layers.3d.middle.filled",
//                            description: Text(selectedCategory == nil ? "Create your first symbol concept to get started" : "No concepts found in '\(selectedCategory ?? "")'")
//                        )
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    } else {
//                        ScrollView {
//                            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
//                                ForEach(groupedConcepts.keys.sorted(), id: \.self) { categoryName in
//                                    Section {
//                                        UnifiedConceptGrid(
//                                            concepts: groupedConcepts[categoryName] ?? [],
//                                            selectedConcept: $selectedSymbolConcept,
//                                            gridSize: gridSize,
//                                            renderingMode: selectedRenderingMode,
//                                            symbolColor: selectedColor,
//                                            vegasMode: vegasMode,
//                                            showConceptColors: iconStore.displayPreference == .default
//                                        )
//                                    } header: {
//                                        CategoryHeader(title: categoryName)
//                                    }
//                                }
//                            }
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 16)
//                        }
//                    }
//                }
//                .toolbar {
//                    ToolbarItemGroup(placement: .primaryAction) {
//                        // Category management
//                        Button("Categories", systemImage: "folder.badge.gearshape") {
//                            showingCategoryManager = true
//                        }
//                        .help("Manage Categories")
//                        
//                        // Add concept
//                        Button("Add", systemImage: "plus") {
//                            showingAddConceptSheet = true
//                        }
//                        .help("Add a new symbol concept (⌘N)")
//                        .keyboardShortcut("n", modifiers: .command)
//                    }
//                }
//                .sheet(isPresented: $showingCategoryManager) {
//                    CategoryManagerSheet(iconStore: iconStore)
//                }
//                
//            case .all, .recent:
//                ContentUnavailableView(
//                    "Feature Coming Soon",
//                    systemImage: "hammer.fill",
//                    description: Text("This section is under development")
//                )
//                
//            case .none:
//                ContentUnavailableView(
//                    "Select a Category",
//                    systemImage: "sidebar.left",
//                    description: Text("Choose a category from the sidebar to get started")
//                )
//            }
//        }
//    }
//    
//    // MARK: - Unified Control Bar (matches symbol picker)
//    private var controlBar: some View {
//        HStack(spacing: 12) {
//            Spacer()
//            
//            // Grid Size Control
//            Button {
//                showingGridSizePopover.toggle()
//            } label: {
//                HStack(spacing: 6) {
//                    Image(systemName: gridSize.iconName)
//                        .font(.caption)
//                    Text("Grid")
//                        .font(.caption)
//                    Image(systemName: "chevron.down")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 10)
//                .padding(.vertical, 5)
//                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
//            }
//            .buttonStyle(.borderless)
//            // .popover(isPresented: $showingGridSizePopover) {
//            //     // Placeholder for grid size popover
//            //     VStack {
//            //         Text("Grid Size Options")
//            //         Button("Small") { gridSize = .small }
//            //         Button("Medium") { gridSize = .medium }  
//            //         Button("Large") { gridSize = .large }
//            //     }
//            //     .padding()
//            // }
//            
//            // Rendering Mode Control
//            Button {
//                showingStylePopover.toggle()
//            } label: {
//                HStack(spacing: 6) {
//                    Image(systemName: selectedRenderingMode.iconName)
//                        .font(.caption)
//                    Text("Render")
//                        .font(.caption)
//                    Image(systemName: "chevron.down")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 10)
//                .padding(.vertical, 5)
//                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
//            }
//            .buttonStyle(.borderless)
//            // .popover(isPresented: $showingStylePopover) {
//            //     VStack {
//            //         Text("Rendering Mode")
//            //         Button("Hierarchical") { selectedRenderingMode = .hierarchical }
//            //         Button("Monochrome") { selectedRenderingMode = .monochrome }
//            //         Button("Multicolor") { selectedRenderingMode = .multicolor }
//            //         Button("Palette") { selectedRenderingMode = .palette }
//            //     }
//            //     .padding()
//            // }
//            
//            // Color Control
//            Button {
//                showingColorPopover.toggle()
//            } label: {
//                HStack(spacing: 6) {
//                    Circle()
//                        .fill(selectedColor)
//                        .frame(width: 14, height: 14)
//                        .overlay(
//                            Circle()
//                                .strokeBorder(.primary.opacity(0.3), lineWidth: 0.5)
//                        )
//                    Text("Colors")
//                        .font(.caption)
//                    Image(systemName: "chevron.down")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 10)
//                .padding(.vertical, 5)
//                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
//            }
//            .buttonStyle(.borderless)
//            // .popover(isPresented: $showingColorPopover) {
//            //     VStack {
//            //         Text("Symbol Color")
//            //         Button("Primary") { selectedColor = .primary }
//            //         Button("Blue") { selectedColor = .blue }
//            //         Button("Green") { selectedColor = .green }
//            //         Button("Red") { selectedColor = .red }
//            //     }
//            //     .padding()
//            // }
//            
//            // Vegas Mode Control
//            Button {
//                withAnimation(.bouncy) {
//                    vegasMode.toggle()
//                }
//            } label: {
//                Image(systemName: vegasMode ? "sparkles" : "sparkles")
//                    .font(.caption)
//                    .foregroundColor(vegasMode ? .yellow : .secondary)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 5)
//                    .background(vegasMode ? Color.yellow.opacity(0.2) : Color.clear,
//                               in: RoundedRectangle(cornerRadius: 6))
//            }
//            .buttonStyle(.borderless)
//            
//            Spacer()
//        }
//    }
//    
//    // MARK: - Computed Properties
//    
//    private var filteredConcepts: [SymbolConcept] {
//        var concepts = iconStore.symbolConcepts
//        
//        // Filter by selected category
//        if let selectedCategory = selectedCategory {
//            concepts = concepts.filter { concept in
//                getConceptCategory(concept) == selectedCategory
//            }
//        }
//        
//        return concepts
//    }
//    
//    private var availableCategories: [String] {
//        // Get actual categories from concepts
//        let categories = Set(iconStore.symbolConcepts.map { getConceptCategory($0) })
//        return Array(categories).sorted()
//    }
//    
//    private var groupedConcepts: [String: [SymbolConcept]] {
//        Dictionary(grouping: filteredConcepts) { concept in
//            getConceptCategory(concept)
//        }
//    }
//    
//    private func getConceptCategory(_ concept: SymbolConcept) -> String {
//        // For now, use the concept's category. In the future, this could use AI-generated categories
//        return concept.category.rawValue
//    }
//}
//
//// MARK: - Unified Concept Grid with Same Style as Symbol Picker
//struct UnifiedConceptGrid: View {
//    let concepts: [SymbolConcept]
//    @Binding var selectedConcept: SymbolConcept?
//    let gridSize: BrowserGridSize
//    let renderingMode: BrowserRenderingMode
//    let symbolColor: Color
//    let vegasMode: Bool
//    let showConceptColors: Bool
//    
//    private var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize.columnCount)
//    }
//    
//    var body: some View {
//        LazyVGrid(columns: columns, spacing: 12) {
//            ForEach(concepts, id: \.primarySymbol) { concept in
//                UnifiedConceptCard(
//                    concept: concept,
//                    isSelected: selectedConcept?.primarySymbol == concept.primarySymbol,
//                    gridSize: gridSize,
//                    renderingMode: renderingMode,
//                    symbolColor: showConceptColors ? getConceptColor(concept) : symbolColor,
//                    vegasMode: vegasMode
//                ) {
//                    print("🔥 BUTTON TAPPED: \(concept.name)")
//                    selectedConcept = concept
//                    print("🔥 SELECTED CONCEPT: \(selectedConcept?.name ?? "nil")")
//                }
//            }
//        }
//    }
//    
//    private func getConceptColor(_ concept: SymbolConcept) -> Color {
//        // Return concept's preferred color or default
//        // For now, assign colors based on category
//        switch concept.category {
//        case .uiElements: return .blue
//        case .entityTypes: return .green
//        }
//    }
//}
//
//// MARK: - Unified Concept Card (matches symbol picker style)
//struct UnifiedConceptCard: View {
//    let concept: SymbolConcept
//    let isSelected: Bool
//    let gridSize: BrowserGridSize
//    let renderingMode: BrowserRenderingMode
//    let symbolColor: Color
//    let vegasMode: Bool
//    let onTap: () -> Void
//    
//    @State private var isHovered = false
//    @State private var animationOffset: CGFloat = 0
//    @State private var animationRotation: Double = 0
//    @State private var animationScale: CGFloat = 1
//    @State private var randomColor: Color = .primary
//    @State private var vegasTimer: Timer?
//    @Environment(AppSettings.self) private var appSettings
//    
//    var body: some View {
//        Button(action: onTap) {
//            VStack(spacing: 8) {
//                // Symbol with unified styling
//                Image(systemName: concept.primarySymbol.isEmpty ? "questionmark.square.dashed" : concept.primarySymbol)
//                    .font(.system(size: gridSize.symbolSize))
//                    .foregroundColor(isHovered || isSelected ? .white : (vegasMode ? randomColor : symbolColor))
//                    .symbolRenderingMode(swiftUIRenderingMode)
//                    .frame(width: gridSize.symbolSize + 12, height: gridSize.symbolSize + 12)
//                    .scaleEffect(vegasMode ? animationScale : 1)
//                    .rotationEffect(.degrees(vegasMode ? animationRotation : 0))
//                    .offset(x: vegasMode ? animationOffset : 0)
//                    .symbolEffect(.bounce, isActive: vegasMode)
//                    .symbolEffect(.pulse, isActive: vegasMode)
//                
//                // Name with consistent styling
//                if gridSize.showNames {
//                    Text(concept.name.isEmpty ? "Untitled" : concept.name)
//                        .font(.caption2)
//                        .fontWeight(.medium)
//                        .lineLimit(2)
//                        .multilineTextAlignment(.center)
//                        .foregroundColor(isHovered || isSelected ? .white : .secondary)
//                        .frame(height: 24) // Fixed height for consistency
//                }
//            }
//            .frame(minWidth: gridSize.buttonSize.min, maxWidth: gridSize.buttonSize.max,
//                   minHeight: gridSize.buttonSize.height, maxHeight: gridSize.buttonSize.height)
//            .background(
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(isHovered || isSelected ? Color.accentColor : Color.clear)
//                    .opacity(vegasMode ? 0.8 : 1)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 8)
//                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
//                           lineWidth: isSelected ? 2 : 1)
//            )
//        }
//        .buttonStyle(.borderless)
//        .onHover { hovering in
//            withAnimation(.easeInOut(duration: 0.15)) {
//                isHovered = hovering
//            }
//        }
//        .contextMenu {
//            Button("Edit") { onTap() }
//            Divider()
//            Menu("Change Category") {
//                ForEach(Category.allCases, id: \.self) { category in
//                    Button(category.displayName) {
//                        // TODO: Implement category change
//                    }
//                }
//            }
//            Button("Duplicate") {
//                // TODO: Implement duplicate
//            }
//            Divider()
//            Button("Delete", role: .destructive) {
//                // TODO: Implement delete
//            }
//        }
//        .onAppear {
//            if vegasMode {
//                startVegasAnimations()
//            }
//        }
//        .onChange(of: vegasMode) { oldValue, newValue in
//            if newValue {
//                startVegasAnimations()
//            } else {
//                stopVegasAnimations()
//            }
//        }
//        .onChange(of: appSettings.vegasAnimationSpeed) { _, _ in if vegasMode { restartVegasAnimations() } }
//        .onChange(of: appSettings.vegasColorCycleSpeed) { _, _ in if vegasMode { restartVegasAnimations() } }
//        .onChange(of: appSettings.vegasIntensity) { _, _ in if vegasMode { restartVegasAnimations() } }
//        .onChange(of: appSettings.vegasRotationEnabled) { _, _ in if vegasMode { restartVegasAnimations() } }
//    }
//    
//    private var swiftUIRenderingMode: SymbolRenderingMode {
//        switch renderingMode {
//        case .monochrome: return .monochrome
//        case .hierarchical: return .hierarchical
//        case .palette: return .palette
//        case .multicolor: return .multicolor
//        }
//    }
//    
//    // MARK: - Vegas Animations (unified with symbol picker)
//    private func restartVegasAnimations() {
//        stopVegasAnimations()
//        startVegasAnimations()
//    }
//
//    private func startVegasAnimations() {
//        vegasTimer?.invalidate()
//        vegasTimer = nil
//
//        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
//        randomColor = colors.randomElement() ?? .primary
//        
//        let baseSpeed = 2.5 / appSettings.vegasAnimationSpeed
//        let intensity = appSettings.vegasIntensity
//        let colorSpeed = 1.5 / appSettings.vegasColorCycleSpeed
//        
//        let randomnessFactor = appSettings.vegasRandomnessLevel
//        let scaleRange = appSettings.vegasScaleIntensity
//        let movementRange = appSettings.vegasMovementIntensity
//        
//        let minScale = 1.0 - (0.2 * intensity * randomnessFactor)
//        let maxScale = 1.0 + (0.3 * intensity * randomnessFactor) + scaleRange
//        
//        withAnimation(.easeInOut(duration: Double.random(in: baseSpeed...baseSpeed*1.5)).repeatForever(autoreverses: true)) {
//            animationScale = Double.random(in: minScale...maxScale)
//        }
//        
//        if appSettings.vegasRotationEnabled {
//            let rotationSpeed = Double.random(in: (4.0/intensity)...(6.0/intensity)) * (1.0 + randomnessFactor)
//            withAnimation(.linear(duration: rotationSpeed).repeatForever(autoreverses: false)) {
//                animationRotation = 360
//            }
//        } else {
//            animationRotation = 0
//        }
//        
//        let movementIntensity = movementRange * randomnessFactor
//        withAnimation(.easeInOut(duration: Double.random(in: baseSpeed...(baseSpeed*2.0))).repeatForever(autoreverses: true)) {
//            animationOffset = Double.random(in: (-movementIntensity)...(movementIntensity))
//        }
//        
//        let variableColorSpeed = colorSpeed * (0.5 + randomnessFactor)
//        vegasTimer = Timer.scheduledTimer(withTimeInterval: variableColorSpeed, repeats: true) { timer in
//            if !vegasMode {
//                timer.invalidate()
//                return
//            }
//            withAnimation(.easeInOut(duration: 0.3)) {
//                randomColor = colors.randomElement() ?? .primary
//            }
//        }
//    }
//    
//    private func stopVegasAnimations() {
//        vegasTimer?.invalidate()
//        vegasTimer = nil
//
//        withAnimation(.easeOut(duration: 0.5)) {
//            animationScale = 1
//            animationRotation = 0
//            animationOffset = 0
//            randomColor = symbolColor
//        }
//    }
//}
//
//// MARK: - Category Header
//struct CategoryHeader: View {
//    let title: String
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .font(.headline)
//                .fontWeight(.semibold)
//                .foregroundStyle(.primary)
//            
//            Spacer()
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 8)
//        .background(.regularMaterial, in: Rectangle())
//    }
//}
//
//// MARK: - Header View (updated for new category system)
//struct HeaderView: View {
//    let filteredCount: Int
//    @Binding var selectedCategory: String?
//    let availableCategories: [String]
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            HStack {
//                Text("Symbol Concepts")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                // Concept count
//                Text("\(filteredCount)")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(Color.gray.opacity(0.3), in: Capsule())
//            }
//            
//            // Category filter pills (click to unselect)
//            CategoryFilterView(
//                selectedCategory: $selectedCategory,
//                availableCategories: availableCategories
//            )
//        }
//    }
//}
//
//// MARK: - Category Filter View (updated to allow unselection)
//struct CategoryFilterView: View {
//    @Binding var selectedCategory: String?
//    let availableCategories: [String]
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//                // Category pills (click to toggle)
//                ForEach(availableCategories, id: \.self) { category in
//                    CategoryPill(
//                        title: category,
//                        isSelected: selectedCategory == category
//                    ) {
//                        // Toggle selection - click to unselect
//                        selectedCategory = selectedCategory == category ? nil : category
//                    }
//                }
//            }
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
//// MARK: - Category Pill (updated styling)
//struct CategoryPill: View {
//    let title: String
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: 6) {
//                Text(title)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                
//                if isSelected {
//                    Image(systemName: "xmark")
//                        .font(.caption2)
//                }
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(isSelected ? Color.blue : Color.gray.opacity(0.3), in: Capsule())
//            .foregroundStyle(isSelected ? .white : .primary)
//        }
//        .buttonStyle(.borderless)
//    }
//}
//
//// MARK: - Enhanced Category Manager Sheet (with auto-categorize moved here)
//struct CategoryManagerSheet: View {
//    @ObservedObject var iconStore: IconStore
//    @Environment(\.dismiss) private var dismiss
//    @State private var newCategoryName = ""
//    @State private var customCategories: [String] = []
//    @State private var showingAutoCategorizerSheet = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                // Add new category
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Add New Category")
//                        .font(.headline)
//                    
//                    HStack {
//                        TextField("Category name", text: $newCategoryName)
//                            .textFieldStyle(.roundedBorder)
//                            .autocorrectionDisabled(false)
//                            .onSubmit {
//                                if !newCategoryName.isEmpty {
//                                    customCategories.append(newCategoryName)
//                                    newCategoryName = ""
//                                }
//                            }
//                        
//                        Button("Add") {
//                            if !newCategoryName.isEmpty {
//                                customCategories.append(newCategoryName)
//                                newCategoryName = ""
//                            }
//                        }
//                        .disabled(newCategoryName.isEmpty)
//                        .buttonStyle(.borderedProminent)
//                    }
//                }
//                
//                // Existing categories
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Categories")
//                        .font(.headline)
//                    
//                    if customCategories.isEmpty {
//                        Text("No custom categories yet")
//                            .foregroundStyle(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    } else {
//                        ForEach(customCategories, id: \.self) { category in
//                            HStack {
//                                Text(category)
//                                Spacer()
//                                Button("Delete", role: .destructive) {
//                                    customCategories.removeAll { $0 == category }
//                                }
//                                .buttonStyle(.borderless)
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
//                
//                Spacer()
//                
//                // AI Categorization (moved here from content view)
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("AI Categorization")
//                        .font(.headline)
//                    
//                    Text("Automatically organize your symbols using AI")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    
//                    HStack(spacing: 12) {
//                    Button("Suggest Categories with AI") {
//                            // TODO: Implement AI category suggestions
//                        }
//                        .buttonStyle(.bordered)
//                        
//                        Button("Auto Categorize All") {
//                            showingAutoCategorizerSheet = true
//                        }
//                        .buttonStyle(.borderedProminent)
//                    }
//                }
//            }
//            .padding()
//            .navigationTitle("Manage Categories")
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//        .frame(minWidth: 400, minHeight: 400)
//        .sheet(isPresented: $showingAutoCategorizerSheet) {
//            AutoCategorizerSheet(iconStore: iconStore)
//        }
//        .onAppear {
//            // Load existing custom categories
//            customCategories = ["Work", "Personal", "Design"] // Placeholder
//        }
//    }
//}
//
//// MARK: - Auto Categorizer Sheet (moved from original location)
//struct AutoCategorizerSheet: View {
//    @ObservedObject var iconStore: IconStore
//    @Environment(\.dismiss) private var dismiss
//    @State private var isProcessing = false
//    @State private var processedCount = 0
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 24) {
//                VStack(spacing: 16) {
//                    Image(systemName: "wand.and.rays")
//                        .font(.system(size: 48))
//                        .foregroundStyle(.blue)
//                    
//                    VStack(spacing: 8) {
//                        Text("Auto Categorize Concepts")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                        
//                        Text("Automatically categorize your symbol concepts using AI analysis")
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                            .multilineTextAlignment(.center)
//                    }
//                }
//                
//                if isProcessing {
//                    VStack(spacing: 12) {
//                        ProgressView()
//                            .scaleEffect(1.2)
//                        
//                        Text("Processing \(processedCount) of \(iconStore.symbolConcepts.count) concepts...")
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                } else {
//                    VStack(spacing: 16) {
//                        Text("This will analyze each concept's name and symbol to suggest the most appropriate category.")
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                            .multilineTextAlignment(.center)
//                        
//                        HStack(spacing: 12) {
//                            Button("Cancel") {
//                                dismiss()
//                            }
//                            .buttonStyle(.bordered)
//                            
//                            Button("Start Categorization") {
//                                startAutoCategorization()
//                            }
//                            .buttonStyle(.borderedProminent)
//                        }
//                    }
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Auto Categorize")
//        }
//        .frame(minWidth: 400, minHeight: 300)
//    }
//    
//    private func startAutoCategorization() {
//        isProcessing = true
//        processedCount = 0
//        
//        // Simulate AI processing with realistic categorization
//        Task {
//            for concept in iconStore.symbolConcepts {
//                await MainActor.run {
//                    processedCount += 1
//                    
//                    // Simple rule-based categorization (simulating AI)
//                    print("Would categorize '\(concept.name)' as: \(suggestCategory(for: concept))")
//                }
//                
//                // Simulate processing time
//                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
//            }
//            
//            await MainActor.run {
//                isProcessing = false
//                dismiss()
//            }
//        }
//    }
//    
//    private func suggestCategory(for concept: SymbolConcept) -> Category {
//        let name = concept.name.lowercased()
//        let symbol = concept.primarySymbol.lowercased()
//        
//        // UI Elements patterns
//        if name.contains("add") || name.contains("delete") || name.contains("edit") || name.contains("share") ||
//           name.contains("settings") || name.contains("navigation") || name.contains("menu") ||
//           symbol.contains("plus") || symbol.contains("trash") || symbol.contains("pencil") || 
//           symbol.contains("square.and.arrow") || symbol.contains("gear") || symbol.contains("arrow") || 
//           symbol.contains("chevron") || symbol.contains("button") || symbol.contains("menu") {
//            return .uiElements
//        }
//        
//        // Default to entity types
//        return .entityTypes
//    }
//}
//
//// MARK: - Preview
//#Preview {
//    ContentListView(
//        selectedSidebarItem: .sfSymbols,
//        selectedSymbolConcept: .constant(nil),
//        selectedIcon: .constant(nil),
//        iconStore: IconStore(context: PersistenceController.preview.container.viewContext),
//        showingSymbolPicker: .constant(false),
//        showingAddConceptSheet: .constant(false)
//    )
//}
