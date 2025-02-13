import UIKit
import SwiftUI
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        QuickActionManager.shared.setupQuickActions()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Set up notification categories
        NotificationManager.shared.setupNotificationCategories()
        
        // Initialize required dependencies
        let viewModel = TodoListViewModel()
        
        let window = UIWindow(windowScene: windowScene)
        let contentView = ContentView(
            viewModel: viewModel,
            imageViewerData: .constant(nil)  // Pass nil binding since it's handled inside ContentView
        )
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case QuickAction.newTask.rawValue:
            NotificationCenter.default.post(name: .showNewTaskSheet, object: nil)
        case QuickAction.showToday.rawValue:
            NotificationCenter.default.post(name: .showTodayTasks, object: nil)
        default:
            break
        }
        completionHandler(true)
    }
    
    // Add notification delegate method
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.categoryIdentifier == "dailyReminder" &&
           (response.actionIdentifier == "addTodo" || response.actionIdentifier == UNNotificationDefaultActionIdentifier) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showNewTaskSheet, object: nil)
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let showNewTaskSheet = Notification.Name("showNewTaskSheet")
    static let showTodayTasks = Notification.Name("showTodayTasks")
} 
