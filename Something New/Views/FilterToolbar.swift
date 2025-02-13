import SwiftUI

struct FilterToolbar: View {
    @Binding var filters: TaskFilters
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category Filter
                FilterButton(
                    title: filters.selectedCategory?.rawValue ?? "All",
                    icon: "folder",
                    isSelected: filters.selectedCategory != nil
                ) {
                    // Handle category selection
                }
                
                // Sort Order
                let sortTitle = sortOrderTitle()
                FilterButton(
                    title: sortTitle,
                    icon: "arrow.up.arrow.down",
                    isSelected: filters.sortOrder != .none
                ) {
                    // Handle sort order
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func sortOrderTitle() -> String {
        switch filters.sortOrder {
        case .none:
            return "Sort"
        case .dueDate(let ascending):
            return "Due Date \(ascending ? "↑" : "↓")"
        case .priority:
            return "Priority"
        }
    }
}

struct FilterButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .containerRelativeFrame(.horizontal)
        }
        .background(
            Capsule()
                .fill(isSelected ? themeManager.currentColor.opacity(0.1) : .clear)
                .padding(1)
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? themeManager.currentColor : .gray.opacity(0.3), lineWidth: 1)
                .padding(1)
        )
        .foregroundColor(isSelected ? themeManager.currentColor : .primary)
    }
} 
