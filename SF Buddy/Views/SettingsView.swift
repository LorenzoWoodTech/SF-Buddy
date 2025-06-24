//
//  SettingsView.swift
//  SF Buddy
//
//  Simple settings following HIG guidelines
//

import SwiftUI

struct SettingsView: View {
    @Environment(SFSymbolService.self) private var symbolService
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var bindableSymbolService = symbolService
        @Bindable var bindableAppSettings = appSettings
        Form {
            Section("AI Search") {
                SecureField("API Key", text: $bindableSymbolService.claudeAPIKey)
                
                Picker("Results", selection: $bindableAppSettings.symbolCount) {
                    ForEach([8, 12, 16, 20, 24], id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.menu)
            }
            
            #if os(macOS)
            Section("Appearance") {
                Toggle("Show in Menu Bar", isOn: $bindableAppSettings.showInMenuBar)
            }
            #endif
            
            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        #if os(macOS)
        .frame(minWidth: 500, idealWidth: 600, minHeight: 400, idealHeight: 500)
        #endif
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(SFSymbolService.shared)
    .environment(AppSettings.shared)
}
