//
//  DetailView.swift
//  SF Buddy
//
//  Minimal stub implementation for compatibility
//

import SwiftUI

struct DetailView: View {
    let selectedItem: SidebarItem?
    
    var body: some View {
        VStack {
            Text("Detail View")
                .font(.title)
            Text("This is a stub implementation")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DetailViewWithConcept: View {
    @ObservedObject var iconStore: IconStore
    let concept: SymbolConcept?
    
    var body: some View {
        VStack {
            Text("Detail View")
                .font(.title)
            if let concept = concept {
                Text("Concept: \(concept.name)")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    init(concept: SymbolConcept, iconStore: IconStore) {
        self._iconStore = ObservedObject(wrappedValue: iconStore)
        self.concept = concept
    }
}

// Stub types for compatibility
struct EditableSymbol: Identifiable, Equatable {
    let id = UUID()
    let symbolName: String
    
    static func == (lhs: EditableSymbol, rhs: EditableSymbol) -> Bool {
        lhs.symbolName == rhs.symbolName
    }
}

struct EditableSymbolCard: View {
    let symbol: EditableSymbol
    let isPrimary: Bool
    let onTap: () -> Void
    let onMakePrimary: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: symbol.symbolName)
                .font(.title2)
            Text(symbol.symbolName)
                .font(.caption2)
        }
        .frame(width: 80, height: 80)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
    }
}

struct AddSymbolCard: View {
    let onAdd: () -> Void
    let hasExistingSymbols: Bool
    
    var body: some View {
        Button(action: onAdd) {
            VStack {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Add Symbol")
                    .font(.caption2)
            }
            .frame(width: 80, height: 80)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DetailView(selectedItem: .sfSymbols)
}