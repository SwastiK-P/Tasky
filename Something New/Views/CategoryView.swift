import SwiftUI
import SharedModels

struct CategoryView: View {
    let category: Category 
    @ObservedObject var viewModel: TodoListViewModel
    @Binding var imageViewerData: ImageViewerData?
    @State private var showingAddSheet = false
    
    var filteredTodos: [TodoItem] {
        viewModel.todos
            .filter { $0.category == category && !$0.isCompleted }
            .sorted { todo1, todo2 in
                if let date1 = todo1.dueDate {
                    if let date2 = todo2.dueDate {
                        return date1 < date2
                    }
                    return true
                }
                return false
            }
    }
    
    var body: some View {
        Group {
            if filteredTodos.isEmpty {
                EmptyStateView1 (
                    icon: "checkmark.circle", title: "No Tasks Yet",
                    message: "Add task in \(category.rawValue) by tapping the + button"
                )
            } else {
                if !filteredTodos.isEmpty {
                    List {
                        ForEach(filteredTodos) { todo in
                            TodoRowView(
                                todo: todo,
                                toggleAction: { viewModel.toggleTodo(todo) },
                                viewModel: viewModel,
                                imageViewerData: $imageViewerData
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteTodo(todo)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .tint(.red)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarItems(trailing: addButton)
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView(viewModel: viewModel, preselectedCategory: category)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            FeedbackManager.shared.playHaptic(style: .medium)
            showingAddSheet = true
        }) {
            Image(systemName: "plus")
        }
    }
} 
