//
//  IconListView.swift
//  SF Buddy
//
//  Native list view for displaying icons following HIG guidelines
//  Renamed from IconGridView to better reflect List-based design
//

import SwiftUI

struct IconListView: View {
    let icons: [Icon]
    @Binding var selectedIcon: Icon?
    let onAddIcon: () -> Void
    let onPublish: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if icons.isEmpty {
                emptyStateView
            } else {
                List(icons, id: \.self, selection: $selectedIcon) { icon in
                    // iPhone uses NavigationLink, iPad/Mac uses selection binding
                    if horizontalSizeClass == .compact {
                        NavigationLink(value: icon) {
                            IconRow(icon: icon)
                        }
                    } else {
                        IconRow(icon: icon)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIcon = icon
                                #if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #endif
                            }
                    }
                }
                #if os(macOS)
                .listStyle(.inset)
                #else
                .listStyle(.plain)
                #endif
            }
        }
        .navigationTitle(navigationTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            toolbarContent
        }
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
        ContentUnavailableView(
            "No Icons",
            systemImage: "square.stack.3d.up.slash",
            description: Text("Start building your icon registry by adding your first icon.")
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        // macOS: Add (cmd-N) & Publish… (shift-cmd-P)
        ToolbarItem(placement: .primaryAction) {
            Button("Add Icon", action: onAddIcon)
                .keyboardShortcut("n", modifiers: .command)
        }
        
        ToolbarItem(placement: .secondaryAction) {
            Button("Publish…", action: onPublish)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(icons.isEmpty)
        }
        #else
        // iOS: trailing plus only
        ToolbarItem(placement: .primaryAction) {
            Button(action: onAddIcon) {
                Image(systemName: "plus")
            }
        }
        #endif
    }
}

// MARK: - Icon Row

/// Native row design following HIG specifications:
/// • Leading: 32 pt SF Symbol / custom asset, hierarchical rendering
/// • Title: semanticName – .body, weight medium
/// • Subtitle: baseSymbol (monospaced) + optional "• Custom" capsule
struct IconRow: View {
    let icon: Icon
    
    var body: some View {
        HStack(spacing: 12) {
            // Leading: 32 pt symbol with hierarchical rendering
            Group {
                if let baseSymbol = icon.baseSymbol {
                    if icon.isCustomAsset {
                        // Custom asset - load from bundle
                        Image(baseSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // SF Symbol - hierarchical rendering mode for better visual hierarchy
                        Image(systemName: baseSymbol)
                            .symbolRenderingMode(.hierarchical)
                    }
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.title2)
            .foregroundStyle(.primary)
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                // Title: semanticName – .body, weight medium
                Text(icon.semanticName ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Subtitle: baseSymbol (monospaced) + optional "• Custom" capsule
                HStack(spacing: 4) {
                    Text(icon.baseSymbol ?? "No symbol")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                        .lineLimit(1)
                    
                    if icon.isCustomAsset {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        Text("Custom")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuContent
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Duplicate") {
            // TODO: Implement duplicate functionality
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            // TODO: Implement delete functionality
        }
    }
}

#Preview {
    NavigationView {
        IconListView(
            icons: [],
            selectedIcon: .constant(nil),
            onAddIcon: {},
            onPublish: {}
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}