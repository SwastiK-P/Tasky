import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        QuickActionManager.shared.setupQuickActions()
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
}

extension Notification.Name {
    static let showNewTaskSheet = Notification.Name("showNewTaskSheet")
    static let showTodayTasks = Notification.Name("showTodayTasks")
} 