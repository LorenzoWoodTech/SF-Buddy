//
//  ContentView.swift
//  SF Buddy
//
//  Created by Lorenzo Wood on 5/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettingsSheet = false
    @StateObject private var symbolService = SFSymbolService.shared

    var body: some View {
        SearchView(showingSettingsSheet: $showingSettingsSheet)
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
                    .environmentObject(SFSymbolService.shared)
                    .environmentObject(AppSettings.shared)
                    .frame(minWidth: 380, idealWidth: 400, maxWidth: 450, minHeight: 500, idealHeight: 650, maxHeight: 800)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .frame(minWidth: 320, idealWidth: 380, maxWidth: 420, minHeight: 400, idealHeight: 600, maxHeight: 750)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SearchView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var searchText = ""
    @Binding var showingSettingsSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                HStack {
                    Spacer()
                    Text("SF Buddy")
                        .font(.headline)
                    Spacer()
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing)
                }
            }
            .padding(.top)

            if symbolService.claudeAPIKey.isEmpty && !symbolService.isProcessing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude API Key Required:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        SecureField("Enter your Anthropic API Key...", text: $symbolService.claudeAPIKey)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    Link("Get an API Key from Anthropic", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                        .font(.caption)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !searchText.isEmpty {
                            Task {
                                await symbolService.searchSymbols(for: searchText)
                            }
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            if symbolService.isProcessing {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding SF Symbols...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if symbolService.apiKeyMissingOrInvalid && !symbolService.claudeAPIKey.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Claude API Key Invalid or Issue")
                        .font(.headline)
                    Text("There was an issue with your API key or the service. Please check your key and internet connection. You can update your key in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    if !symbolService.lastProcessedText.isEmpty && symbolService.suggestedSymbols.isEmpty && symbolService.invalidSymbolNamesFromClaude.isEmpty {
                        Text("Tried for: \"\(symbolService.lastProcessedText)\"")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            } else if !symbolService.suggestedSymbols.isEmpty || !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                SymbolPickerView()
            } else if !searchText.isEmpty && symbolService.suggestedSymbols.isEmpty && symbolService.invalidSymbolNamesFromClaude.isEmpty && !symbolService.apiKeyMissingOrInvalid && !symbolService.claudeAPIKey.isEmpty {
                Text("No symbols found for \"\(searchText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else if symbolService.claudeAPIKey.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "key.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text("API Key Needed")
                        .font(.headline)
                    Text("Please enter your Anthropic API key above to start finding symbols.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    Text("Ready to Find Symbols")
                        .font(.headline)
                    Text("Enter text in the search bar above, or press ⌃⌥⌘Space to find symbols for selected text in other apps.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            Spacer()
        }
    }
}

struct SettingsView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Settings")
                        .font(.title2)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                }
                .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude API Key")
                        .font(.headline)
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(symbolService.claudeAPIKey.isEmpty ? .orange : .secondary)
                        SecureField("Enter your Anthropic API Key...", text: $symbolService.claudeAPIKey)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    if symbolService.claudeAPIKey.isEmpty {
                        Text("An API key is required to suggest symbols.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.leading, 4)
                    }
                    Link("Get an API Key from Anthropic", destination: URL(string: "https://console.anthropic.com/account/keys")!)
                        .font(.caption)
                        .padding(.top, 2)
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Model")
                        .font(.headline)
                    VStack(spacing: 6) {
                        ForEach(ClaudeModel.allCases) { model in
                            Button {
                                appSettings.selectedModel = model
                            } label: {
                                HStack {
                                    Image(systemName: appSettings.selectedModel == model ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(appSettings.selectedModel == model ? .accentColor : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        Text(model.description)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(appSettings.selectedModel == model ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol Generation")
                        .font(.headline)
                    HStack {
                        Text("Number of symbols:")
                            .font(.caption)
                        Spacer()
                        Picker("Symbol Count", selection: $appSettings.symbolCount) {
                            ForEach([8, 12, 16, 20, 24], id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                    Text("Choose how many symbols to generate for each search.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Appearance")
                        .font(.headline)
                    Toggle("Show in Menu Bar", isOn: $appSettings.showInMenuBar)
                        .padding(.vertical, 4)
                    Text("If hidden, a Dock icon will appear. You may need to re-launch if both are hidden to access settings.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
    }
}

struct SymbolPickerView: View {
    @StateObject private var symbolService = SFSymbolService.shared
    @State private var selectedColor: Color = .primary
    @State private var showingStylePopover = false
    @State private var showingColorPopover = false
    @State private var showingGridSizePopover = false
    @State private var showingVegasSettingsPopover = false
    @State private var vegasMode = false
    @State private var gridSize: GridSize = .medium

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button {
                        showingGridSizePopover.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: gridSize.iconName)
                                .font(.caption)
                            Text("Grid")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingGridSizePopover) {
                        GridSizePopover(selectedGridSize: $gridSize)
                    }
                    
                    Button {
                        showingStylePopover.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.grid.2x2")
                                .font(.caption)
                            Text("Render")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingStylePopover) {
                        RenderingModePopover(
                            selectedRenderingMode: $symbolService.currentRenderingMode
                        )
                    }
                    
                    Button {
                        showingColorPopover.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.primary.opacity(0.3), lineWidth: 0.5)
                                )
                            Text("Colors")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingColorPopover) {
                        ColorPickerPopover(
                            selectedColor: $selectedColor
                        )
                    }
                    
                    Button {
                        withAnimation(.bouncy) {
                            vegasMode.toggle()
                        }
                    } label: {
                        Image(systemName: vegasMode ? "sparkles" : "sparkles")
                            .font(.caption)
                            .foregroundColor(vegasMode ? .yellow : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(vegasMode ? Color.yellow.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .onLongPressGesture {
                        showingVegasSettingsPopover = true
                    }
                    .popover(isPresented: $showingVegasSettingsPopover) {
                        VegasSettingsPopover()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)

                if !symbolService.suggestedSymbols.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: gridSize.buttonSize.min, maximum: gridSize.buttonSize.max), spacing: 10), count: gridSize.columnCount), spacing: 10) {
                        ForEach(symbolService.suggestedSymbols) { suggestion in
                            SymbolButton(suggestion: suggestion, symbolColor: selectedColor, vegasMode: vegasMode, gridSize: gridSize)
                        }
                    }
                    .padding(.horizontal, 16)
                } else if symbolService.suggestedSymbols.isEmpty && !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                    Text("All suggested symbols appear to be invalid or non-existent.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                } else if symbolService.suggestedSymbols.isEmpty && symbolService.apiKeyMissingOrInvalid && !symbolService.lastProcessedText.isEmpty {
                }

                if !symbolService.invalidSymbolNamesFromClaude.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Model suggested \(symbolService.invalidSymbolNamesFromClaude.count) invalid symbol name(s):")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text(symbolService.invalidSymbolNamesFromClaude.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                            .padding(.leading, 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

            }
            .padding(.vertical)
        }
    }
}

enum GridSize: String, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var columnCount: Int {
        switch self {
        case .small: return 8
        case .medium: return 4
        case .large: return 3
        case .extraLarge: return 1
        }
    }
    
    var iconName: String {
        switch self {
        case .small: return "grid"
        case .medium: return "square.grid.2x2"
        case .large: return "rectangle.grid.1x2"
        case .extraLarge: return "square.fill"
        }
    }
    
    var symbolSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 24
        case .large: return 32
        case .extraLarge: return 64
        }
    }
    
    var buttonSize: (min: CGFloat, max: CGFloat, height: CGFloat) {
        switch self {
        case .small: return (40, 50, 50)
        case .medium: return (70, 85, 75)
        case .large: return (90, 110, 90)
        case .extraLarge: return (300, 350, 140)
        }
    }
    
    var showNames: Bool {
        switch self {
        case .small: return false
        default: return true
        }
    }
}

extension SFSymbolRenderingMode {
    var iconName: String {
        switch self {
        case .monochrome:
            return "circle"
        case .hierarchical:
            return "circle.lefthalf.striped.horizontal"
        case .palette:
            return "paintpalette"
        case .multicolor:
            return "circle.hexagongrid"
        }
    }
}

private struct GridSizePopover: View {
    @Binding var selectedGridSize: GridSize
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grid Size")
                .font(.caption)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                ForEach(GridSize.allCases) { size in
                    Button {
                        selectedGridSize = size
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: size.iconName)
                                .font(.caption)
                            Text(size.displayName)
                                .font(.caption)
                            Spacer()
                            if selectedGridSize == size {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(selectedGridSize == size ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 140)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct RenderingModePopover: View {
    @Binding var selectedRenderingMode: SFSymbolRenderingMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Render Mode")
                .font(.caption)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                ForEach(SFSymbolRenderingMode.allCases) { mode in
                    Button {
                        selectedRenderingMode = mode
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: mode.iconName)
                                .font(.caption)
                            Text(mode.displayName)
                                .font(.caption)
                            Spacer()
                            if selectedRenderingMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(selectedRenderingMode == mode ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 140)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct ColorPickerPopover: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss

    private let systemColors: [(String, Color)] = [
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Blue", .blue),
        ("Indigo", .indigo),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Brown", .brown),
        ("Gray", .gray),
        ("Primary", .primary),
        ("Secondary", .secondary),
        ("Accent", .accentColor)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 3), count: 8), spacing: 3) {
                ForEach(systemColors, id: \.0) { colorName, color in
                    Button {
                        selectedColor = color
                        dismiss()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .strokeBorder(selectedColor == color ? .primary : Color.clear, lineWidth: 1.5)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(colorName)
                }
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(RoundedRectangle(cornerRadius: 6).fill(.regularMaterial))
    }
}

struct SymbolButton: View {
    let suggestion: SFSymbolSuggestion
    let symbolColor: Color
    let vegasMode: Bool
    let gridSize: GridSize
    @StateObject private var symbolService = SFSymbolService.shared
    @StateObject private var appSettings = AppSettings.shared
    @State private var isHovered = false
    @State private var justCopied = false
    @State private var animationOffset: CGFloat = 0
    @State private var animationRotation: Double = 0
    @State private var animationScale: CGFloat = 1
    @State private var randomColor: Color = .primary
    @State private var vegasTimer: Timer?

    var body: some View {
        VStack(spacing: 4) {
            if justCopied {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: gridSize.symbolSize + 6))
                    .foregroundColor(.green)
                Text("Copied!")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Image(systemName: suggestion.name)
                    .font(.system(size: gridSize.symbolSize))
                    .foregroundColor(isHovered ? .white : (vegasMode ? randomColor : symbolColor))
                    .symbolRenderingMode(symbolRenderingMode)
                    .frame(width: gridSize.symbolSize + 12, height: gridSize.symbolSize + 12)
                    .scaleEffect(vegasMode ? animationScale : 1)
                    .rotationEffect(.degrees(vegasMode ? animationRotation : 0))
                    .offset(x: vegasMode ? animationOffset : 0)
                    .symbolEffect(.bounce, isActive: vegasMode)
                    .symbolEffect(.pulse, isActive: vegasMode)

                if gridSize.showNames {
                    Text(suggestion.name)
                        .font(.caption2)
                        .foregroundColor(isHovered ? .white : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(minWidth: gridSize.buttonSize.min, maxWidth: gridSize.buttonSize.max, minHeight: gridSize.buttonSize.height, maxHeight: gridSize.buttonSize.height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered && !justCopied ? Color.accentColor : Color.clear)
                .opacity(vegasMode ? 0.1 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            if !justCopied {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .onTapGesture {
            if !justCopied {
                symbolService.replaceTextWithSymbol(suggestion.name)
                withAnimation {
                    justCopied = true
                }

                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run {
                        withAnimation {
                            justCopied = false
                        }
                        if let delegate = NSApplication.shared.delegate as? AppDelegate {
                            delegate.popover?.performClose(nil)
                        }
                    }
                }
            }
        }
        .draggable(suggestion.name) {
            VStack(spacing: 2) {
                Image(systemName: suggestion.name)
                    .font(.system(size: 16))
                    .foregroundColor(vegasMode ? randomColor : symbolColor)
                Text(suggestion.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.regularMaterial)
            }
        }
        .onAppear {
            if vegasMode {
                startVegasAnimations()
            }
        }
        .onChange(of: vegasMode) { oldValue, newValue in
            if newValue {
                startVegasAnimations()
            } else {
                stopVegasAnimations()
            }
        }
        .onChange(of: appSettings.vegasAnimationSpeed) { _, _ in if vegasMode { restartVegasAnimations() } }
        .onChange(of: appSettings.vegasColorCycleSpeed) { _, _ in if vegasMode { restartVegasAnimations() } }
        .onChange(of: appSettings.vegasIntensity) { _, _ in if vegasMode { restartVegasAnimations() } }
        .onChange(of: appSettings.vegasRotationEnabled) { _, _ in if vegasMode { restartVegasAnimations() } }
    }
    
    private func restartVegasAnimations() {
        stopVegasAnimations()
        startVegasAnimations()
    }

    private func startVegasAnimations() {
        vegasTimer?.invalidate()
        vegasTimer = nil

        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
        randomColor = colors.randomElement() ?? .primary
        
        let baseSpeed = 2.5 / appSettings.vegasAnimationSpeed
        let intensity = appSettings.vegasIntensity
        let colorSpeed = 1.5 / appSettings.vegasColorCycleSpeed
        
        withAnimation(.easeInOut(duration: Double.random(in: baseSpeed...baseSpeed*1.5)).repeatForever(autoreverses: true)) {
            animationScale = Double.random(in: (1.0 - 0.2 * intensity)...(1.0 + 0.3 * intensity))
        }
        
        if appSettings.vegasRotationEnabled {
            withAnimation(.linear(duration: Double.random(in: (4.0/intensity)...(6.0/intensity))).repeatForever(autoreverses: false)) {
                animationRotation = 360
            }
        } else {
            animationRotation = 0
        }
        
        withAnimation(.easeInOut(duration: Double.random(in: baseSpeed...(baseSpeed*2.0))).repeatForever(autoreverses: true)) {
            animationOffset = Double.random(in: (-5*intensity)...(5*intensity))
        }
        
        vegasTimer = Timer.scheduledTimer(withTimeInterval: colorSpeed, repeats: true) { timer in
            if !vegasMode {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                randomColor = colors.randomElement() ?? .primary
            }
        }
    }
    
    private func stopVegasAnimations() {
        vegasTimer?.invalidate()
        vegasTimer = nil

        withAnimation(.easeOut(duration: 0.5)) {
            animationScale = 1
            animationRotation = 0
            animationOffset = 0
            randomColor = symbolColor
        }
    }

    private var symbolRenderingMode: SymbolRenderingMode {
        switch symbolService.currentRenderingMode {
        case .monochrome:
            return .monochrome
        case .hierarchical:
            return .hierarchical
        case .palette:
            return .palette
        case .multicolor:
            return .multicolor
        }
    }
}

struct VegasSettingsPopover: View {
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vegas Mode Settings")
                .font(.caption)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Animation Speed:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasAnimationSpeed, in: 0.5...3.0, step: 0.1)
                        .frame(width: 80)
                    Text(String(format: "%.1fx", appSettings.vegasAnimationSpeed))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25)
                }
                
                HStack {
                    Text("Color Cycling:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasColorCycleSpeed, in: 0.2...5.0, step: 0.1)
                        .frame(width: 80)
                    Text(String(format: "%.1fx", appSettings.vegasColorCycleSpeed))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25)
                }
                
                HStack {
                    Text("Intensity:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasIntensity, in: 0.3...2.0, step: 0.1)
                        .frame(width: 80)
                    Text(String(format: "%.1fx", appSettings.vegasIntensity))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25)
                }
                
                HStack {
                    Text("Rotation:")
                        .font(.caption2)
                    Spacer()
                    Toggle("", isOn: $appSettings.vegasRotationEnabled)
                        .controlSize(.mini)
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .font(.caption)
            .padding(.top, 4)
        }
        .padding(12)
        .frame(width: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environmentObject(SFSymbolService.shared)
        .environmentObject(AppSettings.shared)
}
