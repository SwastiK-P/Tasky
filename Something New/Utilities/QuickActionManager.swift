import UIKit

enum QuickAction: String {
    case newTask = "newTask"
    case showToday = "showToday"
    
    var title: String {
        switch self {
        case .newTask: return "New Task"
        case .showToday: return "Today's Tasks"
        }
    }
    
    var icon: String {
        switch self {
        case .newTask: return "plus.circle.fill"
        case .showToday: return "calendar"
        }
    }
}

class QuickActionManager {
    static let shared = QuickActionManager()
    
    func setupQuickActions() {
        let newTaskAction = UIApplicationShortcutItem(
            type: QuickAction.newTask.rawValue,
            localizedTitle: QuickAction.newTask.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: QuickAction.newTask.icon),
            userInfo: nil
        )
        
        let todayAction = UIApplicationShortcutItem(
            type: QuickAction.showToday.rawValue,
            localizedTitle: QuickAction.showToday.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: QuickAction.showToday.icon),
            userInfo: nil
        )
        
        UIApplication.shared.shortcutItems = [newTaskAction, todayAction]
    }
} 