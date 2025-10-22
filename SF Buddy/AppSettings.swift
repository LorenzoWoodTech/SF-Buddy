//
//  AppSettings.swift
//  SF Buddy
//
//  Bridge to package settings with app-specific additions
//

import SwiftUI
import SF_Buddy_Package

@Observable
@MainActor
class AppSettings {
    static let shared = AppSettings()

    private static let userDefaultsShowInMenuBarKey = "ShowInMenuBar"

    var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            // Post a notification so AppDelegate can react
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }
    
    // Bridge to package settings
    var symbolCount: Int {
        get { SFSymbolPackageSettings.shared.symbolCount }
        set { SFSymbolPackageSettings.shared.symbolCount = newValue }
    }
    
    var selectedModel: ClaudeModel {
        get { SFSymbolPackageSettings.shared.selectedModel }
        set { SFSymbolPackageSettings.shared.selectedModel = newValue }
    }
    
    // Bridge to vegas settings
    var vegasAnimationSpeed: Double {
        get { SFSymbolVegasSettings.shared.vegasAnimationSpeed }
        set { SFSymbolVegasSettings.shared.vegasAnimationSpeed = newValue }
    }
    
    var vegasColorCycleSpeed: Double {
        get { SFSymbolVegasSettings.shared.vegasColorCycleSpeed }
        set { SFSymbolVegasSettings.shared.vegasColorCycleSpeed = newValue }
    }
    
    var vegasIntensity: Double {
        get { SFSymbolVegasSettings.shared.vegasIntensity }
        set { SFSymbolVegasSettings.shared.vegasIntensity = newValue }
    }
    
    var vegasRotationEnabled: Bool {
        get { SFSymbolVegasSettings.shared.vegasRotationEnabled }
        set { SFSymbolVegasSettings.shared.vegasRotationEnabled = newValue }
    }

    var vegasRandomnessLevel: Double {
        get { SFSymbolVegasSettings.shared.vegasRandomnessLevel }
        set { SFSymbolVegasSettings.shared.vegasRandomnessLevel = newValue }
    }
    
    var vegasScaleIntensity: Double {
        get { SFSymbolVegasSettings.shared.vegasScaleIntensity }
        set { SFSymbolVegasSettings.shared.vegasScaleIntensity = newValue }
    }
    
    var vegasMovementIntensity: Double {
        get { SFSymbolVegasSettings.shared.vegasMovementIntensity }
        set { SFSymbolVegasSettings.shared.vegasMovementIntensity = newValue }
    }
    
    var vegasChaosMode: Bool = false {
        didSet {
            UserDefaults.standard.set(vegasChaosMode, forKey: "VegasChaosMode")
        }
    }

    func triggerVegasChaos() {
        SFSymbolVegasSettings.shared.triggerVegasChaos()
        vegasChaosMode.toggle()
        // Briefly enable chaos mode to trigger randomization in animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.vegasChaosMode.toggle()
        }
    }

    func randomizeVegas() {
        SFSymbolVegasSettings.shared.randomizeVegas()
    }

    private init() {
        self.showInMenuBar = UserDefaults.standard.object(forKey: AppSettings.userDefaultsShowInMenuBarKey) as? Bool ?? true
        self.vegasChaosMode = UserDefaults.standard.object(forKey: "VegasChaosMode") as? Bool ?? false
        
        print("[AppSettings] Initialized as bridge to package settings with @Observable")
    }
}

extension Notification.Name {
    static let appSettingShowInMenuBarChanged = Notification.Name("appSettingShowInMenuBarChanged")
    static let showSymbolPicker = Notification.Name("showSymbolPicker")
}