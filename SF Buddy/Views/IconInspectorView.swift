//
//  IconInspectorView.swift
//  SF Buddy
//
//  Inspector view for displaying icon details following HIG guidelines
//

import SwiftUI

struct IconInspectorView: View {
    let icon: Icon
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Semantic Name", value: icon.semanticName ?? "Unknown")
                LabeledContent("Base Symbol", value: icon.baseSymbol ?? "Unknown")
                LabeledContent("Type", value: icon.isCustomAsset ? "Custom Asset" : "SF Symbol")
                
                if let dateCreated = icon.dateCreated {
                    LabeledContent("Created", value: DateFormatter.shortDate.string(from: dateCreated))
                }
                
                if let dateModified = icon.dateModified {
                    LabeledContent("Modified", value: DateFormatter.shortDate.string(from: dateModified))
                }
            }
            
            if let tags = icon.tags as? Set<Tag>, !tags.isEmpty {
                Section("Tags") {
                    ForEach(Array(tags), id: \.self) { tag in
                        Label(tag.name ?? "Unknown", systemImage: "tag")
                            .foregroundStyle(tagColor(for: tag))
                    }
                }
            }
            
            if let variants = icon.variants as? Set<Variant>, !variants.isEmpty {
                Section("Variants") {
                    ForEach(Array(variants), id: \.self) { variant in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(variant.symbolName ?? "Unknown")
                                .font(.body)
                            if let context = variant.context, !context.isEmpty {
                                Text(context)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Inspector")
        #if os(macOS)
        .navigationSubtitle(icon.semanticName ?? "Unknown Icon")
        #else
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button("Export Code") {
                    // TODO: Export code snippet functionality
                }
                .help("Export code snippet for this icon")
            }
            #endif
        }
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorString = tag.color else { return .secondary }
        
        switch colorString.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .secondary
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NavigationView {
        IconInspectorView(icon: Icon()) // This would need a proper preview icon
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}