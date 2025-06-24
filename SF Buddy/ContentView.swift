//
//  ContentView.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettingsSheet = false
    @State private var showingIconRegistry = false
    @Environment(SFSymbolService.self) private var symbolService

    var body: some View {
        Group {
            if showingIconRegistry {
                IconRegistryPreview()
            } else {
                SearchView(showingSettingsSheet: $showingSettingsSheet)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .frame(minWidth: 380, idealWidth: 400, maxWidth: 450, minHeight: 500, idealHeight: 650, maxHeight: 800)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(minWidth: 320, idealWidth: 380, maxWidth: 420, minHeight: 400, idealHeight: 600, maxHeight: 750)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(showingIconRegistry ? "Back to Search" : "Icon Registry") {
                    showingIconRegistry.toggle()
                }
            }
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @Binding var showingSettingsSheet: Bool
    @Environment(SFSymbolService.self) private var symbolService

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                HStack {
                    Spacer()
                    Text("SF Buddy")
                        .font(.headline)
                    Spacer()
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing)
                }
            }
            .padding(.top)

            if symbolService.claudeAPIKey.isEmpty && !symbolService.isProcessing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude API Key Required:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        @Bindable var bindableSymbolService = symbolService
                        SecureField("Enter your Anthropic API Key...", text: $bindableSymbolService.claudeAPIKey)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    Link("Get an API Key from Anthropic", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                        .font(.caption)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for symbols...", text: $searchText)
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
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            if symbolService.isProcessing {
                VStack(spacing: 16) {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3 + Double(index) * 0.5) * 0.3)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
                        }
                    }
                    
                    Text("Finding magical symbols...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.7 + sin(Date().timeIntervalSince1970 * 2) * 0.3)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
                }
                .padding()
            } else if symbolService.apiKeyMissingOrInvalid && !symbolService.claudeAPIKey.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Claude API Key Invalid or Issue")
                        .font(.headline)
                    Text("There was an issue with your API key or the service. Please check your key and internet connection. You can update your key in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    if !symbolService.lastProcessedText.isEmpty && symbolService.suggestedSymbols.isEmpty && symbolService.invalidSymbolNamesFromClaude.isEmpty {
                        Text("Tried for: \"\(symbolService.lastProcessedText)\"")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            } else if !symbolService.suggestedSymbols.isEmpty || !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                SymbolPickerView()
            } else if !searchText.isEmpty && symbolService.suggestedSymbols.isEmpty && symbolService.invalidSymbolNamesFromClaude.isEmpty && !symbolService.apiKeyMissingOrInvalid && !symbolService.claudeAPIKey.isEmpty {
                Text("No symbols found for \"\(searchText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else if symbolService.claudeAPIKey.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "key.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text("API Key Needed")
                        .font(.headline)
                    Text("Please enter your Anthropic API key above to start finding symbols.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    Text("Ready to Find Symbols")
                        .font(.headline)
                    Text("Enter text in the search bar above, or press ⌃⌥⌘Space to find symbols for selected text in other apps.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            Spacer()
        }
    }
}

struct IconRegistryPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "cylinder.split.1x2.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SFBuddy Icon Registry")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Comprehensive icon management system")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Feature Overview
            VStack(spacing: 16) {
                Text("Building the Future of Icon Management")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Following the detailed plan, we're implementing a comprehensive multiplatform app with Core Data, code generation, and seamless SF Symbol integration.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(iconName: "cylinder.split.1x2", title: "Core Data Architecture", description: "Icon, Variant & Tag entities with CloudKit support", status: "✅ Complete")
                    
                    FeatureItem(iconName: "magnifyingglass", title: "Multiplatform UI", description: "NavigationSplitView for macOS/iPad, NavigationStack for iPhone", status: "🔨 In Progress")
                    
                    FeatureItem(iconName: "square.and.arrow.up", title: "Code Generation", description: "Automatic IconRegistry.generated.swift creation", status: "📋 Planned")
                    
                    FeatureItem(iconName: "gear", title: "Advanced Features", description: "Variants, tags, validation & HIG compliance", status: "📋 Planned")
                }
                
                Divider()
                
                Text("Current implementation provides symbol search while the full registry is being developed step-by-step according to PLAN.md")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureItem: View {
    let iconName: String
    let title: String
    let description: String
    let status: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2), in: Capsule())
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environment(SFSymbolService.shared)
        .environment(AppSettings.shared)
}
