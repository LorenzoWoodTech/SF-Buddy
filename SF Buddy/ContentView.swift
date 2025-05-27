//
//  ContentView.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var showingSymbolPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            if symbolService.isProcessing {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding SF Symbols...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !symbolService.suggestedSymbols.isEmpty {
                SymbolPickerView()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    
                    Text("SF Buddy")
                        .font(.headline)
                    
                    Text("Press ⌃⌥⌘Space to find SF Symbols for selected text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(width: 300)
        .onReceive(NotificationCenter.default.publisher(for: .showSymbolPicker)) { _ in
            showingSymbolPicker = true
        }
    }
}

struct SymbolPickerView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Symbols for:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(symbolService.lastProcessedText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(symbolService.suggestedSymbols) { suggestion in
                    SymbolButton(suggestion: suggestion)
                }
            }
            .padding(.horizontal)
            
            Button("Clear") {
                symbolService.suggestedSymbols = []
                symbolService.lastProcessedText = ""
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct SymbolButton: View {
    let suggestion: SFSymbolSuggestion
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: suggestion.name)
                .font(.system(size: 20))
                .foregroundColor(isHovered ? .white : .primary)
                .frame(width: 32, height: 32)
            
            Text(suggestion.name)
                .font(.caption2)
                .foregroundColor(isHovered ? .white : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            symbolService.replaceTextWithSymbol(suggestion.name)
            // Close the popover after selection
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                delegate.popover?.performClose(nil)
            }
        }
    }
}

#Preview {
    ContentView()
}
