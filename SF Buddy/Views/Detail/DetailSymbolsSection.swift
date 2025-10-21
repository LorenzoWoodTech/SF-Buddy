import SwiftUI
import AppKit

struct DetailSymbolsSection: View {
    let concept: SymbolConcept
    let symbols: [EditableSymbol]
    let gridSize: BrowserGridSize
    let selectedRenderingMode: BrowserRenderingMode
    let showSymbolNames: Bool
    let onAddSymbol: () -> Void
    let onEditSymbol: (EditableSymbol) -> Void
    let onDeleteSymbol: (EditableSymbol) -> Void
    let onMakePrimary: (EditableSymbol) -> Void
    let onExportIconProvider: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Symbol Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize.columnCount)
            LazyVGrid(columns: columns, spacing: 12) {
                // Existing symbols
                ForEach(Array(symbols.enumerated()), id: \.element.id) { index, symbol in
                    EditableSymbolCard(
                        symbol: symbol,
                        isPrimary: index == 0,
                        onTap: {
                            onEditSymbol(symbol)
                        },
                        onMakePrimary: {
                            onMakePrimary(symbol)
                        },
                        onDelete: {
                            onDeleteSymbol(symbol)
                        }
                    )
                }
                
                // Add symbol card
                AddSymbolCard(onAdd: onAddSymbol, hasExistingSymbols: !symbols.isEmpty)
            }
            
            // MARK: - Actions Section
            if !symbols.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Button("Copy Primary Symbol") {
                            if let primarySymbol = symbols.first {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(primarySymbol.symbolName, forType: .string)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(symbols.isEmpty)
                        
                        Button("Export IconProvider") {
                            onExportIconProvider()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Copy All Symbols") {
                            let allSymbols = symbols.map { $0.symbolName }.joined(separator: ", ")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(allSymbols, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

 