//
//  PublishSheet.swift
//  SF Buddy
//
//  Sheet for publishing/generating code registry with branded empty state
//

import SwiftUI

struct PublishSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "swift")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Code Generation")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Automatically generate IconRegistry.swift with type-safe access to all your icons.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("Learn More") {
                        // TODO: Open README link in external browser
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Notify Me") {
                        // TODO: Add to notification list (placeholder)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Publish Registry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 600,
               minHeight: 300, idealHeight: 400, maxHeight: 500)
        #endif
    }
}

#Preview {
    PublishSheet()
}