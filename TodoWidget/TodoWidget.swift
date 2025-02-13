//
//  TodoWidget.swift
//  TodoWidget
//
//  Created by Swastik Patil on 2/9/25.
//

import WidgetKit
import SwiftUI
import SharedModels
import AppIntents
import Intents

// MARK: - Widget Entry
struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
    let category: SharedModels.Category?
}

// MARK: - Widget Provider
struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(
            date: .now,
            todos: [
                TodoItem(title: "Loading tasks...", category: .personal, priority: .medium),
                TodoItem(title: "Please wait...", category: .personal, priority: .low)
            ],
            category: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let entry = TodoEntry(date: .now, todos: loadTodos(), category: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let currentDate = Date.now
        let entry = TodoEntry(date: currentDate, todos: loadTodos(), category: nil)
        let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 15 * 60)))
        completion(timeline)
    }
    
    private func loadTodos() -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New"),
              let data = userDefaults.data(forKey: "todos"),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return todos.filter { !$0.isCompleted }
    }
}

// MARK: - Toggle Intent
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    
    @Parameter(title: "Todo ID")
    var todoId: String
    
    init() {
        self.todoId = ""
    }
    
    init(todoId: String) {
        self.todoId = todoId
    }
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")
        
        guard let id = UUID(uuidString: todoId),
              let data = userDefaults?.data(forKey: "todos"),
              var todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return .result()
        }
        
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
            
            if let encoded = try? JSONEncoder().encode(todos) {
                userDefaults?.set(encoded, forKey: "todos")
                
                let hapticsEnabled = userDefaults?.bool(forKey: "hapticsEnabled") ?? true
                if hapticsEnabled {
                    await MainActor.run {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        #endif
                    }
                }
                
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        return .result()
    }
}

// MARK: - Button Modifier
struct ButtonModifier: ViewModifier {
    let intent: ToggleTodoIntent
    
    func body(content: Content) -> some View {
        Button(intent: intent) {
            content
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Views
struct SmallWidgetView: View {
    let entry: TodoEntry
    @Environment(\.colorScheme) var colorScheme
    
    private var limitedTodos: [TodoItem] {
        Array(entry.todos.prefix(3))  // Limit to 3 tasks
    }
    
    var body: some View {
        if entry.todos.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category?.rawValue ?? "All Tasks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No tasks")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //.background(Color.widgetBackground)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.category?.rawValue ?? "All Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(entry.todos.count)")  // Show total count
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.taskBackground)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(limitedTodos) { todo in
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(categoryColor(for: todo.category))
                                .padding(.leading, 4)
                            Text(todo.title)
                                .lineLimit(1)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.taskBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(categoryColor(for: todo.category))
                                        .opacity(0.1)
                                )
                        )
                        .modifier(ButtonModifier(intent: ToggleTodoIntent(todoId: todo.id.uuidString)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            //.background(Color.widgetBackground)
        }
    }
    
    private func categoryColor(for category: SharedModels.Category) -> Color {
        switch category {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        }
    }
}

struct MediumWidgetView: View {
    let entry: TodoEntry
    @Environment(\.colorScheme) var colorScheme
    
    private var limitedTodos: [TodoItem] {
        Array(entry.todos.prefix(3))  // Limit to 3 tasks
    }
    
    var body: some View {
        if entry.todos.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category?.rawValue ?? "All Tasks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No tasks")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //.background(Color.widgetBackground)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.category?.rawValue ?? "All Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(entry.todos.count)")  // Show total count
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.taskBackground)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(limitedTodos) { todo in
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(categoryColor(for: todo.category))
                                .padding(.leading, 4)
                            Text(todo.title)
                                .lineLimit(1)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.taskBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(categoryColor(for: todo.category))
                                        .opacity(0.1)
                                )
                        )
                        .modifier(ButtonModifier(intent: ToggleTodoIntent(todoId: todo.id.uuidString)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            //.background(Color.widgetBackground)
        }
    }
    
    private func categoryColor(for category: SharedModels.Category) -> Color {
        switch category {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        }
    }
}

struct LargeWidgetView: View {
    let entry: TodoEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if entry.todos.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category?.rawValue ?? "All Tasks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No tasks")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //.background(Color.widgetBackground)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.category?.rawValue ?? "All Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(entry.todos.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.taskBackground)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.todos.prefix(7))) { todo in
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(categoryColor(for: todo.category))
                                .padding(.leading, 4)
                            Text(todo.title)
                                .lineLimit(1)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.taskBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(categoryColor(for: todo.category))
                                        .opacity(0.1)
                                )
                        )
                        .modifier(ButtonModifier(intent: ToggleTodoIntent(todoId: todo.id.uuidString)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            //.background(Color.widgetBackground)
        }
    }
    
    private func categoryColor(for category: SharedModels.Category) -> Color {
        switch category {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        @unknown default:
            return .black
        }
    }
}

// MARK: - Main Widget View
struct TodoWidgetView: View {
    let entry: TodoEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition
@main
struct TodoWidget: Widget {
    static let kind = "TodoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TodoProvider()) { entry in
            TodoWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Todo List")
        .description("View your tasks at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Colors
extension Color {
    static let widgetBackground = Color(.systemBackground)
    static let taskBackground = Color(.secondarySystemBackground)
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(
        date: .now,
        todos: [
            TodoItem(title: "Study for exam", category: .college, priority: .high),
            TodoItem(title: "Team meeting", category: .personal, priority: .medium),
            TodoItem(title: "Call home", category: .work, priority: .low)
        ],
        category: nil
    )
}

