//
//  SF_BuddyApp.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI
import AppKit

@main
struct SF_BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        print("[SF_BuddyApp] App struct initializing.")
    }
    
    var body: some Scene {
        // Hide the default window - we only want menu bar
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var keyboardShortcutManager: KeyboardShortcutManager?
    
    override init() {
        super.init()
        print("[AppDelegate] Initializing.")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching started.")
        
        // Check for accessibility permissions
        checkAccessibilityPermissions()
        print("[AppDelegate] Accessibility check done.")
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("[AppDelegate] Status item created.")
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass.circle", accessibilityDescription: "SF Buddy")
            button.action = #selector(togglePopover)
            button.target = self
            print("[AppDelegate] Status item button configured.")
        }
        
        // Setup global keyboard shortcut (Ctrl+Option+Cmd+Space)
        keyboardShortcutManager = KeyboardShortcutManager()
        keyboardShortcutManager?.setupGlobalShortcut()
        print("[AppDelegate] Keyboard shortcut manager setup.")
        
        // Hide dock icon and keep app running in background
        // This should ideally be redundant if LSUIElement is true in Info.plist,
        // but it doesn't hurt to keep it.
        NSApplication.shared.setActivationPolicy(.accessory)
        print("[AppDelegate] Activation policy set to .accessory.")

        NotificationCenter.default.addObserver(self, selector: #selector(handleShowSymbolPicker), name: .showSymbolPicker, object: nil)
        print("[AppDelegate] Notification observer added.")
        
        print("[AppDelegate] applicationDidFinishLaunching finished.")
    }
    
    @objc func togglePopover() {
        print("[AppDelegate] togglePopover called.")
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
                popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SFSymbolService.shared))
                popover?.behavior = .transient
            }
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
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

    @objc private func handleShowSymbolPicker() {
        print("[AppDelegate] handleShowSymbolPicker called.")
        DispatchQueue.main.async {
            print("[AppDelegate] handleShowSymbolPicker on main thread.")
            guard let button = self.statusItem?.button else {
                print("[AppDelegate] handleShowSymbolPicker: Status item button not found.")
                return
            }
            
            if self.popover == nil {
                print("[AppDelegate] handleShowSymbolPicker: Creating new popover.")
                self.popover = NSPopover()
                self.popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SFSymbolService.shared))
                self.popover?.behavior = .transient
            }

            if !(self.popover?.isShown ?? false) {
                 print("[AppDelegate] handleShowSymbolPicker: Showing popover.")
                 self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            } else {
                print("[AppDelegate] handleShowSymbolPicker: Popover already shown.")
            }
            self.popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            print("[AppDelegate] handleShowSymbolPicker: Popover brought to front.")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[AppDelegate] applicationWillTerminate called.")
        NotificationCenter.default.removeObserver(self, name: .showSymbolPicker, object: nil)
    }
}
