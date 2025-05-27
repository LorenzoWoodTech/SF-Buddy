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

    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: AppSettings.userDefaultsShowInMenuBarKey)
            print("[AppSettings] ShowInMenuBar setting changed to: \(showInMenuBar) and saved.")
            // Post a notification so AppDelegate can react
            NotificationCenter.default.post(name: .appSettingShowInMenuBarChanged, object: nil)
        }
    }

    private init() {
        // Load the setting or default to true
        self.showInMenuBar = UserDefaults.standard.object(forKey: AppSettings.userDefaultsShowInMenuBarKey) as? Bool ?? true
        print("[AppSettings] Initialized. ShowInMenuBar: \(self.showInMenuBar)")
    }
}

extension Notification.Name {
    static let appSettingShowInMenuBarChanged = Notification.Name("appSettingShowInMenuBarChanged")
}