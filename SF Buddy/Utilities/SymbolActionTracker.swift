//
//  SymbolActionTracker.swift
//  SF Buddy
//
//  Utility for tracking symbol actions in SwiftData
//

import Foundation
import SwiftData
import SFBuddyKit

/// Sets up the symbol service callback to track actions in SwiftData
@MainActor
func setupSymbolServiceCallback(context: ModelContext) {
    let symbolService = SFBuddyKit.SFSymbolService.shared
    
    symbolService.trackSymbolActionCallback = { symbolName, action, searchTerm in
        Task { @MainActor in
            // Get or create recent search
            let descriptor = FetchDescriptor<RecentSearch>(
                predicate: #Predicate { $0.searchTerm == searchTerm }
            )
            
            do {
                let existingSearches = try context.fetch(descriptor)
                let search: RecentSearch
                
                if let existingSearch = existingSearches.first {
                    search = existingSearch
                    search.selectedSymbol = symbolName
                } else {
                    search = RecentSearch(searchTerm: searchTerm, selectedSymbol: symbolName)
                    context.insert(search)
                }
                
                search.recordAction(action)
                try context.save()
            } catch {
                print("Failed to track symbol action: \(error)")
            }
        }
    }
}