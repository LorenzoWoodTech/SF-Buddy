//
//  ContentView.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI
import SFBuddyKit

struct ContentView: View {
    @State private var selectedSymbol: String?

    var body: some View {
        SymbolPickerView(selectedSymbol: $selectedSymbol, mode: .picker)
            .environment(SFBuddyKit.VegasSettings.shared)
            .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity, 
                   minHeight: 600, idealHeight: 700, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(SFSymbolPackageSettings.shared)
        .environment(SFBuddyKit.VegasSettings.shared)
}