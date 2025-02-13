import WidgetKit
import SwiftUI
import SharedModels
import AppIntents

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
        let currentDate = Date.now
        let entry = CategoryEntry(
            date: currentDate,
            configuration: configuration,
            todos: loadTodos(for: configuration.category)
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 15 * 60)))
        return timeline
    }
    
    private func loadTodos(for selectedCategory: Category?) -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New"),
              let data = userDefaults.data(forKey: "todos"),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        let incompleteTodos = todos.filter { !$0.isCompleted }
        if let category = selectedCategory {
            return incompleteTodos.filter { $0.category == category }
        }
        return incompleteTodos
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

// Rest of the CategoryWidget code... 