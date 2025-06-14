//
//  MainContentView.swift
//  SF Buddy
//
//  Simple three-column layout
//

import SwiftUI
import CoreData

struct MainContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var iconStore = IconStore(context: PersistenceController.shared.container.viewContext)
    
    @State private var selectedIcon: Icon?
    @State private var selectedSidebarItem: SidebarItem?
    
    var body: some View {
        NavigationSplitView {
            // Simple sidebar with default icons
            List(selection: $selectedSidebarItem) {
                Section("Library") {
                    Label("All Icons", systemImage: "square.grid.3x3")
                        .tag(SidebarItem.all)
                    Label("Recent", systemImage: "clock")
                        .tag(SidebarItem.recent)
                }
            }
            .navigationTitle("SF Buddy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Create new icon and select it
                        let newIcon = Icon(context: viewContext)
                        newIcon.semanticName = ""
                        newIcon.baseSymbol = ""
                        newIcon.dateCreated = Date()
                        selectedIcon = newIcon
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } content: {
            // Simple icon list
            List(iconStore.icons, id: \.self, selection: $selectedIcon) { icon in
                VStack(alignment: .leading) {
                    Text(icon.semanticName ?? "Unknown")
                        .font(.headline)
                    Text(icon.baseSymbol ?? "No symbol")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Icons")
        } detail: {
            // Simple form - edits existing or creates new
            if let selectedIcon = selectedIcon {
                IconDetailForm(icon: selectedIcon, iconStore: iconStore)
            } else {
                Text("Select an icon")
            }
        }
        .searchable(text: $iconStore.searchText)
        .onAppear {
            iconStore.updateContext(viewContext)
            selectedSidebarItem = .all
        }
    }
}

struct IconDetailForm: View {
    let icon: Icon
    let iconStore: IconStore
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingPicker = false
    
    var body: some View {
        Form {
            TextField("Name", text: Binding(
                get: { icon.semanticName ?? "" },
                set: { 
                    icon.semanticName = $0.isEmpty ? nil : $0
                    icon.dateModified = Date()
                    try? viewContext.save()
                    iconStore.updateContext(viewContext)
                }
            ))
            
            HStack {
                TextField("Symbol", text: Binding(
                    get: { icon.baseSymbol ?? "" },
                    set: { 
                        icon.baseSymbol = $0.isEmpty ? nil : $0
                        icon.dateModified = Date()
                        try? viewContext.save()
                        iconStore.updateContext(viewContext)
                    }
                ))
                
                Button("Pick") {
                    showingPicker = true
                }
            }
        }
        .navigationTitle("Icon")
        .sheet(isPresented: $showingPicker) {
            SFSymbolBrowserView(selectedSymbol: Binding(
                get: { icon.baseSymbol },
                set: { 
                    icon.baseSymbol = $0
                    icon.dateModified = Date()
                    try? viewContext.save()
                    iconStore.updateContext(viewContext)
                }
            ))
        }
    }
}

enum SidebarItem {
    case all, recent
}

// MARK: - Icon Store

/// Simple IconStore
class IconStore: ObservableObject {
    @Published var icons: [Icon] = []
    @Published var searchText = ""
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchIcons()
    }
    
    func updateContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        fetchIcons()
    }
    
    private func fetchIcons() {
        let request: NSFetchRequest<Icon> = Icon.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Icon.semanticName, ascending: true)]
        
        do {
            icons = try viewContext.fetch(request)
        } catch {
            print("Error fetching icons: \(error)")
            icons = []
        }
    }
}

#Preview {
    MainContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
