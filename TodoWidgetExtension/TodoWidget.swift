import WidgetKit
import SwiftUI
import SharedModels

// ... keep existing widget code ...

// Add new category widget
struct CategoryWidget: Widget {
    static let kind = "CategoryWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: WidgetConfiguration.self,
            provider: CategoryProvider()
        ) { entry in
            TodoWidgetView(entry: entry.toTodoEntry())
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Category Tasks")
        .description("View tasks from a specific category")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CategoryProvider: AppIntentTimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    func placeholder(in context: Context) -> CategoryEntry {
        CategoryEntry(
            date: .now,
            configuration: WidgetConfiguration(),
            todos: [
                TodoItem(title: "Loading tasks...", category: .personal, priority: .medium),
                TodoItem(title: "Please wait...", category: .personal, priority: .low)
            ]
        )
    }
    
    func snapshot(for configuration: WidgetConfiguration, in context: Context) async -> CategoryEntry {
        CategoryEntry(
            date: .now,
            configuration: configuration,
            todos: loadTodos(for: configuration.category)
        )
    }
    
    func timeline(for configuration: WidgetConfiguration, in context: Context) async -> Timeline<CategoryEntry> {
        let todos = loadTodos(for: configuration.category)
        let entry = CategoryEntry(
            date: .now,
            configuration: configuration,
            todos: todos
        )
        return Timeline(entries: [entry], policy: .after(.now.advanced(by: 15 * 60)))
    }
    
    private func loadTodos(for category: SharedModels.Category?) -> [TodoItem] {
        if let todosData = userDefaults.data(forKey: "todos"),
           let todos = try? JSONDecoder().decode([TodoItem].self, from: todosData) {
            let incompleteTodos = todos.filter { !$0.isCompleted }
            if let category = category {
                return incompleteTodos.filter { $0.category == category }
            }
            return incompleteTodos
        }
        return []
    }
}

struct CategoryEntry: TimelineEntry {
    let date: Date
    let configuration: WidgetConfiguration
    let todos: [TodoItem]
    
    func toTodoEntry() -> TodoEntry {
        TodoEntry(
            date: date,
            todos: todos,
            category: configuration.category
        )
    }
}

struct CategoryWidgetView: View {
    var entry: CategoryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.configuration.category?.rawValue ?? "All Tasks")
                    .font(.headline)
                Spacer()
                Text("\(entry.todos.count)")
                    .foregroundStyle(.secondary)
            }
            
            if entry.todos.isEmpty {
                Text("No tasks")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.todos.prefix(family == .systemSmall ? 2 : 4)) { todo in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(todo.category.color)
                            .frame(width: 8, height: 8)
                        Text(todo.title)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Widget Bundle
@main
struct TodoWidgets: WidgetBundle {
    var body: some Widget {
        TodoWidget()
        CategoryWidget()
    }
}

// MARK: - Widgets
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