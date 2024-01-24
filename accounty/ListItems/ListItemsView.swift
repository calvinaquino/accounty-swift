//
//  ListItemsView.swift
//  accounty
//
//  Created by Calvin Gonçalves de Aquino on 2023-12-18.
//

import SwiftUI
import SwiftData

struct ListItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState: AppState
    @Bindable var list: ShoppingList
    @State var searchText = ""
    @State var editingItem: Item?
    
    var body: some View {
        ListitemsFilter(list: list, searchText: $searchText) { items, categories in
            List {
                ForEach(items) { itemListRow(item: $0) }
                    .onDelete { deleteUncategorizedItems(offsets: $0, from: items) }
                ForEach(categories) { category in
                    Section(header: Text(category.name)) {
                        ForEach(category.items) { itemListRow(item: $0) }
                            .onDelete { deleteUncategorizedItems(offsets: $0, from: category.items) }
                    }
                }
            }
            .overlay {
                if items.isEmpty, categories.isEmpty {
                    #warning("improve the look of this view.")
    //                ContentUnavailableView.search
                    Button("Create new item named '\(searchText)'") {
                        addSearchItem()
                    }
                }
            }
            .searchable(text: $searchText)
            .onSubmit(of: .search) {
                if items.isEmpty, categories.isEmpty {
                    addItem()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                    Button(action: goToCategories) {
                        Label("Categories", systemImage: "folder")
                    }
                }
                ToolbarItem(placement: .principal) {
                    TextField("List", text: $list.name)
                        .fixedSize()
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let data = try! JSONEncoder().encode(list.id)
                UserDefaults.standard.setValue(data, forKey: "selectedList")
            }
            .sheet(item: $editingItem) { item in
                NavigationView {
                    ItemEditView(item: item, list: self.list)
                        .navigationTitle(item.name)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                Button {
                                    self.editingItem = nil
                                } label: {
                                    Text("Done")
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newName = searchText.isEmpty ? "New item" : searchText
            searchText = ""
            let newItem = Item(name: newName, list: list)
            modelContext.insert(newItem)
            editingItem = newItem // should open sheet
        }
    }
    
    private func goToCategories() {
        appState.path.append(.categories(list))
    }
    
    private func addSearchItem() {
        withAnimation {
            let newName = searchText.isEmpty ? "New item" : searchText
            searchText = ""
            let newItem = Item(name: newName, list: list)
            modelContext.insert(newItem)
            editingItem = newItem // should open sheet
        }
    }
    
    @ViewBuilder private func itemListRow(item: Item) -> some View {
        ItemRowView(item: item) {
            self.editingItem = item
        }
    }
    
    private func deleteUncategorizedItems(offsets: IndexSet, from items: [Item]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

extension Collection where Element == ListingCategory {
    var itemCount: Int {
        self.reduce(0) { partialResult, cat in
            partialResult + cat.items.count
        }
    }
}

#Preview {
    ListsView()
        .modelContainer(for: Item.self, inMemory: true)
}
