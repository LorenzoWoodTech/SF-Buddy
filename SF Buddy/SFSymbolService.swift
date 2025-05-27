//
//  SFSymbolService.swift
//  SF Buddy
//
//

import Foundation
import AppKit

@MainActor
class SFSymbolService: ObservableObject {
    static let shared = SFSymbolService()
    
    @Published var suggestedSymbols: [SFSymbolSuggestion] = []
    @Published var isProcessing = false
    @Published var lastProcessedText = ""
    
    private let claudeAPIKey = "REDACTED_ANTHROPIC_KEY"
    private let claudeURL = "https://api.anthropic.com/v1/messages"
    
    private init() {
        print("[SFSymbolService] Initialized.")
    }
    
    func processSelectedText() async {
        print("[SFSymbolService] processSelectedText started.")
        isProcessing = true
        
        let selectedText = await getSelectedText()
        print("[SFSymbolService] Selected text: '\(selectedText)'")
        guard !selectedText.isEmpty else {
            print("[SFSymbolService] Selected text is empty. Aborting.")
            isProcessing = false
            return
        }
        
        lastProcessedText = selectedText
        
        await getSFSymbolSuggestions(for: selectedText)
        
        isProcessing = false
        print("[SFSymbolService] processSelectedText finished. Suggested symbols count: \(suggestedSymbols.count)")
        
        NotificationCenter.default.post(name: .showSymbolPicker, object: nil)
        print("[SFSymbolService] .showSymbolPicker notification posted.")
    }
    
    private func getSelectedText() async -> String {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        let selectedText = pasteboard.string(forType: .string) ?? ""
        
        if selectedText == previousContents, let previous = previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
            print("[SFSymbolService] Restored previous clipboard content as it matched selected text.")
        } else if selectedText != previousContents {
        }
        
        return selectedText
    }
    
    private func getSFSymbolSuggestions(for text: String) async {
        print("[SFSymbolService] getSFSymbolSuggestions for: '\(text)'")
        do {
            let symbols = try await callClaudeAPI(for: text)
            print("[SFSymbolService] Claude API success. Raw symbols: \(symbols)")
            suggestedSymbols = symbols.map { SFSymbolSuggestion(name: $0) }
        } catch {
            print("[SFSymbolService] Claude API error: \(error). Falling back to mock suggestions.")
            suggestedSymbols = getMockSuggestions(for: text)
            print("[SFSymbolService] Mock suggestions count: \(suggestedSymbols.count)")
        }
    }
    
    private func callClaudeAPI(for text: String) async throws -> [String] {
        print("[SFSymbolService] Calling Claude API...")
        guard let url = URL(string: claudeURL) else {
            print("[SFSymbolService] Invalid Claude API URL.")
            throw APIError.invalidURL
        }
        
        let prompt = """
        Given this text: "\(text)"
        
        Suggest 6-8 relevant SF Symbols that would best represent this concept, action, or meaning. 
        Return ONLY the symbol names (like "house.fill", "person.circle", "magnifyingglass") separated by commas, no explanations or additional text.
        Focus on symbols that actually exist in Apple's SF Symbols library.
        If the text is about UI elements, suggest symbols commonly used in app interfaces.
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20240620",
            "max_tokens": 200,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[SFSymbolService] Claude API HTTP status: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("[SFSymbolService] Claude API raw response: \(responseString)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let symbolText = firstContent["text"] as? String else {
            print("[SFSymbolService] Invalid Claude API JSON response structure.")
            throw APIError.invalidResponse
        }
        
        print("[SFSymbolService] Claude API parsed text: \(symbolText)")
        
        let symbols = symbolText.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return symbols
    }
    
    private func getMockSuggestions(for text: String) -> [SFSymbolSuggestion] {
        let lowercased = text.lowercased()
        print("[SFSymbolService] Getting mock suggestions for: '\(lowercased)'")
        var symbols: [String] = []
        
        if lowercased.contains("event") || lowercased.contains("calendar") || lowercased.contains("schedule") {
            symbols = ["calendar", "calendar.circle", "calendar.badge.plus", "calendar.badge.clock", "clock", "bell"]
        } else if lowercased.contains("home") || lowercased.contains("house") {
            symbols = ["house", "house.fill", "house.circle", "house.lodge"]
        } else if lowercased.contains("user") || lowercased.contains("person") || lowercased.contains("profile") {
            symbols = ["person", "person.fill", "person.circle", "person.crop.circle"]
        } else if lowercased.contains("settings") || lowercased.contains("config") {
            symbols = ["gearshape", "gearshape.fill", "slider.horizontal.3", "wrench.and.screwdriver"]
        } else if lowercased.contains("search") || lowercased.contains("find") {
            symbols = ["magnifyingglass", "magnifyingglass.circle", "viewfinder", "binoculars"]
        } else if lowercased.contains("message") || lowercased.contains("chat") {
            symbols = ["message", "message.fill", "bubble.left", "bubble.right"]
        } else if lowercased.contains("photo") || lowercased.contains("image") || lowercased.contains("picture") {
            symbols = ["photo", "photo.fill", "camera", "camera.fill"]
        } else {
            symbols = ["star", "heart", "bell", "bookmark", "tag", "flag"]
            print("[SFSymbolService] No specific mock match, using generic symbols.")
        }
        
        return symbols.map { SFSymbolSuggestion(name: $0) }
    }
    
    func replaceTextWithSymbol(_ symbolName: String) {
        print("[SFSymbolService] replaceTextWithSymbol: '\(symbolName)'")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(symbolName, forType: .string)
        
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
}

struct SFSymbolSuggestion: Identifiable {
    let id = UUID()
    let name: String
}

extension Notification.Name {
    static let showSymbolPicker = Notification.Name("showSymbolPicker")
}
