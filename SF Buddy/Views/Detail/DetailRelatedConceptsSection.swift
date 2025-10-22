import SwiftUI

struct DetailRelatedConceptsSection: View {
    let relatedConcepts: [SymbolConcept]
    let onAddRelatedConcept: () -> Void
    let onRemoveRelatedConcept: (SymbolConcept) -> Void
    let onTapRelatedConcept: (SymbolConcept) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Related Concepts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Add related concept button (gray dashed style)
                Button(action: onAddRelatedConcept) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add Related")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.secondary.opacity(0.5), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.1)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
                }
                .buttonStyle(.plain)
                .help("Add related concept")
            }
            
            if relatedConcepts.isEmpty {
                Text("No related concepts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(relatedConcepts, id: \.primarySymbol) { relatedConcept in
                            RelatedConceptCard(concept: relatedConcept) {
                                onTapRelatedConcept(relatedConcept)
                            } onRemove: {
                                onRemoveRelatedConcept(relatedConcept)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
}

// Stub implementation for compatibility
struct RelatedConceptCard: View {
    let concept: SymbolConcept
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: concept.primarySymbol)
                .font(.title3)
            Text(concept.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(width: 80, height: 80)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}