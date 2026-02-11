//
//  SettingsView.swift
//  SF Buddy
//
//  Settings interface for configuring the app
//

import SwiftUI
import SFBuddyKit

public struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var symbolService = SFBuddyKit.SFSymbolService.shared
    @State private var isTestingAPIKey = false
    @State private var apiKeyStatus: APIKeyStatus = .untested
    @State private var apiKeyError: String?
    
    enum APIKeyStatus {
        case untested
        case valid
        case invalid
        case testing
    }
    
    public init() {}
    
    public var body: some View {
        @Bindable var appSettings = appSettings
        
        NavigationStack {
            Form {
                // AI Provider Selection
                Section {
                    Picker("AI Provider", selection: $appSettings.modelProvider) {
                        ForEach(ModelProvider.allCases) { provider in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.displayName)
                                    .font(.body)
                                Text(provider.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(provider)
                        }
                    }
                    .pickerStyle(.inline)
                    .onChange(of: appSettings.modelProvider) { _, _ in
                        apiKeyStatus = .untested
                        apiKeyError = nil
                    }
                    
                    if appSettings.modelProvider == .apple {
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 4) {
                                if symbolService.isAppleIntelligenceAvailable() {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                Text(symbolService.appleIntelligenceStatusMessage())
                                    .foregroundStyle(symbolService.isAppleIntelligenceAvailable() ? .green : .secondary)
                            }
                        }
                    }
                } header: {
                    Text("AI Provider")
                } footer: {
                    if appSettings.modelProvider == .apple {
                        if symbolService.isAppleIntelligenceAvailable() {
                            Text("Using Apple's on-device intelligence. No API key needed. Private and secure.")
                        } else {
                            Text("Apple Intelligence is not available. \(symbolService.appleIntelligenceStatusMessage()). Will fall back to Claude API if configured, or mock data.")
                        }
                    } else {
                        Text("Using Claude API. Requires Anthropic API key.")
                    }
                }
                
                // API Settings (only show for Claude)
                if appSettings.modelProvider == .claude {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SecureField("Anthropic API Key", text: $symbolService.claudeAPIKey)
                                    .onChange(of: symbolService.claudeAPIKey) { _, _ in
                                        apiKeyStatus = .untested
                                        apiKeyError = nil
                                    }
                                
                                Button {
                                    testAPIKey()
                                } label: {
                                    if isTestingAPIKey {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Test")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(symbolService.claudeAPIKey.isEmpty || isTestingAPIKey)
                            }
                            
                            // Status indicator
                            switch apiKeyStatus {
                            case .untested:
                                if !symbolService.claudeAPIKey.isEmpty {
                                    Label("API key not tested", systemImage: "questionmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            case .testing:
                                Label("Testing API key...", systemImage: "ellipsis.circle")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            case .valid:
                                Label("API key is valid", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            case .invalid:
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("API key is invalid", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                    if let error = apiKeyError {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Picker("AI Model", selection: $appSettings.selectedModel) {
                            ForEach(ClaudeModel.allCases) { model in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.displayName)
                                        .font(.body)
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(model)
                            }
                        }
                        
                        Link("Get API Key from Anthropic", 
                             destination: URL(string: "https://console.anthropic.com/account/keys")!)
                            .font(.caption)
                    } header: {
                        Text("Claude API Settings")
                    } footer: {
                        Text("Create an API key at console.anthropic.com. Click 'Test' to verify your key.")
                    }
                }
                
                // Symbol Count (common to both)
                Section {
                    Stepper("Symbol Count: \(appSettings.symbolCount)", 
                           value: $appSettings.symbolCount, 
                           in: 4...20, 
                           step: 4)
                } header: {
                    Text("Results")
                } footer: {
                    Text("Number of symbol suggestions to generate")
                }
                
                #if os(macOS)
                // macOS-specific settings
                Section {
                    Toggle("Show in Menu Bar", isOn: $appSettings.showInMenuBar)
                } header: {
                    Text("macOS")
                } footer: {
                    Text("Access SF Buddy from the menu bar for quick symbol lookups")
                }
                #endif
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("SFBuddyKit on GitHub", 
                         destination: URL(string: "https://github.com/")!)
                } header: {
                    Text("About")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func testAPIKey() {
        guard !symbolService.claudeAPIKey.isEmpty else { return }
        
        apiKeyStatus = .testing
        isTestingAPIKey = true
        apiKeyError = nil
        
        Task {
            do {
                // Make a minimal test request to Claude
                let result = try await testClaudeAPIKey()
                
                await MainActor.run {
                    if result {
                        apiKeyStatus = .valid
                        symbolService.currentError = .none
                    } else {
                        apiKeyStatus = .invalid
                        apiKeyError = "Invalid response from API"
                    }
                    isTestingAPIKey = false
                }
            } catch {
                await MainActor.run {
                    apiKeyStatus = .invalid
                    
                    // Parse error message
                    if let apiError = error as? TestAPIError {
                        switch apiError {
                        case .authenticationError:
                            apiKeyError = "Authentication failed. Check your API key."
                        case .networkError(let message):
                            apiKeyError = message
                        case .unknownError(let message):
                            apiKeyError = message
                        }
                    } else {
                        apiKeyError = error.localizedDescription
                    }
                    
                    isTestingAPIKey = false
                }
            }
        }
    }
    
    private func testClaudeAPIKey() async throws -> Bool {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw TestAPIError.networkError("Invalid URL")
        }
        
        let appSettings = AppSettings.shared
        
        // Minimal test request
        let requestBody: [String: Any] = [
            "model": appSettings.selectedModel.rawValue,
            "max_tokens": 10,
            "messages": [
                [
                    "role": "user",
                    "content": "test"
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(symbolService.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TestAPIError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw TestAPIError.authenticationError
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TestAPIError.unknownError("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
    }
}

enum TestAPIError: Error {
    case authenticationError
    case networkError(String)
    case unknownError(String)
}

#Preview {
    SettingsView()
        .environment(AppSettings.shared)
        .environment(SFSymbolPackageSettings.shared)
}