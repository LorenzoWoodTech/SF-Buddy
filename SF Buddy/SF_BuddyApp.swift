//
//  SF_BuddyApp.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI
#if os(macOS)
import AppKit
import Carbon
import Combine
#endif

@main
struct SF_BuddyApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        #if os(macOS)
        // Main app window for macOS - This is now the primary interface
        WindowGroup("SF Buddy") {
            MainContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(SFSymbolService.shared)
                .environmentObject(AppSettings.shared)
        }
        .commands {
            SidebarCommands()
        }
        
        Settings {
            ContentView()
                .environmentObject(SFSymbolService.shared)
                .environmentObject(AppSettings.shared)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        #else
        // iOS/iPadOS: Standard app with main content
        WindowGroup {
            MainContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(SFSymbolService.shared)
                .environmentObject(AppSettings.shared)
        }
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var keyboardShortcutManager: KeyboardShortcutManager?
    private var appSettings = AppSettings.shared
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching started.")
        
        NSApplication.shared.setActivationPolicy(.regular)
        print("[AppDelegate] Activation policy set to .regular for main app.")
        
        checkAccessibilityPermissions()
        print("[AppDelegate] Accessibility check done.")
        
        setupStatusItemIfNeeded()

        appSettings.$showInMenuBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupStatusItemIfNeeded()
            }
            .store(in: &cancellables)
        
        keyboardShortcutManager = KeyboardShortcutManager()
        keyboardShortcutManager?.setupGlobalShortcut()
        print("[AppDelegate] Keyboard shortcut manager setup.")

        NotificationCenter.default.addObserver(self, selector: #selector(handleShowSymbolPicker), name: .showSymbolPicker, object: nil)
        print("[AppDelegate] Notification observer added for showSymbolPicker.")
        
        print("[AppDelegate] applicationDidFinishLaunching finished.")
    }

    @MainActor
    private func setupStatusItemIfNeeded() {
        if appSettings.showInMenuBar {
            if statusItem == nil {
                print("[AppDelegate] Creating status item as per settings.")
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = statusItem?.button {
                    button.image = NSImage(systemSymbolName: "magnifyingglass.circle", accessibilityDescription: "SF Buddy")
                    button.action = #selector(togglePopover)
                    button.target = self
                    print("[AppDelegate] Status item button configured.")
                }
            }
        } else {
            if let item = statusItem {
                print("[AppDelegate] Removing status item as per settings.")
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    @MainActor
    @objc func togglePopover() {
        print("[AppDelegate] togglePopover called.")
        NSApp.activate(ignoringOtherApps: true)

        guard let button = statusItem?.button else {
            print("[AppDelegate] togglePopover: Status item button not found.")
            return
        }
        
        if let popover = popover, popover.isShown {
            print("[AppDelegate] togglePopover: Closing popover.")
            popover.performClose(nil)
        } else {
            print("[AppDelegate] togglePopover: Showing popover.")
            if popover == nil {
                print("[AppDelegate] togglePopover: Creating new popover.")
                popover = NSPopover()
                popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SFSymbolService.shared).environmentObject(AppSettings.shared))
                popover?.behavior = .transient
                popover?.contentSize = NSSize(width: 450, height: 600)
            }
            popover?.contentSize = NSSize(width: 450, height: 600)

            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    private func checkAccessibilityPermissions() {
        print("[AppDelegate] checkAccessibilityPermissions called.")
        let trusted = AXIsProcessTrusted()
        print("[AppDelegate] AXIsProcessTrusted: \(trusted)")
        if !trusted {
            print("[AppDelegate] Accessibility permissions not granted. Requesting...")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            let result = AXIsProcessTrustedWithOptions(options as CFDictionary)
            print("[AppDelegate] AXIsProcessTrustedWithOptions result: \(result)")
        }
    }

    @MainActor
    @objc private func handleShowSymbolPicker() {
        print("[AppDelegate] handleShowSymbolPicker called via keyboard shortcut.")
        NSApp.activate(ignoringOtherApps: true)
        
        if self.appSettings.showInMenuBar, let button = self.statusItem?.button {
            if self.popover == nil {
                print("[AppDelegate] handleShowSymbolPicker: Creating new popover.")
                self.popover = NSPopover()
                self.popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SFSymbolService.shared).environmentObject(AppSettings.shared))
                self.popover?.behavior = .transient
                self.popover?.contentSize = NSSize(width: 450, height: 600)
            }
            self.popover?.contentSize = NSSize(width: 450, height: 600)

            if !(self.popover?.isShown ?? false) {
                print("[AppDelegate] handleShowSymbolPicker: Showing popover.")
                self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
            self.popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        } else {
            // Show main app window
            for window in NSApp.windows {
                if window.title == "SF Buddy" {
                    window.makeKeyAndOrderFront(nil)
                    return
                }
            }
        }
        print("[AppDelegate] handleShowSymbolPicker completed.")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("[AppDelegate] applicationShouldHandleReopen called. HasVisibleWindows: \(flag)")
        if !flag {
            for window in NSApp.windows {
                if window.title == "SF Buddy" {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[AppDelegate] applicationWillTerminate called.")
        NotificationCenter.default.removeObserver(self, name: .showSymbolPicker, object: nil)
        cancellables.forEach { $0.cancel() }
    }
}
#endif
