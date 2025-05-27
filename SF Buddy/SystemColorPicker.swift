import SwiftUI

struct SystemColorPicker: View {
    @Binding var selectedColor: Color
    let title: String
    @State private var showingPopover = false
    
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
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Button {
                showingPopover.toggle()
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .strokeBorder(.primary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(colorName(for: selectedColor))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPopover) {
                ColorPickerPopover(
                    selectedColor: $selectedColor,
                    systemColors: systemColors,
                    onColorSelected: {
                        showingPopover = false
                    }
                )
            }
        }
    }
    
    private func colorName(for color: Color) -> String {
        return systemColors.first { $0.1 == color }?.0 ?? "Custom"
    }
}

private struct ColorPickerPopover: View {
    @Binding var selectedColor: Color
    let systemColors: [(String, Color)]
    let onColorSelected: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Color")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(systemColors, id: \.0) { colorName, color in
                    SystemColorButton(
                        colorName: colorName,
                        color: color,
                        isSelected: selectedColor == color,
                        action: {
                            selectedColor = color
                            onColorSelected()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

internal struct SystemColorButton: View {
    let colorName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? .primary : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                )
            
            Text(colorName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? .primary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    @State var selectedColor = Color.blue
    
    return SystemColorPicker(selectedColor: $selectedColor, title: "Symbol Color")
        .padding()
}
