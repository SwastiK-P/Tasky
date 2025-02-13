import WidgetKit
import SwiftUI
import SharedModels

struct Provider: AppIntentTimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: WidgetConfiguration(), todos: [])
    }

    func snapshot(for configuration: WidgetConfiguration, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, todos: loadTodos(for: configuration.category))
    }

    func timeline(for configuration: WidgetConfiguration, in context: Context) async -> Timeline<SimpleEntry> {
        let todos = loadTodos(for: configuration.category)
        let entry = SimpleEntry(date: Date(), configuration: configuration, todos: todos)
        return Timeline(entries: [entry], policy: .atEnd)
    }
    
    private func loadTodos(for category: Category?) -> [TodoItem] {
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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: WidgetConfiguration
    let todos: [TodoItem]
}

struct HomeScreenWidget: Widget {
    let kind: String = "com.swastik.Something-New.homescreen"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WidgetConfiguration.self,
            provider: Provider()
        ) { entry in
            HomeScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tasks by Category")
        .description("View tasks from a specific category.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeScreenWidgetEntryView: View {
    var entry: Provider.Entry
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