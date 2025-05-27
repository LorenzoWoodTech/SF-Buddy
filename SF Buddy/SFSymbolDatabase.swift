//
//  SFSymbolDatabase.swift
//  SF Buddy
//
//  Created by Alex Carmack on CurrentDate
//

import Foundation

struct SFSymbolDatabase {
    static let shared = SFSymbolDatabase()
    
    // Comprehensive list of common SF Symbols organized by category
    static let symbolsByCategory: [String: [String]] = [
        "Communication": [
            "phone", "phone.fill", "phone.circle", "phone.circle.fill",
            "message", "message.fill", "message.circle", "message.circle.fill",
            "mail", "mail.fill", "envelope", "envelope.fill", "envelope.open", "envelope.open.fill",
            "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
            "bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill",
            "ellipsis.bubble", "ellipsis.bubble.fill", "quote.bubble", "quote.bubble.fill"
        ],
        
        "System": [
            "gear", "gearshape", "gearshape.fill", "slider.horizontal.3", "slider.vertical.3",
            "switch.2", "power", "restart", "sleep", "wake", "power.circle", "power.circle.fill",
            "lock", "lock.fill", "lock.open", "lock.open.fill", "key", "key.fill",
            "wifi", "wifi.slash", "antenna.radiowaves.left.and.right",
            "battery.100", "battery.75", "battery.50", "battery.25", "battery.0"
        ],
        
        "Navigation": [
            "house", "house.fill", "house.circle", "house.circle.fill",
            "arrow.left", "arrow.right", "arrow.up", "arrow.down",
            "arrow.left.circle", "arrow.right.circle", "arrow.up.circle", "arrow.down.circle",
            "arrow.left.circle.fill", "arrow.right.circle.fill", "arrow.up.circle.fill", "arrow.down.circle.fill",
            "chevron.left", "chevron.right", "chevron.up", "chevron.down",
            "chevron.left.circle", "chevron.right.circle", "chevron.up.circle", "chevron.down.circle",
            "location", "location.fill", "location.circle", "location.circle.fill",
            "map", "map.fill", "globe", "globe.fill"
        ],
        
        "Media": [
            "play", "play.fill", "play.circle", "play.circle.fill",
            "pause", "pause.fill", "pause.circle", "pause.circle.fill",
            "stop", "stop.fill", "stop.circle", "stop.circle.fill",
            "forward", "forward.fill", "backward", "backward.fill",
            "speaker", "speaker.fill", "speaker.wave.1", "speaker.wave.2", "speaker.wave.3",
            "speaker.slash", "speaker.slash.fill", "mic", "mic.fill", "mic.slash", "mic.slash.fill",
            "headphones", "airpods", "tv", "tv.fill", "camera", "camera.fill",
            "video", "video.fill", "video.slash", "video.slash.fill"
        ],
        
        "Files": [
            "folder", "folder.fill", "folder.circle", "folder.circle.fill",
            "doc", "doc.fill", "doc.text", "doc.text.fill",
            "text.document", "text.document.fill", "doc.richtext", "doc.richtext.fill",
            "note", "note.text", "book", "book.fill", "book.closed", "book.closed.fill",
            "bookmark", "bookmark.fill", "bookmark.circle", "bookmark.circle.fill",
            "paperclip", "link", "square.and.arrow.up", "square.and.arrow.down",
            "tray", "tray.fill", "archivebox", "archivebox.fill"
        ],
        
        "Actions": [
            "plus", "plus.circle", "plus.circle.fill", "plus.square", "plus.square.fill",
            "minus", "minus.circle", "minus.circle.fill", "minus.square", "minus.square.fill",
            "multiply", "multiply.circle", "multiply.circle.fill",
            "divide", "divide.circle", "divide.circle.fill",
            "equal", "equal.circle", "equal.circle.fill",
            "checkmark", "checkmark.circle", "checkmark.circle.fill", "checkmark.square", "checkmark.square.fill",
            "xmark", "xmark.circle", "xmark.circle.fill", "xmark.square", "xmark.square.fill",
            "trash", "trash.fill", "trash.circle", "trash.circle.fill",
            "pencil", "pencil.circle", "pencil.circle.fill", "square.and.pencil"
        ],
        
        "People": [
            "person", "person.fill", "person.circle", "person.circle.fill",
            "person.2", "person.2.fill", "person.3", "person.3.fill",
            "person.crop.circle", "person.crop.circle.fill",
            "person.crop.square", "person.crop.square.fill",
            "face.smiling", "face.smiling.fill", "heart", "heart.fill",
            "heart.circle", "heart.circle.fill", "star", "star.fill",
            "star.circle", "star.circle.fill"
        ],
        
        "Shopping": [
            "cart", "cart.fill", "cart.circle", "cart.circle.fill",
            "bag", "bag.fill", "bag.circle", "bag.circle.fill",
            "basket", "basket.fill", "creditcard", "creditcard.fill",
            "dollarsign.circle", "dollarsign.circle.fill", "tag", "tag.fill",
            "tag.circle", "tag.circle.fill", "giftcard", "giftcard.fill"
        ],
        
        "Weather": [
            "sun.max", "sun.max.fill", "moon", "moon.fill",
            "cloud", "cloud.fill", "cloud.rain", "cloud.rain.fill",
            "cloud.snow", "cloud.snow.fill", "bolt", "bolt.fill",
            "thermometer", "drop", "drop.fill", "humidity", "humidity.fill",
            "wind", "tornado", "hurricane", "snowflake"
        ],
        
        "Transport": [
            "car", "car.fill", "car.circle", "car.circle.fill",
            "bus", "bus.fill", "airplane", "airplane.circle", "airplane.circle.fill",
            "bicycle", "bicycle.circle", "bicycle.circle.fill",
            "train.side.front.car", "tram", "ferry", "sailboat", "sailboat.fill"
        ],
        
        "Search": [
            "magnifyingglass", "magnifyingglass.circle", "magnifyingglass.circle.fill",
            "text.magnifyingglass", "doc.text.magnifyingglass", "sparkles.magnifyingglass"
        ],
        
        "Time": [
            "clock", "clock.fill", "clock.circle", "clock.circle.fill",
            "timer", "stopwatch", "stopwatch.fill", "alarm", "alarm.fill",
            "calendar", "calendar.circle", "calendar.circle.fill"
        ],
        
        "Health": [
            "heart.text.square", "heart.text.square.fill", "medical.thermometer",
            "pills", "pills.fill", "cross", "cross.fill", "cross.circle", "cross.circle.fill",
            "staroflife", "staroflife.fill", "staroflife.circle", "staroflife.circle.fill"
        ]
    ]
    
    // Get all symbols as a flat array
    static var allSymbols: [String] {
        return symbolsByCategory.values.flatMap { $0 }
    }
    
    // Get symbols relevant to a search term
    static func getRelevantSymbolsForPrompt(searchTerm: String) -> String {
        let lowercasedTerm = searchTerm.lowercased()
        var relevantSymbols: [String] = []
        
        // Find categories that might be relevant
        for (category, symbols) in symbolsByCategory {
            if category.lowercased().contains(lowercasedTerm) ||
               lowercasedTerm.contains(category.lowercased()) {
                relevantSymbols.append(contentsOf: symbols)
            }
        }
        
        // Also find individual symbols that might match
        for symbols in symbolsByCategory.values {
            for symbol in symbols {
                if symbol.lowercased().contains(lowercasedTerm) ||
                   lowercasedTerm.contains(symbol.lowercased().replacingOccurrences(of: ".", with: " ")) {
                    if !relevantSymbols.contains(symbol) {
                        relevantSymbols.append(symbol)
                    }
                }
            }
        }
        
        // If no specific matches, include some common ones
        if relevantSymbols.isEmpty {
            relevantSymbols = Array(allSymbols.prefix(50))
        }
        
        return relevantSymbols.joined(separator: ", ")
    }
}