//
//  DetailView.swift
//  SF Buddy
//
//  Enhanced detail view with color picker, size controls, rendering modes, and related concepts
//

import SwiftUI
import CoreData
import AppKit

// MARK: - Detail Views
struct DetailView: View {
    @ObservedObject var iconStore: IconStore
    let selectedItem: SidebarItem?
    @Binding var selectedSymbolConcept: SymbolConcept?
    
    var body: some View {
        Group {
                if let concept = selectedSymbolConcept {
                    EnhancedConceptEditor(concept: concept, iconStore: iconStore)
                } else {
                        ContentUnavailableView(
                    "No Concept Selected",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Select a symbol concept to view its details")
                )
            }
        }
    }
}

// MARK: - Enhanced Concept Editor with All Features
struct EnhancedConceptEditor: View {
    let concept: SymbolConcept
    @ObservedObject var iconStore: IconStore
    
    // Editable states
    @State private var conceptName: String
    @State private var conceptColor: Color = .blue
    @State private var symbols: [EditableSymbol] = []
    @State private var isEditingName = false
    
    // Display controls
    @State private var selectedRenderingMode: BrowserRenderingMode = .hierarchical
    @State private var gridSize: BrowserGridSize = .medium
    @State private var showSymbolNames = true
    @State private var vegasMode = false
    
    // UI states
    @State private var showingSymbolPicker = false
    @State private var showingDeleteAlert = false
    @State private var symbolToDelete: EditableSymbol?
    @State private var editingSymbol: EditableSymbol?
    @State private var showingColorPicker = false
    @State private var showingRenderingPopover = false
    @State private var showingSizePopover = false
    @State private var showingRelatedConceptPicker = false
    @State private var showingRelatedConceptDetail = false
    @State private var selectedRelatedConcept: SymbolConcept?
    
    // Related concepts
    @State private var relatedConcepts: [SymbolConcept] = []
    
