//
//  TodayView.swift
//  Something New
//
//  Created by Swastik Patil on 2/15/25.
//

import SwiftUI
import EventKit

struct TodayView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var showingTodayTasks = false
    @State private var showingPriorityTasks = false
    @State private var showingOverdueTasks = false
    @State private var showingCalendarEvents = false
    @State private var showingTomorrowTasks = false
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
    
    private var completedTodayTasks: [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.todos.compactMap { todo in
            guard let completedDate = todo.completedDate,
                  completedDate >= today && completedDate < tomorrow,
                  todo.isCompleted else {
                return nil
            }
            return todo
        }
    }
    
    private var tomorrowTasks: [TodoItem] {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: tomorrow)!
        
        return viewModel.todos.compactMap { todo in
            guard let dueDate = todo.dueDate,
                  dueDate >= tomorrow && dueDate < dayAfter,
                  !todo.isCompleted else {
                return nil
            }
            return todo
        }
    }
    
    var todayTasks: [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.todos.compactMap { todo in
            guard let dueDate = todo.dueDate,
                  dueDate >= today && dueDate < tomorrow,
                  !todo.isCompleted else {
                return nil
            }
            return todo
        }
    }
    
    var priorityTasks: [TodoItem] {
        viewModel.todos.compactMap { todo in
            todo.priority == .high && !todo.isCompleted ? todo : nil
        }
    }
    
    var overdueTasks: [TodoItem] {
        let now = Date()
        return viewModel.todos.compactMap { todo in
            guard let dueDate = todo.dueDate,
                  dueDate < now,
                  !todo.isCompleted else {
                return nil
            }
            return todo
        }
    }
    
    private var navigationTitleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(timeBasedGreeting),")
                .font(.system(size: 34, weight: .bold))
            Text("Swastik")
                .font(.system(size: 34, weight: .bold))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            navigationTitleView
                .padding(.top, 32)
            
            SummaryTextView(
                viewModel: viewModel,
                timeOfDay: timeBasedGreeting,
                todayTasks: todayTasks,
                tomorrowTasks: tomorrowTasks,
                completedTasks: completedTodayTasks,
                priorityTasks: priorityTasks,
                overdueTasks: overdueTasks,
                calendarEvents: calendarManager.todayEvents,
                tomorrowEvents: calendarManager.tomorrowEvents,
                hasCalendarAccess: calendarManager.hasCalendarAccess,
                showingTodayTasks: $showingTodayTasks,
                showingTomorrowTasks: $showingTomorrowTasks,
                showingPriorityTasks: $showingPriorityTasks,
                showingOverdueTasks: $showingOverdueTasks,
                showingCalendarEvents: $showingCalendarEvents
            )
            Spacer()
        }
        .padding(.horizontal)
        .navigationBarHidden(true)
        
        .sheet(isPresented: $showingTodayTasks) {
            TaskListView(title: "Today's Tasks", tasks: todayTasks, viewModel: viewModel)
        }
        .sheet(isPresented: $showingPriorityTasks) {
            TaskListView(title: "Priority Tasks", tasks: priorityTasks, viewModel: viewModel)
        }
        .sheet(isPresented: $showingOverdueTasks) {
            TaskListView(title: "Overdue Tasks", tasks: overdueTasks, viewModel: viewModel)
        }
        .sheet(isPresented: $showingCalendarEvents) {
            CalendarEventsView(
                events: timeBasedGreeting == "Good Evening"
                    ? calendarManager.tomorrowEvents
                    : calendarManager.todayEvents
            )
        }
        .sheet(isPresented: $showingTomorrowTasks) {
            TaskListView(title: "Tomorrow's Tasks", tasks: tomorrowTasks, viewModel: viewModel)
        }
        .onAppear {
            if !calendarManager.hasCalendarAccess {
                calendarManager.requestAccess()
            }
        }
    }
}

struct SummaryTextView: View {
    @ObservedObject var viewModel: TodoListViewModel
    let timeOfDay: String
    let todayTasks: [TodoItem]
    let tomorrowTasks: [TodoItem]
    let completedTasks: [TodoItem]
    let priorityTasks: [TodoItem]
    let overdueTasks: [TodoItem]
    let calendarEvents: [EKEvent]
    let tomorrowEvents: [EKEvent]
    let hasCalendarAccess: Bool
    @Binding var showingTodayTasks: Bool
    @Binding var showingTomorrowTasks: Bool
    @Binding var showingPriorityTasks: Bool
    @Binding var showingOverdueTasks: Bool
    @Binding var showingCalendarEvents: Bool
    @State private var showingCompletedTasks = false
    
