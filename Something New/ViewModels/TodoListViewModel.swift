import Foundation
import Combine
import SwiftUI
import SharedModels
import WidgetKit
import UserNotifications

final class TodoListViewModel: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var selectedCategory: Category?
    @Published var filters = TaskFilters()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    private var cancellables = Set<AnyCancellable>()
    @StateObject private var feedbackManager = FeedbackManager.shared
    
    init() {
        loadData()
        setupSubscriptions()
        setupNotifications()
    }
    
    private func setupSubscriptions() {
        $todos
            .sink { [weak self] _ in
                self?.saveTodos()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        // Observe when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.append(todo)
        saveTodos()
    }
    
    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            
            // If todo is completed and has a notification, remove it
            if todos[index].isCompleted, let notificationId = todos[index].notificationId {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
            }
            
            if todos[index].isCompleted {
                FeedbackManager.shared.playDoneSound()
            }
            saveTodos()
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
    
    func updateTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos()
            HapticManager.shared.impact(style: .medium)
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            userDefaults.set(encoded, forKey: "todos")
            userDefaults.synchronize()  // Force immediate UserDefaults sync
            
            // Force immediate widget updates using multiple methods
            WidgetCenter.shared.reloadAllTimelines()
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let widgets):
                    widgets.forEach { widget in
                        WidgetCenter.shared.reloadTimelines(ofKind: widget.kind)
                    }
                case .failure:
                    break
                }
            }
            
            // Invalidate widget cache
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removeObject(forKey: "\(bundleId).widget-cache")
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    private func loadData() {
        if let todosData = userDefaults.data(forKey: "todos"),
           let decodedTodos = try? JSONDecoder().decode([TodoItem].self, from: todosData) {
            // Update on main thread immediately
            todos = decodedTodos
        }
    }
    
    func todos(for category: Category) -> [TodoItem] {
        todos.filter { $0.category == category }
    }
    
    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }
    
    var completedTodos: [TodoItem] {
        todos.filter { $0.isCompleted }
    }
    
    var filteredAndSortedTodos: [TodoItem] {
        var result = activeTodos
        
        // Apply category filter
        if let category = filters.selectedCategory {
            result = result.filter { $0.category.rawValue == category.rawValue }
        }
        
        // Apply sort order
        switch filters.sortOrder {
        case .none:
            return result
        case .dueDate(let ascending):
            return result.sorted { first, second in
                let date1 = first.dueDate ?? (ascending ? Date.distantFuture : Date.distantPast)
                let date2 = second.dueDate ?? (ascending ? Date.distantFuture : Date.distantPast)
                return ascending ? date1 < date2 : date1 > date2
            }
        case .priority:
            return result.sorted { first, second in
                let p1 = priorityValue(first.priority)
                let p2 = priorityValue(second.priority)
                return p1 > p2
            }
        }
    }
    
    private func priorityValue(_ priority: TodoItem.Priority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
} 
