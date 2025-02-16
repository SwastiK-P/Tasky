import UIKit
import SwiftUI
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let viewModel = TodoListViewModel()
        
        let window = UIWindow(windowScene: windowScene)
        let contentView = ContentView(
            viewModel: viewModel,
            imageViewerData: .constant(nil)
        )
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
}

extension Notification.Name {
    static let showNewTaskSheet = Notification.Name("showNewTaskSheet")
    static let showTodayTasks = Notification.Name("showTodayTasks")
} 
