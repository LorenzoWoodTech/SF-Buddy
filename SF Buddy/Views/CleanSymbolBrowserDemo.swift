//
//  CleanSymbolBrowserDemo.swift
//  SF Buddy
//
//  Demo view showcasing the clean SF Symbol browser components
//

import SwiftUI
import SF_Buddy_Package

struct CleanSymbolBrowserDemo: View {
    @State private var selectedSymbol: String?
    @State private var showingBrowser = false
    @State private var showingAISearch = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                
                Text("SF Symbol Browser")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                Text("Clean, focused symbol search and selection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Selected Symbol Display
            if let selectedSymbol = selectedSymbol {
                VStack(spacing: 8) {
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 48))
                        .foregroundStyle(.primary)
                    
                    Text(selectedSymbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    showingBrowser = true
                } label: {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                        Text("Browse All Symbols")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                
                Button {
                    showingAISearch = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("AI Symbol Search")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
            }
            
            Spacer()
            
            // Package Info
            VStack(spacing: 8) {
                Text("Package-Ready Components")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Comprehensive symbol browser")
                    Text("• AI-powered symbol suggestions")
                    Text("• Clean selection interface")
                    Text("• Minimal configuration")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: 600)
        .sheet(isPresented: $showingBrowser) {
            SFSymbolBrowserView(selectedSymbol: $selectedSymbol)
        }
        .sheet(isPresented: $showingAISearch) {
            AISymbolSearchView(selectedSymbol: $selectedSymbol)
        }
    }
}

#Preview {
    CleanSymbolBrowserDemo()
        .environmentObject(SFSymbolService.shared)
        .environment(AppSettings.shared)
}