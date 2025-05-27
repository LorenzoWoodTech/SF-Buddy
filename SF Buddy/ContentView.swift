//
//  ContentView.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettingsSheet = false
    @StateObject private var symbolService = SFSymbolService.shared

    var body: some View {
        SearchView(showingSettingsSheet: $showingSettingsSheet)
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
                    .environmentObject(SFSymbolService.shared)
                    .environmentObject(AppSettings.shared)
                    .frame(minWidth: 380, idealWidth: 400, maxWidth: 450, minHeight: 300, idealHeight: 350, maxHeight: 450)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .frame(minWidth: 380, idealWidth: 450, maxWidth: 500, minHeight: 400, idealHeight: 600, maxHeight: 750)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SearchView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var searchText = ""
    @Binding var showingSettingsSheet: Bool

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
                        SecureField("Enter your Anthropic API Key...", text: $symbolService.claudeAPIKey)
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
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding SF Symbols...")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

struct SettingsView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Claude API Key")
                    .font(.headline)
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(symbolService.claudeAPIKey.isEmpty ? .orange : .secondary)
                    SecureField("Enter your Anthropic API Key...", text: $symbolService.claudeAPIKey)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                if symbolService.claudeAPIKey.isEmpty {
                    Text("An API key is required to suggest symbols.")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.leading, 4)
                }
                Link("Get an API Key from Anthropic", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                    .font(.caption)
                    .padding(.top, 2)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(.headline)
                Toggle("Show in Menu Bar", isOn: $appSettings.showInMenuBar)
                    .padding(.vertical, 4)
                Text("If hidden, a Dock icon will appear. You may need to re-launch if both are hidden to access settings.")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
    }
}

struct SymbolPickerView: View {
    @StateObject private var symbolService = SFSymbolService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Picker("Rendering Mode", selection: $symbolService.currentRenderingMode) {
                        ForEach(SFSymbolRenderingMode.allCases) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .font(.caption2)
                    Spacer()
                }
                .padding(.horizontal)

                HStack {
                    Text("Symbols for:")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(symbolService.lastProcessedText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if !symbolService.suggestedSymbols.isEmpty {
                    ViewThatFits(in: .horizontal) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 70, maximum: 90), spacing: 12), count: 4), spacing: 12) {
                            ForEach(symbolService.suggestedSymbols) { suggestion in
                                SymbolButton(suggestion: suggestion)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 70, maximum: 90), spacing: 12), count: 3), spacing: 12) {
                            ForEach(symbolService.suggestedSymbols) { suggestion in
                                SymbolButton(suggestion: suggestion)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 70, maximum: 90), spacing: 12), count: 2), spacing: 12) {
                            ForEach(symbolService.suggestedSymbols) { suggestion in
                                SymbolButton(suggestion: suggestion)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)
                    }
                } else if symbolService.suggestedSymbols.isEmpty && !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                    Text("All suggested symbols appear to be invalid or non-existent.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                } else if symbolService.suggestedSymbols.isEmpty && symbolService.apiKeyMissingOrInvalid && !symbolService.lastProcessedText.isEmpty {
                }

                if !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Warning: \(symbolService.invalidSymbolNamesFromClaude.count) suggested symbol name(s) might not exist or are invalid:")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text(symbolService.invalidSymbolNamesFromClaude.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                            .padding(.leading, 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                HStack {
                    Spacer()
                    Button("Clear Results") {
                        symbolService.suggestedSymbols = []
                        symbolService.lastProcessedText = ""
                        symbolService.invalidSymbolNamesFromClaude = []
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct SymbolButton: View {
    let suggestion: SFSymbolSuggestion
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var isHovered = false
    @State private var justCopied = false

    var body: some View {
        VStack(spacing: 4) {
            if justCopied {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
                Text("Copied!")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Image(systemName: suggestion.name)
                    .font(.system(size: 20))
                    .foregroundColor(isHovered ? .white : .primary)
                    .symbolRenderingMode(symbolRenderingMode)
                    .frame(width: 32, height: 32)

                Text(suggestion.name)
                    .font(.caption2)
                    .foregroundColor(isHovered ? .white : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(minWidth: 70, maxWidth: 90, minHeight: 70, maxHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered && !justCopied ? Color.accentColor : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            if !justCopied {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .onTapGesture {
            if !justCopied {
                symbolService.replaceTextWithSymbol(suggestion.name)
                withAnimation {
                    justCopied = true
                }

                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run {
                        withAnimation {
                            justCopied = false
                        }
                        if let delegate = NSApplication.shared.delegate as? AppDelegate {
                            delegate.popover?.performClose(nil)
                        }
                    }
                }
            }
        }
        .draggable(suggestion.name) {
            VStack(spacing: 2) {
                Image(systemName: suggestion.name)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Text(suggestion.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private var symbolRenderingMode: SymbolRenderingMode {
        switch symbolService.currentRenderingMode {
        case .monochrome:
            return .monochrome
        case .hierarchical:
            return .hierarchical
        case .palette:
            return .palette
        case .multicolor:
            return .multicolor
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SFSymbolService.shared)
        .environmentObject(AppSettings.shared)
}
