//
//  SettingsView.swift
//  SF Buddy
//
//  Settings view for configuring app preferences
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
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
                    Text("AI Model")
                        .font(.headline)
                    VStack(spacing: 6) {
                        ForEach(ClaudeModel.allCases) { model in
                            Button {
                                appSettings.selectedModel = model
                            } label: {
                                HStack {
                                    Image(systemName: appSettings.selectedModel == model ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(appSettings.selectedModel == model ? .accentColor : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        Text(model.description)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(appSettings.selectedModel == model ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol Generation")
                        .font(.headline)
                    HStack {
                        Text("Number of symbols:")
                            .font(.caption)
                        Spacer()
                        Picker("Symbol Count", selection: $appSettings.symbolCount) {
                            ForEach([8, 12, 16, 20, 24], id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                    Text("Choose how many symbols to generate for each search.")
                        .font(.caption2)
                        .foregroundColor(.gray)
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

                Spacer(minLength: 20)
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SFSymbolService.shared)
        .environmentObject(AppSettings.shared)
}