import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Binding var imageViewerData: ImageViewerData?
    
    var body: some View {
        VStack(spacing: 20) {
            // Statistics Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                StatisticCardView(
                    title: "Total Tasks",
                    value: "\(viewModel.todos.count)",
                    icon: "checklist",
                    color: .blue
                )
                
                StatisticCardView(
                    title: "Completed",
                    value: "\(viewModel.todos.filter(\.isCompleted).count)",
                    icon: "checkmark",
                    color: .green
                )
                
                StatisticCardView(
                    title: "Pending",
                    value: "\(viewModel.todos.filter { !$0.isCompleted }.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatisticCardView(
                    title: "Due Today",
                    value: "\(todayTasks.count)",
                    icon: "calendar",
                    color: .red
                )
            }
            .padding(.horizontal)
            
            List {
                Section(header: Text("Categories")) {
                    ForEach(Category.allCases, id: \.self) { category in
                        let categoryTodos = viewModel.todos(for: category).filter { !$0.isCompleted }
                        NavigationLink {
                            CategoryView(
                                category: category,
                                viewModel: viewModel,
                                imageViewerData: $imageViewerData
                            )
                        } label: {
                            CategoryRowView(
                                title: category.rawValue,
                                count: categoryTodos.count,
                                icon: category.icon,
                                color: category.color
                            )
                        }
                    }
                }
            }
            .scrollDisabled(true)
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var todayTasks: [TodoItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return viewModel.todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        // Default icon mapping - can be expanded
        switch category.lowercased() {
        case "personal": return "house.fill"
        case "work": return "briefcase.fill"
        case "college", "school": return "backpack.fill"
        case "shopping": return "cart.fill"
        case "health": return "heart.fill"
        case "finance": return "dollarsign.circle.fill"
        default: return "tag.fill"
        }
    }
}

struct CategoryRowView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(Circle())
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Binding var selectedCategory: Category?
    @Binding var imageViewerData: ImageViewerData?
    
    var body: some View {
        List {
            ForEach(Category.allCases, id: \.self) { category in
                let incompleteTodoCount = viewModel.todos.filter { $0.category == category && !$0.isCompleted }.count
                
                NavigationLink(destination: CategoryView(
                    category: category,
                    viewModel: viewModel,
                    imageViewerData: $imageViewerData
                )) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("\(incompleteTodoCount) tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color(.systemBackground))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Tasks")
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .listRowBackground(Color.clear)
    }
}

struct StatisticCardView: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(12)
                        .background(color)
                        .clipShape(Circle())
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.largeTitle)
                        .fontDesign(.rounded)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationView {
        DashboardView(viewModel: TodoListViewModel(), imageViewerData: .constant(nil))
    }
}
