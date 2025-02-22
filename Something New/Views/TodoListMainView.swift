import SwiftUI

struct TodoListMainView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Binding var showingAddTodo: Bool
    @Binding var showCompletedTodos: Bool
    @Binding var imageViewerData: ImageViewerData?
    
    var body: some View {
        Group {
            if viewModel.todos.isEmpty {
                EmptyStateView1(
                    icon: "checkmark.circle", title: "No Tasks Yet",
                    message: "Add your first task by tapping the + button"
                )
            } else {
                todoList
            }
        }.navigationTitle("Tasks")
            .navigationBarItems(trailing: addButton)
            .toolbarBackground(.automatic, for: .navigationBar)
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddTodo = true
            FeedbackManager.shared.playHaptic(style: .medium)
        }) {
            Image(systemName: "plus")
        }
    }
    
    private var todoList: some View {
        List {
            activeTodosSection
            completedTodosSection
        }
    }
    
    private var activeTodosSection: some View {
        ForEach(viewModel.filteredAndSortedTodos) { todo in
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
                }
                .tint(.red)
            }
        }
    }
    
    private var completedTodosSection: some View {
        Group {
            if !viewModel.completedTodos.isEmpty {
                Section {
                    if showCompletedTodos {
                        ForEach(viewModel.completedTodos) { todo in
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
                                }
                                .tint(.red)
                            }
                        }
                    }
                } header: {
                    CompletedSectionHeader(
                        count: viewModel.completedTodos.count,
                        isExpanded: $showCompletedTodos
                    )
                }
                .listSectionSpacing(.compact)
                .listRowBackground(Color(.systemGray6))
            }
        }
    }
} 
