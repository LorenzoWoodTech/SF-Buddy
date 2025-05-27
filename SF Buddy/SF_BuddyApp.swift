//
//  SF_BuddyApp.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI
import AppKit
import Carbon
import Combine

@main
struct SF_BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
                .environmentObject(SFSymbolService.shared)
                .environmentObject(AppSettings.shared)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var keyboardShortcutManager: KeyboardShortcutManager?
    private var appSettings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching started.")
        
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
        
        if appSettings.showInMenuBar {
            NSApplication.shared.setActivationPolicy(.accessory)
            print("[AppDelegate] Activation policy set to .accessory.")
        } else {
            NSApplication.shared.setActivationPolicy(.regular)
            print("[AppDelegate] Activation policy set to .regular (menu bar icon hidden).")
        }

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
                if NSApp.activationPolicy() != .accessory {
                    NSApp.setActivationPolicy(.accessory)
                    print("[AppDelegate] Set activation policy to .accessory because menu bar icon is now visible.")
                }
            }
        } else {
            if let item = statusItem {
                print("[AppDelegate] Removing status item as per settings.")
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
                if NSApp.activationPolicy() != .regular {
                    NSApp.setActivationPolicy(.regular)
                    print("[AppDelegate] Set activation policy to .regular because menu bar icon is hidden.")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    @MainActor
    @objc func togglePopover() {
        print("[AppDelegate] togglePopover called.")
        NSApp.activate(ignoringOtherApps: true)

        guard let button = statusItem?.button else {
            print("[AppDelegate] togglePopover: Status item button not found (perhaps it's hidden by settings?).")
            if !appSettings.showInMenuBar {
                openUtilityWindow()
            }
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
                popover?.contentSize = NSSize(width: 450, height: 520)
            }
            popover?.contentSize = NSSize(width: 450, height: 520)

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
        
        guard self.appSettings.showInMenuBar, let button = self.statusItem?.button else {
            print("[AppDelegate] handleShowSymbolPicker: Menu bar icon is hidden or not available. Opening utility window instead.")
            openUtilityWindow()
            return
        }
            
        if self.popover == nil {
            print("[AppDelegate] handleShowSymbolPicker: Creating new popover.")
            self.popover = NSPopover()
            self.popover?.contentViewController = NSHostingController(rootView: ContentView().environmentObject(SFSymbolService.shared).environmentObject(AppSettings.shared))
            self.popover?.behavior = .transient
            self.popover?.contentSize = NSSize(width: 450, height: 520)
        }
        self.popover?.contentSize = NSSize(width: 450, height: 520)

        if !(self.popover?.isShown ?? false) {
            print("[AppDelegate] handleShowSymbolPicker: Showing popover.")
            self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        } else {
            print("[AppDelegate] handleShowSymbolPicker: Popover already shown. Ensuring it's key and front.")
        }
        self.popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        print("[AppDelegate] handleShowSymbolPicker: Popover brought to front.")
    }

    @MainActor
    private func openUtilityWindow() {
        print("[AppDelegate] openUtilityWindow called.")
        for window in NSApp.windows {
            if window.identifier?.rawValue == "sfBuddyUtilityWindow" {
                print("[AppDelegate] Utility window already exists, bringing to front.")
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        print("[AppDelegate] Creating new utility window.")
        let contentView = ContentView()
            .environmentObject(SFSymbolService.shared)
            .environmentObject(AppSettings.shared)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("SFBuddyUtilityWindow")
        window.contentView = NSHostingView(rootView: contentView)
        window.title = "SF Buddy"
        window.identifier = NSUserInterfaceItemIdentifier("sfBuddyUtilityWindow")
        window.makeKeyAndOrderFront(nil)
        
        if NSApp.activationPolicy() == .accessory {
            print("[AppDelegate] Temporarily setting activation policy to .regular to show utility window from accessory mode.")
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("[AppDelegate] applicationShouldHandleReopen called. HasVisibleWindows: \(flag)")
        if !flag {
            if appSettings.showInMenuBar, let button = statusItem?.button {
                if popover?.isShown == false {
                     togglePopover()
                } else {
                     popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
                     NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                openUtilityWindow()
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
