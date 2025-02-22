import SwiftUI
import UserNotifications

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodoListViewModel
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var dueTime: Date
    @State private var showDueDate: Bool
    @State private var showDueTime: Bool
    @State private var enableReminder: Bool
    @State private var reminderTime: AddTodoView.ReminderTime = .atTime
    @State private var priority: TodoItem.Priority
    @State private var category: Category
    @State private var selectedImages: [UIImage] = []
    @State private var existingImages: [String] = []
    @State private var notificationStatus: UNAuthorizationStatus = .authorized
    @State private var showingNotificationAlert = false
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var location: TodoItem.Location?
    @FocusState private var isNotesFocused: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    let todo: TodoItem
    
    init(todo: TodoItem, viewModel: TodoListViewModel) {
        self.todo = todo
        self.viewModel = viewModel
        
        // Initialize state with todo values
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes ?? "")
        _dueDate = State(initialValue: todo.dueDate ?? Date())
        _dueTime = State(initialValue: todo.dueTime ?? Date())
        _showDueDate = State(initialValue: todo.dueDate != nil)
        _showDueTime = State(initialValue: todo.dueTime != nil)
        _enableReminder = State(initialValue: todo.notificationId != nil)
        _priority = State(initialValue: todo.priority)
        _category = State(initialValue: todo.category)
        _existingImages = State(initialValue: todo.images ?? [])
        _location = State(initialValue: todo.location)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isNotesFocused)
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
                                    ForEach(AddTodoView.ReminderTime.allCases, id: \.self) { time in
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
                            .onTapGesture {
                                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(appSettings)
                                }
                            }
                    }
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
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
                
                Section {
                    if let location = location {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(location.name)
                                .font(.headline)
                            
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(role: .destructive) {
                            FeedbackManager.shared.playHaptic(style: .light)
                            self.location = nil
                        } label: {
                            HStack {
                                Text("Remove Location")
                                Spacer()
                            }
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        Button("Add Location") {
                            showingLocationPicker = true
                        }
                    }
                } header: {
                    Text("Location")
                }
                
                
                Section("Images") {
                    // Show existing images
                    if !existingImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(existingImages, id: \.self) { imageName in
                                    if let image = loadImage(named: imageName) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button {
                                                if let index = existingImages.firstIndex(of: imageName) {
                                                    existingImages.remove(at: index)
                                                    deleteImage(named: imageName)
                                                }
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
                    }
                    
                    // Show newly selected images
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button {
                                            selectedImages.remove(at: index)
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
                    
                    if existingImages.count + selectedImages.count < 4 {
                        ImagePicker(selectedImages: $selectedImages)
                    }
                }
            }
            .tint(themeManager.currentColor)
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTodoWithNotification()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPicker(selectedLocation: $location)
        }
        .onAppear {
            NotificationManager.shared.checkNotificationStatus { status in
                notificationStatus = status
                if status == .denied {
                    enableReminder = false
                }
            }
        }
        .notificationAlert(isPresented: $showingNotificationAlert)
    }
    
    private func loadImage(named: String) -> UIImage? {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imagePath = documentsPath.appendingPathComponent(named)
            return UIImage(contentsOfFile: imagePath.path)
        }
        return nil
    }
    
    private func saveImages() -> [String] {
        var imageNames: [String] = []
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access documents directory")
            return []
        }
        
        for image in selectedImages {
            let imageName = UUID().uuidString + ".jpg"
            let imagePath = documentsPath.appendingPathComponent(imageName)
            
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                do {
                    try imageData.write(to: imagePath)
                    imageNames.append(imageName)
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            }
        }
        
        return imageNames
    }
    
    private func deleteImage(named: String) {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imagePath = documentsPath.appendingPathComponent(named)
            try? FileManager.default.removeItem(at: imagePath)
        }
    }
    
    private func updateTodoWithNotification() {
        // Remove existing notification if any
        if let oldNotificationId = todo.notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [oldNotificationId])
        }
        
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
        
        let notificationId = enableReminder ? UUID().uuidString : nil
        
        // Save new images and combine with existing ones
        let newImageNames = saveImages()
        let allImages = existingImages + newImageNames
        
        var updatedTodo = TodoItem(
            id: todo.id,
            title: title,
            isCompleted: todo.isCompleted,
            dueDate: finalDueDate,
            dueTime: showDueTime ? dueTime : nil,
            category: category,
            notes: notes,
            priority: priority,
            images: allImages,
            notificationId: notificationId,
            completedDate: todo.completedDate,
            workSessions: todo.workSessions,
            location: location
        )
        
        if enableReminder, let dueDate = finalDueDate {
            scheduleNotification(for: updatedTodo, at: dueDate, with: notificationId!)
        }
        
        viewModel.updateTodo(updatedTodo)
        dismiss()
    }
    
    private func scheduleNotification(for todo: TodoItem, at date: Date, with id: String) {
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
} 
