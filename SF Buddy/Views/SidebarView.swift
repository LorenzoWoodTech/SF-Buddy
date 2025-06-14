//
//  SidebarView.swift
//  SF Buddy
//
//  Sidebar view containing smart groups and tags for navigation
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var iconStore: IconStore
    @Binding var selectedItem: SidebarItem?
    
    @State private var showingAddTagSheet = false
    
    var body: some View {
        List(selection: $selectedItem) {
            // Smart Groups Section
            Section("Library") {
                ForEach(iconStore.smartGroups) { group in
                    SmartGroupRow(group: group)
                        .tag(SidebarItem.smartGroup(group))
                }
            }
            
            // Tags Section
            Section {
                ForEach(iconStore.tags, id: \.self) { tag in
                    TagRow(tag: tag, iconCount: iconCountForTag(tag))
                        .tag(SidebarItem.tag(tag))
                        .contextMenu {
                            Button("Rename Tag") {
                                // TODO: Implement tag renaming
                            }
                            
                            Button("Delete Tag", role: .destructive) {
                                iconStore.deleteTag(tag)
                            }
                        }
                }
                .onDelete(perform: deleteTags)
            } header: {
                HStack {
                    Text("Tags")
                    Spacer()
                    Button {
                        showingAddTagSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("SF Buddy")
        #if os(macOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.insetGrouped)
        #endif
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(iconStore: iconStore)
        }
        .onAppear {
            // Select "All Icons" by default if nothing is selected
            if selectedItem == nil, let firstGroup = iconStore.smartGroups.first {
                selectedItem = .smartGroup(firstGroup)
            }
        }
    }
    
    /// Get icon count for a specific tag
    private func iconCountForTag(_ tag: Tag) -> Int {
        iconStore.icons.filter { icon in
            icon.tags?.contains(tag) == true
        }.count
    }
    
    /// Delete tags at specified offsets
    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            let tag = iconStore.tags[index]
            iconStore.deleteTag(tag)
        }
    }
}

// MARK: - Row Views

/// Row view for smart groups
struct SmartGroupRow: View {
    let group: SmartGroup
    
    var body: some View {
        HStack {
            Image(systemName: group.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(group.name)
                .font(.subheadline)
            
            Spacer()
            
            if group.count > 0 {
                Text("\(group.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

/// Row view for tags
struct TagRow: View {
    let tag: Tag
    let iconCount: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)
            
            Text(tag.name ?? "Unknown")
                .font(.subheadline)
            
            Spacer()
            
            if iconCount > 0 {
                Text("\(iconCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }
    
    private var tagColor: Color {
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
}

// MARK: - Add Tag Sheet

struct AddTagSheet: View {
    @ObservedObject var iconStore: IconStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var tagName = ""
    @State private var selectedColor = "blue"
    
    private let availableColors = [
        ("red", Color.red),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("green", Color.green),
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("pink", Color.pink),
        ("gray", Color.gray)
    ]
    
    var body: some View {
        Form {
            Section("Tag Details") {
                HStack {
                    Text("Name")
                    TextField("Enter tag name", text: $tagName)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Color")
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(availableColors, id: \.0) { colorName, color in
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(colorSelectionOverlay(for: colorName))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Tag")
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
                Button("Add") {
                    iconStore.createTag(name: tagName, color: selectedColor)
                    dismiss()
                }
                .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500,
               minHeight: 300, idealHeight: 350, maxHeight: 400)
        #endif
    }
    
    // MARK: - Helper Methods
    
    /// Create color selection overlay to avoid complex expressions
    @ViewBuilder
    private func colorSelectionOverlay(for colorName: String) -> some View {
        if selectedColor == colorName {
            Circle()
                .strokeBorder(.primary, lineWidth: 2)
        } else {
            Circle()
                .strokeBorder(.clear, lineWidth: 2)
        }
    }
}

#Preview {
    NavigationView {
        SidebarView(
            iconStore: IconStore(context: PersistenceController.preview.container.viewContext),
            selectedItem: .constant(nil)
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
