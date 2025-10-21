//
//  AISymbolSearchView.swift
//  SF Buddy
//
//  Clean AI-powered symbol search interface
//

import SwiftUI

struct AISymbolSearchView: View {
    @Binding var selectedSymbol: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple.gradient)
                    
                    Text("AI Symbol Search")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Describe what you're looking for and get intelligent symbol suggestions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // API Key Setup
                if symbolService.claudeAPIKey.isEmpty {
                    APIKeySetupView()
                        .padding()
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Search Interface
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Describe what you need a symbol for...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                if !searchText.isEmpty {
                                    Task {
                                        await symbolService.searchSymbols(for: searchText)
                                    }
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                symbolService.suggestedSymbols = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    
                    if !searchText.isEmpty && !symbolService.claudeAPIKey.isEmpty {
                        Button {
                            Task {
                                await symbolService.searchSymbols(for: searchText)
                            }
                        } label: {
                            HStack {
                                if symbolService.isProcessing {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(symbolService.isProcessing ? "Searching..." : "Find Symbols")
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(symbolService.isProcessing)
                    }
                }
                
                // Results
                if symbolService.isProcessing {
                    LoadingView()
                } else if !symbolService.suggestedSymbols.isEmpty {
                    SymbolResultsView(selectedSymbol: $selectedSymbol)
                } else if !searchText.isEmpty && !symbolService.isProcessing && symbolService.suggestedSymbols.isEmpty {
                    EmptyResultsView()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct APIKeySetupView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.orange)
                Text("API Key Required")
                    .fontWeight(.medium)
            }
            
            SecureField("Enter your Anthropic API Key", text: $symbolService.claudeAPIKey)
                .textFieldStyle(.roundedBorder)
            
            Link("Get API Key from Anthropic", 
                 destination: URL(string: "https://console.anthropic.com/account/keys")!)
                .font(.caption)
                .foregroundStyle(.blue)
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.purple.gradient)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index) * 0.5) * 0.5)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                }
            }
            
            Text("Finding perfect symbols...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SymbolResultsView: View {
    @Binding var selectedSymbol: String?
    @StateObject private var symbolService = SFSymbolService.shared
    @Environment(\.dismiss) private var dismiss
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(symbolService.suggestedSymbols) { suggestion in
                    Button {
                        selectedSymbol = suggestion.name
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: suggestion.name)
                                .font(.system(size: 24))
                                .foregroundStyle(.primary)
                                .frame(height: 30)
                            
                            Text(suggestion.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(height: 80)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

private struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No symbols found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Try different search terms or be more specific")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    AISymbolSearchView(selectedSymbol: .constant(nil))
        .environmentObject(SFSymbolService.shared)
        .environment(AppSettings.shared)
}