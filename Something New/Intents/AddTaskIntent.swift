import AppIntents
import WidgetKit
import SharedModels

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = "Add a new task to your list"
    
    @Parameter(title: "Task Title")
    var taskTitle: String
    
    @Parameter(title: "Category")
    var category: String
    
    init() {
        self.taskTitle = ""
        self.category = Category.personal.rawValue
    }
    
    init(taskTitle: String, category: String) {
        self.taskTitle = taskTitle
        self.category = category
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to \(\.$category)")
    }
    
    // Add more specific phrases
    static var siriShortcutPhrases: [LocalizedStringResource] {
        [
            "Do It",
            "Add to Do It",
            "Add task to Do It",
            "Create task in Do It",
            "New Do It task"
        ]
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresAuthentication
    }
    
    static var openAppWhenRun: Bool = false
    
    static var isDiscoverable: Bool = true
    
    static var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Add Task to Do It",
            subtitle: "Creates a new task in your list"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Add Task",
            subtitle: "Add '\(taskTitle)' to \(category)"
        )
    }
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")
        
        // Create new task
        let newTask = TodoItem(
            title: taskTitle,
            category: Category(rawValue: category) ?? .personal,
            priority: .medium
        )
        
        // Load existing tasks
        var todos: [TodoItem] = []
        if let data = userDefaults?.data(forKey: "todos"),
           let existingTodos = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = existingTodos
        }
        
        // Add new task
        todos.append(newTask)
        
        // Save updated tasks
        if let encoded = try? JSONEncoder().encode(todos) {
            userDefaults?.set(encoded, forKey: "todos")
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
}

struct CategoryOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        return Category.allCases.map { $0.rawValue }
    }
    
    // Add display names for better Siri interaction
    func displayName(for value: String) -> String {
        switch value {
        case Category.personal.rawValue: return "Personal Tasks"
        case Category.work.rawValue: return "Work Tasks"
        case Category.college.rawValue: return "College Tasks"
        default: return value
        }
    }
}

// Add Shortcut support
extension AddTaskIntent {
    static var shortTitle: LocalizedStringResource = "Add to Do It"
    static var intent: AddTaskIntent { AddTaskIntent() }
} 
