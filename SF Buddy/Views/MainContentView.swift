//
//  MainContentView.swift
//  SF Buddy
//
//  Simplified menu bar popover focused interface
//

import SwiftUI
import SwiftData
import SFBuddyKit

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSymbol: String?
    
    var body: some View {
        SymbolPickerView(selectedSymbol: $selectedSymbol, mode: .picker)
            .environment(SFBuddyKit.VegasSettings.shared)
            .frame(width: 450, height: 800)
            .onAppear {
                setupSymbolServiceCallback(context: modelContext)
            }
    }
}

#Preview {
    MainContentView()
        .modelContainer(SwiftDataContainer.preview)
        .environment(SFSymbolPackageSettings.shared)
        .environment(SFBuddyKit.VegasSettings.shared)
}