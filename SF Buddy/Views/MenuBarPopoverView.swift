//
//  MenuBarPopoverView.swift
//  SF Buddy
//
//  Focused menu bar popover interface for quick symbol searching
//

import SwiftUI
import SwiftData
import SFBuddyKit

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    @State private var searchText = ""
    @State private var showingAPIKeyField = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            CompactHeaderView(
                searchText: $searchText,
                showingAPIKeyField: $showingAPIKeyField
            )
            
            Divider()
            
            // Main content area
            Group {
                if showingAPIKeyField || symbolService.claudeAPIKey.isEmpty {
                    APIKeyPromptView(showingAPIKeyField: $showingAPIKeyField)
                } else if !searchText.isEmpty && symbolService.isProcessing {
                    ProcessingView()
                } else if !symbolService.suggestedSymbols.isEmpty {
                    SymbolResultsGrid()
                } else if !searchText.isEmpty && symbolService.suggestedSymbols.isEmpty && !symbolService.isProcessing {
                    EmptyResultsView()
                } else {
                    RecentSearchesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 380, height: 480)
        .background(.regularMaterial)
        .onAppear {
            setupSymbolServiceCallback()
        }
    }
    
    private func setupSymbolServiceCallback() {
        symbolService.trackSymbolActionCallback = { symbolName, action, searchTerm in
            Task { @MainActor in
                let descriptor = FetchDescriptor<RecentSearch>(
                    predicate: #Predicate { $0.searchTerm == searchTerm }
                )
                
                do {
                    let existingSearches = try modelContext.fetch(descriptor)
                    let search: RecentSearch
                    
                    if let existingSearch = existingSearches.first {
                        search = existingSearch
                        search.selectedSymbol = symbolName
                    } else {
                        search = RecentSearch(searchTerm: searchTerm, selectedSymbol: symbolName)
                        modelContext.insert(search)
                    }
                    
                    search.recordAction(action)
                    try modelContext.save()
                } catch {
                    print("Failed to track symbol action: \(error)")
                }
            }
        }
    }
}

// MARK: - Compact Header
private struct CompactHeaderView: View {
    @Binding var searchText: String
    @Binding var showingAPIKeyField: Bool
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row with branding and actions
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundStyle(.blue.gradient)
                        .font(.title3)
                    Text("SF Buddy")
                        .font(.system(.subheadline, weight: .semibold))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // API key status indicator
                    Button {
                        showingAPIKeyField.toggle()
                    } label: {
                        Image(systemName: symbolService.claudeAPIKey.isEmpty ? "key.slash" : "key.fill")
                            .foregroundStyle(symbolService.claudeAPIKey.isEmpty ? .orange : .green)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help(symbolService.claudeAPIKey.isEmpty ? "Add API Key" : "API Key Configured")
                    
                    // Main app button
                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        for window in NSApp.windows {
                            if window.title == "SF Buddy" {
                                window.makeKeyAndOrderFront(nil)
                                return
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Open Main App")
                }
            }
            
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "sparkles.magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                TextField("Describe symbols you need...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .default))
                    .onSubmit {
                        performSearch()
                    }
                
                if symbolService.isProcessing {
                    ProgressView()
                        .controlSize(.mini)
                } else if !searchText.isEmpty {
                    Button {
                        clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(12)
    }
    
    private func performSearch() {
        guard !searchText.isEmpty, !symbolService.claudeAPIKey.isEmpty else { return }
        Task {
            await symbolService.searchSymbols(for: searchText)
        }
    }
    
    private func clearSearch() {
        searchText = ""
        symbolService.suggestedSymbols = []
    }
}

// MARK: - API Key Prompt
private struct APIKeyPromptView: View {
    @Binding var showingAPIKeyField: Bool
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    @State private var tempAPIKey = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange.gradient)
            
            Text("API Key Required")
                .font(.headline)
            
            Text("Add your Anthropic API key to enable AI-powered symbol search")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                SecureField("Paste API key here", text: $tempAPIKey)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        saveAPIKey()
                    }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        tempAPIKey = ""
                        showingAPIKeyField = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    
                    Button("Save") {
                        saveAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            Link("Get API Key →", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                .font(.caption2)
                .foregroundStyle(.blue)
        }
        .padding(20)
        .onAppear {
            tempAPIKey = symbolService.claudeAPIKey
        }
    }
    
    private func saveAPIKey() {
        symbolService.claudeAPIKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        showingAPIKeyField = false
        tempAPIKey = ""
    }
}

// MARK: - Processing View
private struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index) * 0.5) * 0.3)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                }
            }
            
            Text("Finding symbols...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Symbol Results Grid
private struct SymbolResultsGrid: View {
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(symbolService.suggestedSymbols, id: \.id) { suggestion in
                    SymbolButton(suggestion: suggestion)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Symbol Button
private struct SymbolButton: View {
    let suggestion: SFSymbolSuggestion
    @State private var isPressed = false
    @State private var showingCopyFeedback = false
    
    var body: some View {
        Button {
            copySymbolName()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: suggestion.name)
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                    .frame(height: 22)
                
                Text(suggestion.name)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(height: 18)
            }
            .padding(6)
            .frame(width: 70, height: 54)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.green, lineWidth: showingCopyFeedback ? 1.5 : 0)
                    .animation(.easeInOut(duration: 0.15), value: showingCopyFeedback)
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
    
    private func copySymbolName() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(suggestion.name, forType: .string)
        
        // Show copy feedback
        withAnimation(.easeInOut(duration: 0.15)) {
            showingCopyFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.15)) {
                showingCopyFeedback = false
            }
        }
    }
}

// MARK: - Recent Searches
private struct RecentSearchesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: \RecentSearch.dateSearched,
        order: .reverse,
        animation: .default
    ) private var recentSearches: [RecentSearch]
    
    var body: some View {
        if recentSearches.isEmpty {
            EmptyStateView()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    ForEach(recentSearches.prefix(8)) { search in
                        RecentSearchRow(search: search)
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Recent Search Row
private struct RecentSearchRow: View {
    let search: RecentSearch
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    
    var body: some View {
        Button {
            performSearch()
        } label: {
            HStack(spacing: 10) {
                // Symbol preview
                if let selectedSymbol = search.selectedSymbol {
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
                
                // Search info
                VStack(alignment: .leading, spacing: 2) {
                    Text(search.searchTerm)
                        .font(.system(.caption, weight: .medium))
                        .lineLimit(1)
                    
                    if let selectedSymbol = search.selectedSymbol {
                        Text(selectedSymbol)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Action count
                Text("\(search.timesUsed)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
    
    private func performSearch() {
        Task {
            await symbolService.searchSymbols(for: search.searchTerm)
        }
    }
}

// MARK: - Empty States
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 24))
                .foregroundStyle(.blue.gradient)
            
            Text("No Recent Searches")
                .font(.system(.caption, weight: .medium))
            
            Text("Search for symbols to see them here")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding(20)
    }
}

private struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            
            Text("No Results")
                .font(.system(.caption, weight: .medium))
            
            Text("Try different search terms")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
        .padding(20)
    }
}

// MARK: - Preview
#Preview {
    MenuBarPopoverView()
        .modelContainer(SwiftDataContainer.preview)
        .environment(SFSymbolPackageSettings.shared)
        .environment(AppSettings.shared)
}