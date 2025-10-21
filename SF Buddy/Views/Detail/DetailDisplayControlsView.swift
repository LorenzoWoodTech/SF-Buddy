import SwiftUI

struct DetailDisplayControlsView: View {
    @Binding var gridSize: BrowserGridSize
    @Binding var selectedRenderingMode: BrowserRenderingMode
    @Binding var conceptColor: Color
    @Binding var vegasMode: Bool
    @Binding var showSymbolNames: Bool
    @Binding var showingSizePopover: Bool
    @Binding var showingRenderingPopover: Bool
    @Binding var showingColorPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display Options")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                // Size control button
                Button {
                    showingSizePopover.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: gridSize.iconName)
                            .font(.caption)
                        Text("Size")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingSizePopover) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symbol Size")
                            .font(.caption)
                            .fontWeight(.medium)
                        ForEach(BrowserGridSize.allCases) { size in
                            Button {
                                gridSize = size
                                showingSizePopover = false
                            } label: {
                                HStack {
                                    Image(systemName: size.iconName)
                                        .font(.caption)
                                    Text(size.displayName)
                                        .font(.caption)
                                    Spacer()
                                    if gridSize == size {
                                        Image(systemName: "checkmark")
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(gridSize == size ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .frame(minWidth: 140)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }

                // Rendering mode control
                Button {
                    showingRenderingPopover.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedRenderingMode.iconName)
                            .font(.caption)
                        Text("Render")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingRenderingPopover) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rendering Mode")
                            .font(.caption)
                            .fontWeight(.medium)
                        ForEach(BrowserRenderingMode.allCases) { mode in
                            Button {
                                selectedRenderingMode = mode
                                showingRenderingPopover = false
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
                    .padding(8)
                    .frame(minWidth: 140)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }

                // Color picker control
                Button {
                    showingColorPicker.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(conceptColor)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(.primary.opacity(0.3), lineWidth: 1))
                        Text("Color")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Vegas mode toggle
                Button {
                    withAnimation(.bouncy) { vegasMode.toggle() }
                } label: {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(vegasMode ? .yellow : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(vegasMode ? Color.yellow.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Toggle Vegas Mode")

                Spacer()

                // Show names toggle
                Toggle("Names", isOn: $showSymbolNames)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
        }
    }
}

#if DEBUG
struct DetailDisplayControlsView_Previews: PreviewProvider {
    @State static var gridSize: BrowserGridSize = .medium
    @State static var renderingMode: BrowserRenderingMode = .hierarchical
    @State static var color: Color = .blue
    @State static var vegasMode = false
    @State static var showNames = true
    @State static var showSize = false
    @State static var showRendering = false
    @State static var showColor = false
    static var previews: some View {
        DetailDisplayControlsView(gridSize: $gridSize,
                                   selectedRenderingMode: $renderingMode,
                                   conceptColor: $color,
                                   vegasMode: $vegasMode,
                                   showSymbolNames: $showNames,
                                   showingSizePopover: $showSize,
                                   showingRenderingPopover: $showRendering,
                                   showingColorPicker: $showColor)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 