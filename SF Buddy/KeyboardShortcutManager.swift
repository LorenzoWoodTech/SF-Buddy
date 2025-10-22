//
//  KeyboardShortcutManager.swift
//  SF Buddy
//
//  Platform-specific keyboard shortcut management
//

import Foundation
import SF_Buddy_Package
#if os(macOS)
import AppKit
#endif

class KeyboardShortcutManager: ObservableObject {
    #if os(macOS)
    private var eventMonitor: Any?
    #endif
    
    func setupGlobalShortcut() {
        #if os(macOS)
        print("[KeyboardShortcutManager] setupGlobalShortcut called.")
        
        // Use NSEvent monitor instead of Carbon APIs
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // print("[KeyboardShortcutManager] Global key down event: keyCode \(event.keyCode), modifiers \(event.modifierFlags)")
            
            // Check for Ctrl+Option+Cmd+Space
            let ctrl = event.modifierFlags.contains(.control)
            let opt = event.modifierFlags.contains(.option)
            let cmd = event.modifierFlags.contains(.command)
            let isSpaceKey = event.keyCode == 49 // Space key's virtual key code
            
            // print("[KeyboardShortcutManager] Modifiers - Ctrl:\(ctrl) Opt:\(opt) Cmd:\(cmd) | KeyCode: \(event.keyCode) (Space is 49)")

            if isSpaceKey && ctrl && opt && cmd {
                print("[KeyboardShortcutManager] Shortcut ⌃⌥⌘Space DETECTED!")
                Task {
                    print("[KeyboardShortcutManager] Task: Calling SFSymbolService.shared.processSelectedText()")
                    await SF_Buddy_Package.SFSymbolService.shared.processSelectedText()
                    print("[KeyboardShortcutManager] Task: SFSymbolService.shared.processSelectedText() finished.")
                }
            }
        }
        
        if eventMonitor != nil {
            print("[KeyboardShortcutManager] Global event monitor successfully created.")
        } else {
            print("[KeyboardShortcutManager] FAILED to create global event monitor.")
        }
        #else
        print("[KeyboardShortcutManager] Global shortcuts only available on macOS")
        #endif
    }
    
    deinit {
        #if os(macOS)
        if let eventMonitor = eventMonitor {
            print("[KeyboardShortcutManager] Removing global event monitor.")
            NSEvent.removeMonitor(eventMonitor)
        }
        #endif
    }
}