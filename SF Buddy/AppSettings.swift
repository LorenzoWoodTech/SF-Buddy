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
    private static let userDefaultsVegasChaosModeKey = "VegasChaosMode"
    private static let userDefaultsVegasModeKey = "VegasMode"
    private static let userDefaultsSymbolSizeKey = "SymbolSize"
    private static let userDefaultsVegasScaleIntensityKey = "VegasScaleIntensity"
    private static let userDefaultsVegasMovementIntensityKey = "VegasMovementIntensity"
    private static let userDefaultsVegasAnimationSpeedKey = "VegasAnimationSpeed"
    private static let userDefaultsVegasIntensityKey = "VegasIntensity" 
    private static let userDefaultsVegasRotationEnabledKey = "VegasRotationEnabled"

    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }

    @Published var vegasChaosMode: Bool = false {
        didSet {
            UserDefaults.standard.set(vegasChaosMode, forKey: AppSettings.userDefaultsVegasChaosModeKey)
        }
    }

    @Published var vegasMode: Bool = false {
        didSet {
            UserDefaults.standard.set(vegasMode, forKey: AppSettings.userDefaultsVegasModeKey)
        }
    }
    
    @Published var symbolSize: SymbolSize = .normal {
        didSet {
            UserDefaults.standard.set(symbolSize.rawValue, forKey: AppSettings.userDefaultsSymbolSizeKey)
        }
    }

    @Published var vegasScaleIntensity: Double = 0.3 {
        didSet {
            UserDefaults.standard.set(vegasScaleIntensity, forKey: AppSettings.userDefaultsVegasScaleIntensityKey)
        }
    }

    @Published var vegasMovementIntensity: Double = 5.0 {
        didSet {
            UserDefaults.standard.set(vegasMovementIntensity, forKey: AppSettings.userDefaultsVegasMovementIntensityKey)
        }
    }

    @Published var vegasAnimationSpeed: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(vegasAnimationSpeed, forKey: AppSettings.userDefaultsVegasAnimationSpeedKey)
        }
    }

    @Published var vegasIntensity: Double = 1.0 { 
        didSet {
            UserDefaults.standard.set(vegasIntensity, forKey: AppSettings.userDefaultsVegasIntensityKey)
        }
    }

    @Published var vegasRotationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(vegasRotationEnabled, forKey: AppSettings.userDefaultsVegasRotationEnabledKey)
        }
    }

    private init() {
        self.vegasScaleIntensity = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasScaleIntensityKey) as? Double ?? 0.3
        self.vegasMovementIntensity = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasMovementIntensityKey) as? Double ?? 5.0
        self.vegasChaosMode = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasChaosModeKey) as? Bool ?? false
        self.vegasMode = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasModeKey) as? Bool ?? false
        let symbolSizeRaw = UserDefaults.standard.string(forKey: AppSettings.userDefaultsSymbolSizeKey) ?? SymbolSize.normal.rawValue
        self.symbolSize = SymbolSize(rawValue: symbolSizeRaw) ?? .normal
        
        self.vegasAnimationSpeed = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasAnimationSpeedKey) as? Double ?? 1.0
        self.vegasIntensity = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasIntensityKey) as? Double ?? 1.0
        self.vegasRotationEnabled = UserDefaults.standard.object(forKey: AppSettings.userDefaultsVegasRotationEnabledKey) as? Bool ?? true
        
        self.showInMenuBar = UserDefaults.standard.object(forKey: AppSettings.userDefaultsShowInMenuBarKey) as? Bool ?? true
        print("[AppSettings] Initialized. ShowInMenuBar: \(self.showInMenuBar)")
        print("[AppSettings] Initialized with Vegas controls")
    }

    func triggerVegasChaos() {
        randomizeVegas()
    }

    func randomizeVegas() {
        vegasAnimationSpeed = Double.random(in: 0.2...5.0)
        vegasIntensity = Double.random(in: 0.3...2.0) 
        vegasScaleIntensity = Double.random(in: 0.1...1.0)
        vegasMovementIntensity = Double.random(in: 1.0...15.0)
        vegasRotationEnabled = Bool.random()
        print("[AppSettings] Vegas settings randomized.")
    }
}

extension Notification.Name {
    static let appSettingShowInMenuBarChanged = Notification.Name("appSettingShowInMenuBarChanged")
}