    var body: some View {
        let isEvening = timeOfDay == "Good Evening"
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        VStack(alignment: .leading, spacing: 16) {
            if isEvening {
                if viewModel.todos.isEmpty {
                    EmptyTodayView(
                        timeOfDay: timeOfDay,
                        hasCalendarAccess: hasCalendarAccess,
                        calendarEvents: tomorrowEvents,
                        showingCalendarEvents: $showingCalendarEvents
                    )
                } else {
                    // Completed Tasks
                    if !completedTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingCompletedTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("You've completed ")
                                            .foregroundColor(.secondary) +
                                        Text("\(completedTasks.count) \(completedTasks.count == 1 ? "task" : "tasks")")
                                            .foregroundColor(.green)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Tomorrow's Tasks
                    if !tomorrowTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingTomorrowTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Text(tomorrow, format: .dateTime.day())
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tomorrow you have ")
                                            .foregroundColor(.secondary) +
                                        Text("\(tomorrowTasks.count) \(tomorrowTasks.count == 1 ? "task" : "tasks")")
                                            .foregroundColor(.blue)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    if hasCalendarAccess && !tomorrowEvents.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingCalendarEvents = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.purple)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading) {
                                        Text("Tomorrow your calendar shows ")
                                            .foregroundColor(.secondary)
                                        Text("\(tomorrowEvents.count) \(tomorrowEvents.count == 1 ? "event" : "events")")
                                            .foregroundColor(.purple)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Priority Tasks
                    if !priorityTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingPriorityTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("There \(priorityTasks.count == 1 ? "is" : "are") ")
                                                .foregroundColor(.secondary) +
                                            Text("\(priorityTasks.count) high priority \(priorityTasks.count == 1 ? "task" : "tasks")")
                                                .foregroundColor(.red)
                                        }
                                        Text("that needs attention")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Overdue Tasks
                    if !overdueTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingOverdueTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    HStack {
                                        Text("From earlier ")
                                            .foregroundColor(.secondary) +
                                        Text("\(overdueTasks.count) \(overdueTasks.count == 1 ? "task is" : "tasks are") overdue")
                                            .foregroundColor(.orange)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            } else {
                if viewModel.todos.isEmpty {
                    EmptyTodayView(
                        timeOfDay: timeOfDay,
                        hasCalendarAccess: hasCalendarAccess,
                        calendarEvents: calendarEvents,
                        showingCalendarEvents: $showingCalendarEvents
                    )
                } else {
                    // Today's Tasks
                    if !todayTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingTodayTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Text(today, format: .dateTime.day())
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Today you have ")
                                            .foregroundColor(.secondary) +
                                        Text("\(todayTasks.count) \(todayTasks.count == 1 ? "task" : "tasks")")
                                            .foregroundColor(.blue)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Calendar Events
                    if hasCalendarAccess && !calendarEvents.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingCalendarEvents = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.purple)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    HStack {
                                        Text("Your calendar shows ")
                                            .foregroundColor(.secondary) +
                                        Text("\(calendarEvents.count) \(calendarEvents.count == 1 ? "event" : "events")")
                                            .foregroundColor(.purple)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Overdue Tasks
                    if !overdueTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingOverdueTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    HStack {
                                        Text("From earlier ")
                                            .foregroundColor(.secondary) +
                                        Text("\(overdueTasks.count) \(overdueTasks.count == 1 ? "task is" : "tasks are") overdue")
                                            .foregroundColor(.orange)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Priority Tasks
                    if !priorityTasks.isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingPriorityTasks = true
                        } label: {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("There \(priorityTasks.count == 1 ? "is" : "are") ")
                                                .foregroundColor(.secondary) +
                                            Text("\(priorityTasks.count) high priority \(priorityTasks.count == 1 ? "task" : "tasks")")
                                                .foregroundColor(.red)
                                        }
                                        Text("that needs attention")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .font(.system(size: 28))
        .fontWeight(.semibold)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $showingCompletedTasks) {
            TaskListView(title: "Completed Tasks", tasks: completedTasks, viewModel: viewModel)
        }
    }
}

struct EmptyTodayView: View {
    let timeOfDay: String
    let hasCalendarAccess: Bool
    let calendarEvents: [EKEvent]
    @Binding var showingCalendarEvents: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                
                Text("All Caught Up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You have no tasks for \(timeOfDay == "Good Evening" ? "tomorrow" : "today"). Take a moment to relax or plan ahead.")
                    .font(.
                          title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .padding(.bottom, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if hasCalendarAccess && !calendarEvents.isEmpty {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingCalendarEvents = true
                } label: {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text("Your calendar shows ")
                                    .foregroundColor(.secondary) +
                                Text("\(calendarEvents.count) \(calendarEvents.count == 1 ? "event" : "events")")
                                    .foregroundColor(.purple)
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct IconTextButton: View {
    let count: Int
    let iconName: String
    let color: Color
    var prefix: String = ""
    var suffix: String = ""
    var isEnabled: Bool
    var isSingular: Bool = false
    var useIsAre: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 2) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .frame(width: 24, height: 24)
                    )
                if !prefix.isEmpty {
                    Text("\(count) \(prefix) \(count == 1 ? "task" : "tasks")")
                        .foregroundColor(color)
                } else if useIsAre {
                    Text("\(count) \(count == 1 ? "task is" : "tasks are") \(suffix)")
                        .foregroundColor(color)
                } else {
                    Text("\(count) \(count == 1 ? (isSingular ? "event" : "task") : (isSingular ? "events" : "tasks"))")
                        .foregroundColor(color)
                }
            }
        }
        .disabled(!isEnabled)
    }
}

extension Text {
    func concatenating(_ text: Text) -> Text {
        self + text
    }
}

struct TaskInfoButton: View {
    let text: String
    let color: Color
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Text(text)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            )
        }
    }
}

struct TaskListView: View {
    let title: String
    let tasks: [TodoItem]
    @ObservedObject var viewModel: TodoListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(tasks) { todo in
                TodoRowView(
                    todo: todo,
                    toggleAction: { viewModel.toggleTodo(todo) },
                    viewModel: viewModel,
                    imageViewerData: .constant(nil)
                )
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CalendarEventsView: View {
    let events: [EKEvent]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(events, id: \.eventIdentifier) { event in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 6)
                        .frame(maxHeight: .infinity) // This makes it full height
                    
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                        if let location = event.location, !location.isEmpty {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text(event.startDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary) +
                        Text(" - ")
                            .font(.caption)
                            .foregroundColor(.secondary) +
                        Text(event.endDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 12)
                    .padding(.vertical, 8) // Add vertical padding for better spacing
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden) // Optional: hide separators for cleaner look
            }
            .navigationTitle("\(Calendar.current.isDateInToday(events.first?.startDate ?? Date()) ? "Today" : "Tomorrow")'s Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    TodayView(viewModel: TodoListViewModel())
}
