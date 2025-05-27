//
//  SymbolSize.swift
//  SF Buddy
//

import Foundation

enum SymbolSize: String, CaseIterable, Identifiable {
    case normal = "normal"
    case large = "large"  
    case extraLarge = "extraLarge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}