//
//  LockScreenWidget.swift
//  LockScreenWidget
//
//  Created by Swastik Patil on 2/11/25.
//

import WidgetKit
import SwiftUI
import SharedModels

struct Provider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todos: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todos: loadTodos())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), todos: loadTodos())
        
        // Create multiple entries for more frequent updates
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        for minuteOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            entries.append(SimpleEntry(date: entryDate, todos: loadTodos()))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadTodos() -> [TodoItem] {
        if let todosData = userDefaults.data(forKey: "todos") {
            do {
                let todos = try JSONDecoder().decode([TodoItem].self, from: todosData)
                let incompleteTodos = todos.filter { !$0.isCompleted }
                return Array(incompleteTodos) // Just show first 2 incomplete tasks
            } catch {
                print("Widget: Failed to decode todos: \(error)")
            }
        }
        return []
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct LockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    private var gaugeLimit: Double {
        let count = Double(entry.todos.count)
        return ceil(count / 10.0) * 10 // Rounds up to nearest 10
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(entry.todos.count), in: 0...gaugeLimit) {
                if entry.todos.count != 0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                }
            } currentValueLabel: {
                VStack() {
                    if entry.todos.count == 0 {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .font(.system(size: 16, weight: .medium))
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                    } else {
                        Text("\(entry.todos.count)")
                            .font(.system(size: 16, weight: .medium))
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                    }
                }
                .minimumScaleFactor(0.6)
            }
            .gaugeStyle(.accessoryCircular)
            .containerBackground(.fill.tertiary, for: .widget)
            
        case .accessoryRectangular:
            RectangularLockScreenView(todos: entry.todos)
            
        case .accessoryInline:
            if let firstTodo = entry.todos.first {
                if let dueDate = firstTodo.dueDate,
                   Calendar.current.isDate(Calendar.current.startOfDay(for: dueDate),
                                         inSameDayAs: Calendar.current.startOfDay(for: Date())) {
                    Text("\(entry.todos.count) Task Today ")
                } else {
                    Text("\(entry.todos.count) Tasks")
                }
            } else {
                Text("All Clear for today")
            }
            
        default:
            EmptyView()
        }
    }
}

struct RectangularLockScreenView: View {
    let todos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tasks")
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)
                Spacer()
            }
            HStack {
                if todos.isEmpty {
                    Text("All Clear!")
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(todos.prefix(2)) { todo in
                            HStack(spacing: 4) {
                                Image(systemName: "circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 10, height: 10)
                                Text(todo.title)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LockScreenWidget: Widget {
    let kind: String = "com.swastik.Something-New.lockscreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tasks")
        .description("View your upcoming tasks.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview("Circular", as: .accessoryCircular) {
    LockScreenWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoItem(title: "Task 1", category: .personal, priority: .medium),
        TodoItem(title: "Task 2", category: .work, priority: .high)
    ])
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoItem(title: "Task 1", category: .personal, priority: .medium),
        TodoItem(title: "Task 2", category: .work, priority: .high)
    ])
}

#Preview("Inline", as: .accessoryInline) {
    LockScreenWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoItem(title: "Task 1", category: .personal, priority: .medium),
        TodoItem(title: "Task 2", category: .work, priority: .high)
    ])
}
