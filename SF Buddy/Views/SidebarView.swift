//
//  SidebarView.swift
//  SF Buddy
//
//  Clean, HIG-compliant sidebar following Apple's design principles
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @Binding var showingAddConceptSheet: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        List(selection: $selectedItem) {
            // MARK: - Clean Navigation (No Sections)
            NavigationLink(value: SidebarItem.sfSymbols) {
                Label("Icons", systemImage: "square.3.layers.3d.middle.filled")
            }
            .tag(SidebarItem.sfSymbols)
        }
        .navigationTitle("SF Buddy")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gear") {
                    showingSettings = true
                }
                .help("Open Settings")
            }
        }
    }
}