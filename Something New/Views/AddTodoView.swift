import SwiftUI
import UserNotifications
import PhotosUI
import SharedModels

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodoListViewModel
    @StateObject private var imageManager = ImageManager()
    @FocusState private var focusedField: Field?
    
    // Read defaults from UserDefaults
    @AppStorage("defaultCategory") private var defaultCategory = Category.personal.rawValue
    @AppStorage("defaultPriority") private var defaultPriority = TodoItem.Priority.medium.rawValue
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date = Date()
    @State private var dueTime: Date = Date()
    @State private var showDueDate = false
    @State private var showDueTime = false
    @State private var enableReminder = false
    @State private var reminderTime: ReminderTime = .atTime
    @State private var priority: TodoItem.Priority
    @State private var category: Category
    
    // Add state for notification status
    @State private var notificationStatus: UNAuthorizationStatus = .authorized
    
    // Add state for alert
    @State private var showingNotificationAlert = false
    
    // Add state for continuous mode
    @State private var isContinuousMode = false
    @State private var showingMenu = false
    
    let preselectedCategory: Category?
    
    enum ReminderTime: String, CaseIterable {
        case atTime = "At time"
        case fifteenMinutes = "15 minutes before"
        case thirtyMinutes = "30 minutes before"
        case oneHour = "1 hour before"
        case oneDay = "1 day before"
        
        var minuteOffset: Double {
            switch self {
            case .atTime: return 0
            case .fifteenMinutes: return -15
            case .thirtyMinutes: return -30
            case .oneHour: return -60
            case .oneDay: return -1440
            }
        }
    }
    
    enum Field {
        case title
        case notes
    }
    
    init(viewModel: TodoListViewModel, preselectedCategory: Category? = nil) {
        self.viewModel = viewModel
        self.preselectedCategory = preselectedCategory
        let defaultCat = UserDefaults.standard.string(forKey: "defaultCategory") ?? Category.personal.rawValue
        let defaultPri = UserDefaults.standard.string(forKey: "defaultPriority") ?? TodoItem.Priority.medium.rawValue
        _category = State(initialValue: Category(rawValue: defaultCat) ?? .personal)
        _priority = State(initialValue: TodoItem.Priority(rawValue: defaultPri) ?? .medium)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Set Due Date", isOn: $showDueDate)
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        
                        Toggle("Set Time", isOn: $showDueTime)
                        if showDueTime {
                            DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                            
                            Toggle("Enable Reminder", isOn: $enableReminder)
                                .disabled(notificationStatus == .denied)
                                .onChange(of: enableReminder) { newValue in
                                    if newValue {
                                        NotificationManager.shared.checkNotificationStatus { status in
                                            if status == .denied {
                                                enableReminder = false
                                                showingNotificationAlert = true
                                            } else if status == .notDetermined {
                                                NotificationManager.shared.requestNotificationPermission { granted in
                                                    if !granted {
                                                        enableReminder = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            
                            if enableReminder {
                                Picker("Remind me", selection: $reminderTime) {
                                    ForEach(ReminderTime.allCases, id: \.self) { time in
                                        Text(time.rawValue)
                                    }
                                }
                            }
                        }
                    }
                } footer: {
                    if showDueTime && notificationStatus == .denied {
                        Text("Notifications are disabled. Enable them in Settings to set reminders.")
                            .foregroundStyle(.orange)
                    }
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .tag(priority)
                        }
                    }
                    .frame(height: 36)
                    .onChange(of: priority) { _ in
                        FeedbackManager.shared.playHaptic(style: .light)
                    }
                }
                
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }
                    .frame(height: 36)
                    .onChange(of: category) { _ in
                        FeedbackManager.shared.playHaptic(style: .light)
                    }
                }
                
                Section("Images") {
                    if !imageManager.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(imageManager.selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: imageManager.selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button {
                                            imageManager.removeImage(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .black)
                                                .background(Circle().fill(.white))
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                    }
                    
                    if imageManager.selectedImages.count < 4 {
                        ImagePicker(selectedImages: .init(
                            get: { imageManager.selectedImages },
                            set: { images in
                                images.forEach { imageManager.addImage($0) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Todo")
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    addButton
                }
            }
            .notificationAlert(isPresented: $showingNotificationAlert)
        }
        .onAppear {
            NotificationManager.shared.checkNotificationStatus { status in
                notificationStatus = status
                if status == .denied {
                    enableReminder = false
                }
            }
            SoundManager.playSound("Open")  // Play sound when sheet opens
        }
    }
    
    private func addTodo(continuous: Bool = false) {
        let newTodo = TodoItem(
            title: title,
            dueDate: showDueDate ? dueDate : nil,
            dueTime: showDueTime ? dueTime : nil,
            category: category,
            notes: notes.isEmpty ? nil : notes,
            priority: priority,
            images: saveImages(),
            notificationId: enableReminder ? UUID().uuidString : nil
        )
        
        if enableReminder, let dueDate = newTodo.dueDate {
            scheduleNotification(for: newTodo, at: dueDate, with: newTodo.notificationId!)
        }
        
        viewModel.addTodo(newTodo)
        FeedbackManager.shared.playHaptic(style: .medium)
        
        if continuous {
            // Reset fields to default values
            title = ""
            notes = ""
            imageManager.selectedImages = []
            if let defaultCategory = Category(rawValue: UserDefaults.standard.string(forKey: "defaultCategory") ?? Category.personal.rawValue) {
                category = defaultCategory
            }
            if let defaultPriority = TodoItem.Priority(rawValue: UserDefaults.standard.string(forKey: "defaultPriority") ?? TodoItem.Priority.medium.rawValue) {
                priority = defaultPriority
            }
        } else {
            dismiss()
        }
    }
    
    var addButton: some View {
        Button {
            addTodo()
        } label: {
            Text("Add")
        }
        .disabled(title.isEmpty)
        .contextMenu {
            Button {
                addTodo()
            } label: {
                Label("Add Todo", systemImage: "plus.circle")
            }
            
            Button {
                addTodo(continuous: true)
            } label: {
                Label("Continuous Add", systemImage: "arrow.counterclockwise")
            }
        }
    }
    
    private func scheduleNotification(for todo: TodoItem, at date: Date, with id: String) {
        // Don't schedule if todo is already completed
        guard !todo.isCompleted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = todo.title
        if let notes = todo.notes {
            content.body = notes
        }
        content.sound = .default
        
        let reminderDate = Calendar.current.date(
            byAdding: .minute,
            value: Int(reminderTime.minuteOffset),
            to: date
        ) ?? date
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func saveImages() -> [String] {
        var imageNames: [String] = []
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            for image in imageManager.selectedImages {
                let imageName = UUID().uuidString + ".jpg"
                let imagePath = documentsPath.appendingPathComponent(imageName)
                
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    try? imageData.write(to: imagePath)
                    imageNames.append(imageName)
                }
            }
        }
        
        return imageNames
    }
    
    private func calculateFinalDueDate() -> Date? {
        var finalDueDate: Date?
        if showDueDate {
            finalDueDate = dueDate
            if showDueTime {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
                finalDueDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                          minute: timeComponents.minute ?? 0,
                                          second: 0,
                                          of: dueDate)
            }
        }
        return finalDueDate
    }
} 

#Preview {
    AddTodoView(viewModel: TodoListViewModel(), preselectedCategory: .personal)
}
