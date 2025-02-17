import WidgetKit
import SwiftUI
import SharedModels

struct LockScreenProvider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), todos: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> ()) {
        let todos = loadTodos()
        print("Widget snapshot: Found \(todos.count) todos")
        let entry = LockScreenEntry(date: Date(), todos: todos)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> ()) {
        let currentDate = Date()
        let todos = loadTodos()
        print("Widget timeline: Found \(todos.count) todos")
        
        // Create a single entry that updates frequently
        let entry = LockScreenEntry(date: currentDate, todos: todos)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadTodos() -> [TodoItem] {
        do {
            guard let todosData = userDefaults.data(forKey: "todos") else {
                print("Widget: No data in UserDefaults")
                return []
            }
            
            let todos = try JSONDecoder().decode([TodoItem].self, from: todosData)
            let incompleteTodos = todos.filter { !$0.isCompleted }
            print("Widget: Successfully loaded \(incompleteTodos.count) incomplete todos")
            return incompleteTodos
        } catch {
            print("Widget: Failed to decode todos - \(error)")
            return []
        }
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LockScreenEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(todos: entry.todos)
        case .accessoryRectangular:
            RectangularLockScreenView(todos: entry.todos)
        case .accessoryInline:
            InlineLockScreenView(todos: entry.todos)
        default:
            EmptyView()
        }
    }
}

struct CircularLockScreenView: View {
    let todos: [TodoItem]
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "checklist")
                    .font(.system(size: 12))
                Text("\(todos.count)")
                    .font(.system(size: 16, weight: .medium))
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

struct RectangularLockScreenView: View {
    let todos: [TodoItem]
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(alignment: .leading, spacing: 4) {
                ForEach(todos.prefix(2)) { todo in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(todo.category.color)
                            .frame(width: 8, height: 8)
                        Text(todo.title)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
                
                if todos.isEmpty {
                    Text("No tasks")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct InlineLockScreenView: View {
    let todos: [TodoItem]
    
    var body: some View {
        if let firstTodo = todos.first {
            Text("\(todos.count) tasks • \(firstTodo.title)")
        } else {
            Text("No tasks")
        }
    }
}

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Tasks")
        .description("View your upcoming tasks.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
} 
