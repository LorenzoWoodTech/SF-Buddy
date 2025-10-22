//
//  IconInspectorView.swift
//  SF Buddy
//
//  Inspector view for displaying icon details following HIG guidelines
//

import SwiftUI
import SwiftData

struct IconInspectorView: View {
    let icon: SFIcon
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Semantic Name", value: icon.semanticName.isEmpty ? "Unknown" : icon.semanticName)
                LabeledContent("Base Symbol", value: icon.baseSymbol.isEmpty ? "Unknown" : icon.baseSymbol)
                LabeledContent("Type", value: icon.isCustomAsset ? "Custom Asset" : "SF Symbol")
                
                LabeledContent("Created", value: DateFormatter.shortDate.string(from: icon.dateCreated))
                LabeledContent("Modified", value: DateFormatter.shortDate.string(from: icon.dateModified))
            }
            
            if !icon.tags.isEmpty {
                Section("Tags") {
                    ForEach(icon.tags, id: \.name) { tag in
                        Label(tag.name.isEmpty ? "Unknown" : tag.name, systemImage: "tag")
                            .foregroundStyle(tagColor(for: tag))
                    }
                }
            }
            
            if !icon.variants.isEmpty {
                Section("Variants") {
                    ForEach(icon.variants, id: \.symbolName) { variant in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(variant.symbolName.isEmpty ? "Unknown" : variant.symbolName)
                                .font(.body)
                            if !variant.context.isEmpty {
                                Text(variant.context)
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
        .navigationSubtitle(icon.semanticName.isEmpty ? "Unknown Icon" : icon.semanticName)
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
    
    private func tagColor(for tag: SFTag) -> Color {
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
        IconInspectorView(icon: SFIcon(semanticName: "home", baseSymbol: "house.fill"))
    }
    .modelContainer(SwiftDataContainer.preview)
}