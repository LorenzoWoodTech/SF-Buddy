//
//  AppSettings.swift
//  SF Buddy
//
//  Created by Alex Carmack on CurrentDate // TO DO: Replace with actual date
//

import SwiftUI
import Combine

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private static let userDefaultsShowInMenuBarKey = "ShowInMenuBar"
    private static let userDefaultsSymbolCountKey = "SymbolCount"
    private static let userDefaultsSelectedModelKey = "SelectedModel"
    private static let userDefaultsVegasAnimationSpeedKey = "VegasAnimationSpeed"
    private static let userDefaultsVegasColorCycleSpeedKey = "VegasColorCycleSpeed"
    private static let userDefaultsVegasIntensityKey = "VegasIntensity"
    private static let userDefaultsVegasRotationEnabledKey = "VegasRotationEnabled"

    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            // Post a notification so AppDelegate can react
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }
    
    @Published var symbolCount: Int {
        didSet {
            UserDefaults.standard.set(symbolCount, forKey: AppSettings.userDefaultsSymbolCountKey)
            print("[AppSettings] SymbolCount setting changed to: \(symbolCount) and saved.")
        }
    }
    
    @Published var selectedModel: ClaudeModel {
        didSet {
            UserDefaults.standard.set(selectedModel.rawValue, forKey: AppSettings.userDefaultsSelectedModelKey)
            print("[AppSettings] SelectedModel setting changed to: \(selectedModel.displayName) and saved.")
        }
    }
    
    @Published var vegasAnimationSpeed: Double {
        didSet {
            UserDefaults.standard.set(vegasAnimationSpeed, forKey: AppSettings.userDefaultsVegasAnimationSpeedKey)
            print("[AppSettings] VegasAnimationSpeed setting changed to: \(vegasAnimationSpeed) and saved.")
        }
    }
    
    @Published var vegasColorCycleSpeed: Double {
        didSet {
            UserDefaults.standard.set(vegasColorCycleSpeed, forKey: AppSettings.userDefaultsVegasColorCycleSpeedKey)
            print("[AppSettings] VegasColorCycleSpeed setting changed to: \(vegasColorCycleSpeed) and saved.")
        }
    }
    
    @Published var vegasIntensity: Double {
        didSet {
            UserDefaults.standard.set(vegasIntensity, forKey: AppSettings.userDefaultsVegasIntensityKey)
            print("[AppSettings] VegasIntensity setting changed to: \(vegasIntensity) and saved.")
        }
    }
    
    @Published var vegasRotationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(vegasRotationEnabled, forKey: AppSettings.userDefaultsVegasRotationEnabledKey)
            print("[AppSettings] VegasRotationEnabled setting changed to: \(vegasRotationEnabled) and saved.")
        }
    }

    private init() {
        self.showInMenuBar = UserDefaults.standard.object(forKey: AppSettings.userDefaultsShowInMenuBarKey) as? Bool ?? true
        self.symbolCount = UserDefaults.standard.object(forKey: AppSettings.userDefaultsSymbolCountKey) as? Int ?? 12
        let modelRawValue = UserDefaults.standard.string(forKey: AppSettings.userDefaultsSelectedModelKey) ?? ClaudeModel.sonnet.rawValue
        self.selectedModel = ClaudeModel(rawValue: modelRawValue) ?? .sonnet
        self.vegasAnimationSpeed = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasAnimationSpeedKey) as? Double ?? 1.0
        self.vegasColorCycleSpeed = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasColorCycleSpeedKey) as? Double ?? 1.0
        self.vegasIntensity = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasIntensityKey) as? Double ?? 1.0
        self.vegasRotationEnabled = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasRotationEnabledKey) as? Bool ?? true
        print("[AppSettings] Initialized. ShowInMenuBar: \(self.showInMenuBar), SymbolCount: \(self.symbolCount), SelectedModel: \(self.selectedModel.displayName), VegasAnimationSpeed: \(self.vegasAnimationSpeed), VegasColorCycleSpeed: \(self.vegasColorCycleSpeed), VegasIntensity: \(self.vegasIntensity), VegasRotationEnabled: \(self.vegasRotationEnabled)")
    }
}

enum ClaudeModel: String, CaseIterable, Identifiable {
    case sonnet = "claude-3-5-sonnet-20240620"
    case opus = "claude-3-opus-20240229"
    case claude4 = "claude-4-20241120"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sonnet: return "Claude 3.5 Sonnet"
        case .opus: return "Claude 3 Opus"
        case .claude4: return "Claude 4"
        }
    }
    
    var description: String {
        switch self {
        case .sonnet: return "Fast and intelligent (recommended)"
        case .opus: return "Most capable, slower"
        case .claude4: return "Latest and most advanced (experimental)"
        }
    }
}

extension Notification.Name {
    static let appSettingShowInMenuBarChanged = Notification.Name("appSettingShowInMenuBarChanged")
}
