//
//  SharedSymbolComponents.swift
//  SF Buddy
//
//  Shared components for symbol pickers to avoid duplication and naming conflicts
//

import SwiftUI

// MARK: - Grid Size Configuration
enum SymbolGridSize: String, CaseIterable, Identifiable {
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

// MARK: - Symbol Rendering Mode
enum SymbolRenderingStyle: String, CaseIterable, Identifiable {
    case monochrome = "monochrome"
    case hierarchical = "hierarchical"
    case palette = "palette"
    case multicolor = "multicolor"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .monochrome: return "Monochrome"
        case .hierarchical: return "Hierarchical"
        case .palette: return "Palette"
        case .multicolor: return "Multicolor"
        }
    }
    
    var iconName: String {
        switch self {
        case .monochrome: return "circle"
        case .hierarchical: return "circle.lefthalf.striped.horizontal"
        case .palette: return "paintpalette"
        case .multicolor: return "circle.hexagongrid"
        }
    }
    
    var swiftUIMode: SymbolRenderingMode {
        switch self {
        case .monochrome: return .monochrome
        case .hierarchical: return .hierarchical
        case .palette: return .palette
        case .multicolor: return .multicolor
        }
    }
}

// MARK: - Grid Size Popover
struct SymbolGridSizePopover: View {
    @Binding var selectedGridSize: SymbolGridSize
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grid Size")
                .font(.caption)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                ForEach(SymbolGridSize.allCases) { size in
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
                        .background(selectedGridSize == size ? Color.accentColor.opacity(0.1) : Color.clear, 
                                   in: RoundedRectangle(cornerRadius: 4))
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

// MARK: - Rendering Mode Popover
struct SymbolRenderingModePopover: View {
    @Binding var selectedRenderingMode: SymbolRenderingStyle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Render Mode")
                .font(.caption)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                ForEach(SymbolRenderingStyle.allCases) { mode in
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
                        .background(selectedRenderingMode == mode ? Color.accentColor.opacity(0.1) : Color.clear, 
                                   in: RoundedRectangle(cornerRadius: 4))
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

// MARK: - Color Picker Popover
struct SymbolColorPickerPopover: View {
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

// MARK: - Vegas Settings Popover
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
                    Text("Randomness:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasRandomnessLevel, in: 0.0...1.0, step: 0.1)
                        .frame(width: 80)
                    Text(String(format: "%.1f", appSettings.vegasRandomnessLevel))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25)
                }
                
                HStack {
                    Text("Scale Chaos:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasScaleIntensity, in: 0.1...1.0, step: 0.1)
                        .frame(width: 80)
                    Text(String(format: "%.1f", appSettings.vegasScaleIntensity))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25)
                }
                
                HStack {
                    Text("Movement:")
                        .font(.caption2)
                    Spacer()
                    Slider(value: $appSettings.vegasMovementIntensity, in: 1.0...15.0, step: 1.0)
                        .frame(width: 80)
                    Text(String(format: "%.0f", appSettings.vegasMovementIntensity))
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
            
            HStack {
                Button("Randomize") {
                    appSettings.randomizeVegas()
                }
                .font(.caption)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.caption)
            }
            .padding(.top, 4)
        }
        .padding(12)
        .frame(width: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}