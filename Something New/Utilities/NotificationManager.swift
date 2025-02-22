import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var showingAlert = false
    
    func checkNotificationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            completion(granted)
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Add this function to schedule daily reminders
    func scheduleDailyReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let isBeforeNoon = hour < 12
        
        content.title = isBeforeNoon ? "Plan Today's Tasks" : "Plan Tomorrow's Tasks"
        content.body = isBeforeNoon 
            ? "Take a moment to organize your day ahead"
            : "Take a moment to prepare for tomorrow"
        content.sound = .default
        
        // Add category identifier for handling the action
        content.categoryIdentifier = "dailyReminder"
        
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        UNUserNotificationCenter.current().add(request)
    }
    
    // Add this function to set up notification categories and actions
    func setupNotificationCategories() {
        let addAction = UNNotificationAction(
            identifier: "addTodo",
            title: "Add Todo",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "dailyReminder",
            actions: [addAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// Create a view modifier for the notification alert
struct NotificationAlertModifier: ViewModifier {
    @StateObject private var notificationManager = NotificationManager.shared
    @Binding var showAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Notifications Disabled", isPresented: $showAlert) {
                Button("Open Settings") {
                    notificationManager.openSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To enable reminders, go to Settings > Notifications > Tasky and turn on notifications.")
            }
    }
}

// Add extension to View for easier usage
extension View {
    func notificationAlert(isPresented: Binding<Bool>) -> some View {
        modifier(NotificationAlertModifier(showAlert: isPresented))
    }
} 