    init(concept: SymbolConcept, iconStore: IconStore) {
        self.concept = concept
        self.iconStore = iconStore
        self._conceptName = State(initialValue: concept.name)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ConceptHeaderView(
                    concept: concept,
                    conceptName: $conceptName,
                    conceptColor: conceptColor,
                    isEditingName: $isEditingName,
                    showingColorPicker: $showingColorPicker,
                    symbols: symbols,
                    updateConceptType: updateConceptType,
                    updateConceptCategory: updateConceptCategory,
                    getConceptTypeDisplay: getConceptTypeDisplay
                )
                
                DetailDisplayControlsView(
                    gridSize: $gridSize,
                    selectedRenderingMode: $selectedRenderingMode,
                    conceptColor: $conceptColor,
                    vegasMode: $vegasMode,
                    showSymbolNames: $showSymbolNames,
                    showingSizePopover: $showingSizePopover,
                    showingRenderingPopover: $showingRenderingPopover,
                    showingColorPicker: $showingColorPicker
                )
                
                DetailSymbolsSection(
                    concept: concept,
                    symbols: symbols,
                    gridSize: gridSize,
                    selectedRenderingMode: selectedRenderingMode,
                    showSymbolNames: showSymbolNames,
                    onAddSymbol: { showingSymbolPicker = true },
                    onEditSymbol: { symbol in
                                editingSymbol = symbol
                            },
                    onDeleteSymbol: { symbol in
                                symbolToDelete = symbol
                                showingDeleteAlert = true
                    },
                    onMakePrimary: moveToPrimary,
                    onExportIconProvider: { _ = exportIconProvider() }
                )
                
                DetailRelatedConceptsSection(
                    relatedConcepts: relatedConcepts,
                    onAddRelatedConcept: { showingRelatedConceptPicker = true },
                    onRemoveRelatedConcept: removeRelatedConcept,
                    onTapRelatedConcept: { relatedConcept in
                                        selectedRelatedConcept = relatedConcept
                                        showingRelatedConceptDetail = true
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(conceptName.isEmpty ? "Symbol Concept" : conceptName)
        .sheet(isPresented: $showingSymbolPicker) {
            UnifiedSymbolPicker(
                searchQuery: conceptName,
                onSymbolSelected: { symbolName in
                    addSymbol(symbolName)
                }
            )
        }
        .sheet(item: $editingSymbol) { symbol in
            EditSymbolSheet(symbol: symbol) { updatedSymbol in
                updateSymbol(updatedSymbol)
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            DetailColorPickerSheet(conceptColor: $conceptColor, showingColorPicker: $showingColorPicker)
        }
        .alert("Delete Symbol", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let symbol = symbolToDelete {
                    deleteSymbol(symbol)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this symbol? This action cannot be undone.")
        }
        .sheet(isPresented: $showingRelatedConceptPicker) {
            RelatedConceptPicker(
                iconStore: iconStore,
                currentConcept: concept,
                onConceptSelected: { selectedConcept in
                    addRelatedConcept(selectedConcept)
                }
            )
        }
        .sheet(isPresented: $showingRelatedConceptDetail) {
            if let selectedConcept = selectedRelatedConcept {
                NavigationStack {
                    EnhancedConceptEditor(concept: selectedConcept, iconStore: iconStore)
                        .navigationTitle(selectedConcept.name.isEmpty ? "Related Concept" : selectedConcept.name)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingRelatedConceptDetail = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            loadSymbols()
            loadRelatedConcepts()
        }
    }
    
    // MARK: - Symbol Management
    
    private func loadSymbols() {
        let primarySymbol = concept.primarySymbol
        guard !primarySymbol.isEmpty else { return }
        
        // Start with primary symbol
        symbols = [EditableSymbol(symbolName: primarySymbol, displayName: nil)]
        
        // Add common variants based on primary symbol
        switch primarySymbol {
        case "house":
            symbols.append(contentsOf: [
                EditableSymbol(symbolName: "house.fill", displayName: "Filled"),
                EditableSymbol(symbolName: "house.circle", displayName: "Circle"),
                EditableSymbol(symbolName: "house.circle.fill", displayName: "Circle Filled")
            ])
        case "gear":
            symbols.append(contentsOf: [
                EditableSymbol(symbolName: "gear.circle", displayName: "Circle"),
                EditableSymbol(symbolName: "gear.circle.fill", displayName: "Circle Filled"),
                EditableSymbol(symbolName: "gearshape.fill", displayName: "Shape Filled")
            ])
        case "magnifyingglass":
            symbols.append(contentsOf: [
                EditableSymbol(symbolName: "magnifyingglass.circle", displayName: "Circle"),
                EditableSymbol(symbolName: "magnifyingglass.circle.fill", displayName: "Circle Filled")
            ])
        case "trash":
            symbols.append(contentsOf: [
                EditableSymbol(symbolName: "trash.fill", displayName: "Filled"),
                EditableSymbol(symbolName: "trash.circle", displayName: "Circle"),
                EditableSymbol(symbolName: "trash.circle.fill", displayName: "Circle Filled")
            ])
        case "plus":
            symbols.append(contentsOf: [
                EditableSymbol(symbolName: "plus.circle", displayName: "Circle"),
                EditableSymbol(symbolName: "plus.circle.fill", displayName: "Circle Filled"),
                EditableSymbol(symbolName: "plus.square", displayName: "Square")
            ])
        default:
            break
        }
    }
    
    private func loadRelatedConcepts() {
        // Find related concepts based on category and naming patterns
        let currentCategory = concept.category
        let currentName = concept.name.lowercased()
        
        relatedConcepts = iconStore.symbolConcepts.filter { otherConcept in
            guard otherConcept.primarySymbol != concept.primarySymbol else { return false }
            
            // Same category
            if otherConcept.category == currentCategory {
                return true
            }
            
            // Similar naming patterns
            let otherName = otherConcept.name.lowercased()
            if currentName.contains("user") && otherName.contains("person") { return true }
            if currentName.contains("delete") && otherName.contains("trash") { return true }
            if currentName.contains("edit") && otherName.contains("pencil") { return true }
            if currentName.contains("settings") && otherName.contains("gear") { return true }
            
            return false
        }
        .prefix(6) // Limit to 6 related concepts
        .map { $0 }
    }
    
    private func addSymbol(_ symbolName: String) {
        let newSymbol = EditableSymbol(symbolName: symbolName, displayName: nil)
        symbols.append(newSymbol)
    }
    
    private func updateSymbol(_ updatedSymbol: EditableSymbol) {
        if let index = symbols.firstIndex(where: { $0.id == updatedSymbol.id }) {
            symbols[index] = updatedSymbol
        }
    }
    
    private func deleteSymbol(_ symbol: EditableSymbol) {
        symbols.removeAll { $0.id == symbol.id }
    }
    
    private func moveToPrimary(_ symbol: EditableSymbol) {
        guard let index = symbols.firstIndex(where: { $0.id == symbol.id }) else { return }
        let symbolToMove = symbols.remove(at: index)
        symbols.insert(symbolToMove, at: 0)
    }
    
    private func exportIconProvider() -> String {
        var code = "// Generated Icon Provider\n"
        code += "enum Icons {\n"
        let safeName = conceptName.isEmpty ? "symbol" : conceptName.lowercased().replacingOccurrences(of: " ", with: "")
        
        for (index, symbol) in symbols.enumerated() {
            let variableName = index == 0 ? safeName : "\(safeName)_\(symbol.symbolName.replacingOccurrences(of: ".", with: "_"))"
            code += "    static let \(variableName) = \"\(symbol.symbolName)\"\n"
        }
        
        code += "}\n"
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        return code
    }
    
    private func addRelatedConcept(_ concept: SymbolConcept) {
        if !relatedConcepts.contains(where: { $0.primarySymbol == concept.primarySymbol }) {
            relatedConcepts.append(concept)
        }
    }
    
    private func removeRelatedConcept(_ concept: SymbolConcept) {
        relatedConcepts.removeAll { $0.primarySymbol == concept.primarySymbol }
    }
    
    private func updateConceptType(_ concept: SymbolConcept, to type: SymbolType) {
        // Note: This is a simulation - in a real app, you'd update the Core Data model
        print("Would update concept '\(concept.name)' type to: \(type.rawValue)")
        // TODO: Implement actual Core Data update
    }
    
    private func updateConceptCategory(_ concept: SymbolConcept, to category: Category) {
        // Note: This is a simulation - in a real app, you'd update the Core Data model
        print("Would update concept '\(concept.name)' category to: \(category.rawValue)")
        // TODO: Implement actual Core Data update
    }
    
    private func getConceptTypeDisplay(_ concept: SymbolConcept) -> String {
        let name = concept.name.lowercased()
        let symbol = concept.primarySymbol.lowercased()
        
        // UI Elements patterns
        if symbol.contains("button") || symbol.contains("arrow") || symbol.contains("chevron") ||
           symbol.contains("plus") || symbol.contains("minus") || symbol.contains("xmark") ||
           symbol.contains("checkmark") || symbol.contains("menu") || symbol.contains("list") ||
           symbol.contains("square.and.arrow") || symbol.contains("trash") || symbol.contains("pencil") ||
           name.contains("button") || name.contains("navigation") || name.contains("menu") ||
           name.contains("delete") || name.contains("edit") || name.contains("share") || name.contains("add") {
            return "UI Elements"
        }
        
        // System patterns
        if symbol.contains("gear") || symbol.contains("settings") || symbol.contains("bell") ||
           symbol.contains("wifi") || symbol.contains("battery") || symbol.contains("lock") ||
           symbol.contains("shield") || symbol.contains("exclamation") || symbol.contains("info") ||
           symbol.contains("antenna") || symbol.contains("network") ||
           name.contains("settings") || name.contains("notification") || name.contains("error") ||
           name.contains("warning") || name.contains("system") || name.contains("alert") {
            return "System"
        }
        
        // Default to entities
        return "Entities"
    }
}

// MARK: - Editable Symbol Model
struct EditableSymbol: Identifiable, Equatable {
    let id = UUID()
    let symbolName: String
    let displayName: String?
    
    var effectiveDisplayName: String {
        displayName ?? symbolName.replacingOccurrences(of: ".", with: " ").capitalized
    }
}

// MARK: - Editable Symbol Card
struct EditableSymbolCard: View {
    let symbol: EditableSymbol
    let isPrimary: Bool
    let onTap: () -> Void
    let onMakePrimary: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Symbol with primary indicator
                ZStack {
                    Image(systemName: symbol.symbolName)
                        .font(.system(size: isPrimary ? 40 : 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isPrimary ? .blue : .primary)
                        .frame(width: 50, height: 50)
                    
                    // Primary badge
                    if isPrimary {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 12, height: 12)
                                    .overlay {
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
                                    }
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
                
                // Symbol name or display name (fixed height to prevent shifting)
                Text(symbol.effectiveDisplayName)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(height: 24) // Fixed height for 2 lines
                
                // Primary label
                if isPrimary {
                    Text("PRIMARY")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isPrimary ? 120 : 110)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isPrimary ? Color.blue.opacity(0.06) : Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? .blue.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit Symbol") {
                onTap()
            }
            
            if !isPrimary {
                Button("Make Primary") {
                    onMakePrimary()
                }
            }
            
            Button("Copy Symbol Name") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(symbol.symbolName, forType: .string)
            }
            
            if !isPrimary {
                Divider()
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}

// MARK: - Add Symbol Card (conditional styling)
struct AddSymbolCard: View {
    let onAdd: () -> Void
    let hasExistingSymbols: Bool
    
    private var isGrayStyle: Bool { hasExistingSymbols }
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundStyle(isGrayStyle ? .secondary : Color.blue)
                    .frame(width: 50, height: 50)
                
                Text("Add Symbol")
                    .font(.caption)
                    .foregroundStyle(isGrayStyle ? .secondary : Color.blue)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)  
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isGrayStyle ? Color.gray.opacity(0.1) : Color.blue.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isGrayStyle ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.4), 
                        style: isGrayStyle ? StrokeStyle(lineWidth: 1, dash: [4, 4]) : StrokeStyle(lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unified Symbol Picker
struct UnifiedSymbolPicker: View {
    let searchQuery: String
    let onSymbolSelected: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSymbol: String?
    
    var body: some View {
        NavigationStack {
            SFSymbolBrowserView(selectedSymbol: Binding(
                get: { selectedSymbol },
                set: { newSymbol in
                    if let symbol = newSymbol {
                        onSymbolSelected(symbol)
                        dismiss()
                    }
                }
            ))
            .navigationTitle("Add Symbol")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-fill search with concept name if available
            if !searchQuery.isEmpty {
                // This would ideally set the search field in SFSymbolBrowserView
                // For now, we'll just pass it through
            }
        }
    }
}

// MARK: - Edit Symbol Sheet
struct EditSymbolSheet: View {
    let symbol: EditableSymbol
    let onSave: (EditableSymbol) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var symbolName: String
    @State private var displayName: String
    @State private var showingSymbolPicker = false
    
    init(symbol: EditableSymbol, onSave: @escaping (EditableSymbol) -> Void) {
        self.symbol = symbol
        self.onSave = onSave
        self._symbolName = State(initialValue: symbol.symbolName)
        self._displayName = State(initialValue: symbol.displayName ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: symbolName)
                            .font(.title)
                            .foregroundStyle(.blue)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            TextField("Symbol Name", text: $symbolName)
                                .fontDesign(.monospaced)
                            
                            Button("Browse Symbols") {
                                showingSymbolPicker = true
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("SF Symbol")
                }
                
                Section {
                    TextField("Display Name (Optional)", text: $displayName)
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("A custom name for this symbol variant. Leave empty to use the symbol name.")
                }
            }
                         .navigationTitle("Edit Symbol")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedSymbol = EditableSymbol(
                            symbolName: symbolName,
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                        onSave(updatedSymbol)
                        dismiss()
                    }
                    .disabled(symbolName.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
                 .sheet(isPresented: $showingSymbolPicker) {
             UnifiedSymbolPicker(searchQuery: displayName.isEmpty ? symbolName : displayName) { selectedSymbol in
                 symbolName = selectedSymbol
             }
         }
    }
}

// MARK: - Related Concept Card
struct RelatedConceptCard: View {
    let concept: SymbolConcept
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: concept.primarySymbol.isEmpty ? "questionmark.square.dashed" : concept.primarySymbol)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                
                Text(concept.name.isEmpty ? "Untitled" : concept.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(concept.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.3), in: Capsule())
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open Details") {
                onTap()
            }
            
            Divider()
            
            Button("Remove", role: .destructive) {
                onRemove()
            }
        }
    }
}

// MARK: - Related Concept Picker
struct RelatedConceptPicker: View {
    @ObservedObject var iconStore: IconStore
    let currentConcept: SymbolConcept
    let onConceptSelected: (SymbolConcept) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingNewConceptSheet = false
    
    var availableConcepts: [SymbolConcept] {
        iconStore.symbolConcepts.filter { concept in
            concept.primarySymbol != currentConcept.primarySymbol &&
            (searchText.isEmpty || concept.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search concepts", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
                
                // Concepts list
                if availableConcepts.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Other Concepts" : "No Results",
                        systemImage: searchText.isEmpty ? "square.3.layers.3d.middle.filled" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Create your first concept to add relationships" : "No concepts match your search")
                    )
                } else {
                    List {
                        ForEach(availableConcepts, id: \.primarySymbol) { concept in
                            Button {
                                onConceptSelected(concept)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: concept.primarySymbol.isEmpty ? "questionmark.square.dashed" : concept.primarySymbol)
                                        .font(.title2)
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.blue)
                                        .frame(width: 32, height: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(concept.name.isEmpty ? "Untitled Concept" : concept.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        
                                        Text(concept.category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Related Concept")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("New Concept") {
                        showingNewConceptSheet = true
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showingNewConceptSheet) {
            // TODO: Add new concept creation sheet
            Text("New Concept Creation - TODO")
                .navigationTitle("New Concept")
        }
    }
}

// MARK: - Concept Header View
struct ConceptHeaderView: View {
    let concept: SymbolConcept
    @Binding var conceptName: String
    let conceptColor: Color
    @Binding var isEditingName: Bool
    @Binding var showingColorPicker: Bool
    let symbols: [EditableSymbol]
    let updateConceptType: (SymbolConcept, SymbolType) -> Void
    let updateConceptCategory: (SymbolConcept, Category) -> Void
    let getConceptTypeDisplay: (SymbolConcept) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Color indicator
                Circle()
                    .fill(conceptColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(.primary.opacity(0.3), lineWidth: 1)
                    )
                
                if isEditingName {
                    TextField("Concept Name", text: $conceptName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            isEditingName = false
                        }
                } else {
                    Text(conceptName.isEmpty ? "Untitled Concept" : conceptName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(conceptName.isEmpty ? .tertiary : .primary)
                        .onTapGesture(count: 2) {
                            isEditingName = true
                        }
                        .contextMenu {
                            Button("Edit Name") {
                                isEditingName = true
                            }
                            Button("Set Color") {
                                showingColorPicker = true
                            }
                        }
                }
                
                Spacer()
                
                // Color picker button
                Button(action: { showingColorPicker = true }) {
                    Image(systemName: "paintpalette")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Set concept color")
            }
            
            HStack {
                Text("\(symbols.count) symbol\(symbols.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                // Type selector
                Menu {
                    ForEach([SymbolType.entities, .uiElements, .system], id: \.self) { type in
                        Button(type.rawValue) {
                            updateConceptType(concept, type)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(getConceptTypeDisplay(concept))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.3), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Change type")
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                // Category selector
                Menu {
                    ForEach(Category.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            updateConceptCategory(concept, category)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(concept.category.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.3), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Change category")
            }
        }
    }
}

