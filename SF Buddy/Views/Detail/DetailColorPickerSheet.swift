import SwiftUI

struct DetailColorPickerSheet: View {
    @Binding var conceptColor: Color
    @Binding var showingColorPicker: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(conceptColor)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .strokeBorder(.primary.opacity(0.3), lineWidth: 2)
                        )
                    
                    Text("Choose Concept Color")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                let systemColors: [(String, Color)] = [
                    ("Red", .red), ("Orange", .orange), ("Yellow", .yellow), ("Green", .green),
                    ("Mint", .mint), ("Teal", .teal), ("Cyan", .cyan), ("Blue", .blue),
                    ("Indigo", .indigo), ("Purple", .purple), ("Pink", .pink), ("Brown", .brown),
                    ("Gray", .gray), ("Primary", .primary), ("Secondary", .secondary), ("Accent", .accentColor)
                ]
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(systemColors, id: \.0) { colorName, color in
                        Button {
                            conceptColor = color
                            showingColorPicker = false
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(conceptColor == color ? .primary : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Text(colorName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                conceptColor == color ? .blue.opacity(0.1) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Concept Color")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingColorPicker = false
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
} 