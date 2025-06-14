//
//  IconGridView.swift
//  SF Buddy
//
//  Adaptive grid view for displaying icons with platform-appropriate layouts
//

import SwiftUI

struct IconGridView: View {
    let icons: [Icon]
    @Binding var selectedIcon: Icon?
    let onAddIcon: () -> Void
    let onPublish: () -> Void
    
    @State private var gridColumnCount = 6
    @State private var showingIconDetail = false
    
    // Multi-selection support (macOS primarily)
    @State private var selectedIcons: Set<Icon> = []
    
    var body: some View {
        Group {
            if icons.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridColumnCount),
                        spacing: 12
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            IconCell(
                                icon: icon,
                                isSelected: selectedIcon == icon || selectedIcons.contains(icon)
                            )
                            .onTapGesture {
                                handleIconSelection(icon)
                            }
                            #if os(macOS)
                            .onTapGesture(count: 2) {
                                selectedIcon = icon
                                showingIconDetail = true
                            }
                            #endif
                            .contextMenu {
                                iconContextMenu(for: icon)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(navigationTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingIconDetail) {
            if let selectedIcon = selectedIcon {
                IconDetailSheet(icon: selectedIcon)
            }
        }
        .onAppear {
            updateGridColumnCount()
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            updateGridColumnCount()
        }
        #endif
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        if icons.isEmpty {
            return "No Icons"
        } else {
            return "\(icons.count) Icon\(icons.count == 1 ? "" : "s")"
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(icon: .add, style: .circle)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Icons Yet")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Start building your icon registry by adding your first icon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add First Icon") {
                onAddIcon()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Add Icon", action: onAddIcon)
                .keyboardShortcut("n", modifiers: .command)
            
            Button("Publish", action: onPublish)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(icons.isEmpty)
        }
        
        ToolbarItem(placement: .automatic) {
            Menu {
                Picker("Grid Size", selection: $gridColumnCount) {
                    Text("Small (8 columns)").tag(8)
                    Text("Medium (6 columns)").tag(6)
                    Text("Large (4 columns)").tag(4)
                    Text("Extra Large (3 columns)").tag(3)
                }
            } label: {
                Image(systemName: "square.grid.3x3")
            }
        }
        #else
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Add Icon", action: onAddIcon)
                Button("Publish Registry", action: onPublish)
                    .disabled(icons.isEmpty)
                
                Divider()
                
                Picker("Grid Size", selection: $gridColumnCount) {
                    Text("Small").tag(8)
                    Text("Medium").tag(6)
                    Text("Large").tag(4)
                    Text("Extra Large").tag(3)
                }
            } label: {
                Image(systemName: "plus")
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func iconContextMenu(for icon: Icon) -> some View {
        Button("Edit") {
            selectedIcon = icon
            showingIconDetail = true
        }
        
        Button("Duplicate") {
            // TODO: Implement duplication
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            // TODO: Implement deletion with confirmation
        }
    }
    
    // MARK: - Methods
    
    private func handleIconSelection(_ icon: Icon) {
        #if os(macOS)
        // Handle multi-selection on macOS
        let modifiers = NSEvent.modifierFlags
        if modifiers.contains(.command) {
            if selectedIcons.contains(icon) {
                selectedIcons.remove(icon)
                if selectedIcon == icon {
                    selectedIcon = selectedIcons.first
                }
            } else {
                selectedIcons.insert(icon)
                selectedIcon = icon
            }
        } else if modifiers.contains(.shift) {
            // TODO: Implement range selection
            selectedIcon = icon
            selectedIcons = [icon]
        } else {
            selectedIcon = icon
            selectedIcons = [icon]
        }
        #else
        selectedIcon = icon
        selectedIcons = [icon]
        #endif
    }
    
    private func updateGridColumnCount() {
        #if os(macOS)
        // Adjust grid based on window width
        if let window = NSApp.mainWindow {
            let width = window.frame.width
            if width < 600 {
                gridColumnCount = 3
            } else if width < 800 {
                gridColumnCount = 4
            } else if width < 1000 {
                gridColumnCount = 6
            } else {
                gridColumnCount = 8
            }
        }
        #else
        // Use trait collection on iOS
        gridColumnCount = UIDevice.current.userInterfaceIdiom == .pad ? 6 : 4
        #endif
    }
}

// MARK: - Icon Cell

struct IconCell: View {
    let icon: Icon
    let isSelected: Bool
    
    @State private var showingPreview = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Symbol preview
            Group {
                if let baseSymbol = icon.baseSymbol {
                    if icon.isCustomAsset {
                        // Custom asset - load from bundle
                        Image(baseSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // SF Symbol
                        Image(systemName: baseSymbol)
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                    }
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .foregroundStyle(isSelected ? .white : .primary)
            
            // Semantic name
            Text(icon.semanticName ?? "unknown")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Base symbol name
            Text(icon.baseSymbol ?? "")
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(minHeight: 100)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : backgroundColorForPlatform)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                }
        }
        .scaleEffect(showingPreview ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: showingPreview)
        .onHover { hovering in
            showingPreview = hovering && !isSelected
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
}

// MARK: - Icon Detail Sheet

struct IconDetailSheet: View {
    let icon: Icon
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Icon Detail View")
                Text("Semantic Name: \(icon.semanticName ?? "Unknown")")
                Text("Base Symbol: \(icon.baseSymbol ?? "Unknown")")
                // TODO: Implement full detail editing
            }
            .navigationTitle("Edit Icon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, idealWidth: 600, maxWidth: 700,
               minHeight: 400, idealHeight: 500, maxHeight: 600)
        #endif
    }
}

#Preview {
    NavigationView {
        IconGridView(
            icons: [],
            selectedIcon: .constant(nil),
            onAddIcon: {},
            onPublish: {}
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
