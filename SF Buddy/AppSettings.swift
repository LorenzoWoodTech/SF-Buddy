//
//  AppSettings.swift
//  SF Buddy
//
//  App-specific settings with bridge to package settings
//

import SwiftUI
import SFBuddyKit

@Observable
@MainActor
class AppSettings {
    static let shared = AppSettings()

    private static let userDefaultsShowInMenuBarKey = "ShowInMenuBar"
    private static let vegasChaosModeLKey = "VegasChaosMode"

    var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            // Post a notification so AppDelegate can react
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }
    
    // Bridge to package settings for Claude AI
    var symbolCount: Int {
        get { SFSymbolPackageSettings.shared.symbolCount }
        set { SFSymbolPackageSettings.shared.symbolCount = newValue }
    }
    
    var selectedModel: ClaudeModel {
        get { SFSymbolPackageSettings.shared.selectedModel }
        set { SFSymbolPackageSettings.shared.selectedModel = newValue }
    }
    
    var modelProvider: ModelProvider {
        get { SFSymbolPackageSettings.shared.modelProvider }
        set { SFSymbolPackageSettings.shared.modelProvider = newValue }
    }
    
    // Bridge to package Vegas settings
    var vegasAnimationSpeed: Double {
        get { VegasSettings.shared.vegasAnimationSpeed }
        set { VegasSettings.shared.vegasAnimationSpeed = newValue }
    }
    
    var vegasColorCycleSpeed: Double {
        get { VegasSettings.shared.vegasColorCycleSpeed }
        set { VegasSettings.shared.vegasColorCycleSpeed = newValue }
    }
    
    var vegasIntensity: Double {
        get { VegasSettings.shared.vegasIntensity }
        set { VegasSettings.shared.vegasIntensity = newValue }
    }
    
    var vegasRotationEnabled: Bool {
        get { VegasSettings.shared.vegasRotationEnabled }
        set { VegasSettings.shared.vegasRotationEnabled = newValue }
    }

    var vegasRandomnessLevel: Double {
        get { VegasSettings.shared.vegasRandomnessLevel }
        set { VegasSettings.shared.vegasRandomnessLevel = newValue }
    }
    
    var vegasScaleIntensity: Double {
        get { VegasSettings.shared.vegasScaleIntensity }
        set { VegasSettings.shared.vegasScaleIntensity = newValue }
    }
    
    var vegasMovementIntensity: Double {
        get { VegasSettings.shared.vegasMovementIntensity }
        set { VegasSettings.shared.vegasMovementIntensity = newValue }
    }
    
    var vegasChaosMode: Bool {
        didSet {
            UserDefaults.standard.set(vegasChaosMode, forKey: AppSettings.vegasChaosModeLKey)
        }
    }

    func triggerVegasChaos() {
        VegasSettings.shared.triggerVegasChaos()
        vegasChaosMode.toggle()
        // Briefly enable chaos mode to trigger randomization in animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.vegasChaosMode.toggle()
        }
    }

    func randomizeVegas() {
        VegasSettings.shared.randomizeVegas()
    }

    private init() {
        self.showInMenuBar = UserDefaults.standard.object(forKey: AppSettings.userDefaultsShowInMenuBarKey) as? Bool ?? true
        self.vegasChaosMode = UserDefaults.standard.object(forKey: AppSettings.vegasChaosModeLKey) as? Bool ?? false
        
        print("[AppSettings] Initialized as bridge to SFBuddyKit package settings")
    }
}

extension Notification.Name {
    static let appSettingShowInMenuBarChanged = Notification.Name("appSettingShowInMenuBarChanged")
    static let showSymbolPicker = Notification.Name("showSymbolPicker")
}