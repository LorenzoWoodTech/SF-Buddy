//
//  MainContentView.swift
//  SF Buddy
//
//  Simplified menu bar popover focused interface
//

import SwiftUI
import SwiftData
import SF_Buddy_Package

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var symbolService = SF_Buddy_Package.SFSymbolService.shared
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search
                HeaderView(searchText: $searchText, showingSearch: $showingSearch, showingSettings: $showingSettings)
                
                // Main content
                if showingSearch || !symbolService.suggestedSymbols.isEmpty {
                    SearchResultsView()
                } else {
                    RecentSearchesList()
                }
            }
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(SFSymbolPackageSettings.shared)
                .environment(SFSymbolVegasSettings.shared)
                .environment(AppSettings.shared)
        }
        .onAppear {
            // Setup symbol action tracking callback
            setupSymbolServiceCallback()
        }
    }
    
    private func setupSymbolServiceCallback() {
        symbolService.trackSymbolActionCallback = { symbolName, action, searchTerm in
            Task { @MainActor in
                // Get or create recent search
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

private struct HeaderView: View {
    @Binding var searchText: String
    @Binding var showingSearch: Bool
    @Binding var showingSettings: Bool
    @StateObject private var symbolService = SF_Buddy_Package.SFSymbolService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // App title
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)
                
                Text("SF Buddy")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search for symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !searchText.isEmpty {
                            performSearch()
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        showingSearch = !newValue.isEmpty
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        showingSearch = false
                        symbolService.suggestedSymbols = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            
            // API key warning if needed
            if symbolService.claudeAPIKey.isEmpty && !symbolService.isProcessing {
                APIKeyWarning()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
    
    private func performSearch() {
        Task {
            await symbolService.searchSymbols(for: searchText)
        }
    }
}

private struct APIKeyWarning: View {
    @StateObject private var symbolService = SF_Buddy_Package.SFSymbolService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.orange)
                Text("API Key Required")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            SecureField("Enter Anthropic API Key", text: $symbolService.claudeAPIKey)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            
            Link("Get API Key →", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                .font(.caption2)
                .foregroundStyle(.blue)
        }
        .padding(10)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SearchResultsView: View {
    @StateObject private var symbolService = SF_Buddy_Package.SFSymbolService.shared
    
    var body: some View {
        Group {
            if symbolService.isProcessing {
                ProcessingView()
            } else if !symbolService.suggestedSymbols.isEmpty {
                PackageSymbolPickerView()
            } else if symbolService.apiKeyMissingOrInvalid {
                EmptyStateView(
                    icon: "key.slash",
                    title: "API Key Issue",
                    message: "Check your Anthropic API key and try again"
                )
            } else if symbolService.claudeAPIKey.isEmpty {
                EmptyStateView(
                    icon: "key.slash",
                    title: "API Key Needed",
                    message: "Add your Anthropic API key above to search for symbols"
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "Try different search terms"
                )
            }
        }
    }
}

private struct PackageSymbolPickerView: View {
    @StateObject private var symbolService = SF_Buddy_Package.SFSymbolService.shared
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(symbolService.suggestedSymbols, id: \.id) { suggestion in
                    PackageSymbolButton(suggestion: suggestion)
                }
            }
            .padding(16)
        }
    }
}

private struct PackageSymbolButton: View {
    let suggestion: SFSymbolSuggestion
    @State private var isPressed = false
    @State private var showingCopyFeedback = false
    
    var body: some View {
        Button {
            copySymbol()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: suggestion.name)
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .frame(height: 30)
                
                Text(suggestion.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(width: 80, height: 70)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.green, lineWidth: showingCopyFeedback ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showingCopyFeedback)
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
    
    private func copySymbol() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(suggestion.name, forType: .string)
        #endif
        
        // TODO: Track this action when we implement recent searches
        
        // Show feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            showingCopyFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingCopyFeedback = false
            }
        }
    }
}

private struct RecentSearchesList: View {
    // TODO: Implement recent searches using SwiftData
    // For now, show empty state
    var body: some View {
        EmptyRecentView()
    }
}

private struct EmptyRecentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(.blue.gradient)
            
            Text("No Recent Searches")
                .font(.headline)
            
            Text("Search for symbols to see them here with quick access to copy or re-search")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
    }
}

private struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index) * 0.5) * 0.5)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                }
            }
            
            Text("Finding symbols...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
    }
}

#Preview {
    MainContentView()
        .modelContainer(SwiftDataContainer.preview)
        .environment(SFSymbolPackageSettings.shared)
        .environment(AppSettings.shared)
}