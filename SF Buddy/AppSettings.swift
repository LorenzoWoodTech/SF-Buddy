//
//  AppSettings.swift
//  SF Buddy
//
//  Created by Alex Carmack on CurrentDate // TO DO: Replace with actual date
//

import SwiftUI
import Combine
import Observation

@Observable
@MainActor
class AppSettings {
    static let shared = AppSettings()

    private static let userDefaultsShowInMenuBarKey = "ShowInMenuBar"
    private static let userDefaultsSymbolCountKey = "SymbolCount"
    private static let userDefaultsSelectedModelKey = "SelectedModel"
    private static let userDefaultsVegasAnimationSpeedKey = "VegasAnimationSpeed"
    private static let userDefaultsVegasColorCycleSpeedKey = "VegasColorCycleSpeed"
    private static let userDefaultsVegasIntensityKey = "VegasIntensity"
    private static let userDefaultsVegasRotationEnabledKey = "VegasRotationEnabled"

    var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            // Post a notification so AppDelegate can react
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }
    
    var symbolCount: Int {
        didSet {
            UserDefaults.standard.set(symbolCount, forKey: AppSettings.userDefaultsSymbolCountKey)
            print("[AppSettings] SymbolCount setting changed to: \(symbolCount) and saved.")
        }
    }
    
    var selectedModel: ClaudeModel {
        didSet {
            UserDefaults.standard.set(selectedModel.rawValue, forKey: AppSettings.userDefaultsSelectedModelKey)
            print("[AppSettings] SelectedModel setting changed to: \(selectedModel.displayName) and saved.")
        }
    }
    
    var vegasAnimationSpeed: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(vegasAnimationSpeed, forKey: AppSettings.userDefaultsVegasAnimationSpeedKey)
            print("[AppSettings] VegasAnimationSpeed setting changed to: \(vegasAnimationSpeed) and saved.")
        }
    }
    
    var vegasColorCycleSpeed: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(vegasColorCycleSpeed, forKey: AppSettings.userDefaultsVegasColorCycleSpeedKey)
            print("[AppSettings] VegasColorCycleSpeed setting changed to: \(vegasColorCycleSpeed) and saved.")
        }
    }
    
    var vegasIntensity: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(vegasIntensity, forKey: AppSettings.userDefaultsVegasIntensityKey)
            print("[AppSettings] VegasIntensity setting changed to: \(vegasIntensity) and saved.")
        }
    }
    
    var vegasRotationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(vegasRotationEnabled, forKey: AppSettings.userDefaultsVegasRotationEnabledKey)
            print("[AppSettings] VegasRotationEnabled setting changed to: \(vegasRotationEnabled) and saved.")
        }
    }

    var vegasRandomnessLevel: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(vegasRandomnessLevel, forKey: "VegasRandomnessLevel")
        }
    }
    
    var vegasScaleIntensity: Double = 0.3 {
        didSet {
            UserDefaults.standard.set(vegasScaleIntensity, forKey: "VegasScaleIntensity")
        }
    }
    
    var vegasMovementIntensity: Double = 5.0 {
        didSet {
            UserDefaults.standard.set(vegasMovementIntensity, forKey: "VegasMovementIntensity")
        }
    }
    
    var vegasChaosMode: Bool = false {
        didSet {
            UserDefaults.standard.set(vegasChaosMode, forKey: "VegasChaosMode")
        }
    }

    func triggerVegasChaos() {
        vegasChaosMode.toggle()
        // Briefly enable chaos mode to trigger randomization in animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.vegasChaosMode.toggle()
        }
    }

    func randomizeVegas() {
        vegasAnimationSpeed = Double.random(in: 0.2...5.0)
        vegasColorCycleSpeed = Double.random(in: 0.2...5.0)
        vegasIntensity = Double.random(in: 0.3...2.0)
        vegasRandomnessLevel = Double.random(in: 0.0...1.0)
        vegasScaleIntensity = Double.random(in: 0.1...1.0)
        vegasMovementIntensity = Double.random(in: 1.0...15.0)
        vegasRotationEnabled = Bool.random()
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
        
        self.vegasRandomnessLevel = UserDefaults.standard.object(forKey: "VegasRandomnessLevel") as? Double ?? 0.5
        self.vegasScaleIntensity = UserDefaults.standard.object(forKey: "VegasScaleIntensity") as? Double ?? 0.3
        self.vegasMovementIntensity = UserDefaults.standard.object(forKey: "VegasMovementIntensity") as? Double ?? 5.0
        self.vegasChaosMode = UserDefaults.standard.object(forKey: "VegasChaosMode") as? Bool ?? false
        
        print("[AppSettings] Initialized with Vegas controls")
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
