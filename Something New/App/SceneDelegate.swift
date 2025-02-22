import UIKit
import SwiftUI
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Prepare haptics and sounds
        prepareHapticsAndSounds()
        
        // Initialize window immediately with a loading view
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let loadingView = LoadingView()
        window.rootViewController = UIHostingController(rootView: loadingView)
        window.makeKeyAndVisible()
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // Defer view model and content view setup
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay for smooth transition
            
            let viewModel = TodoListViewModel()
            let contentView = ContentView(
                viewModel: viewModel,
                imageViewerData: .constant(nil)
            )
            .environmentObject(ThemeManager.shared)
            
            withAnimation {
                window.rootViewController = UIHostingController(rootView: contentView)
            }
        }
    }
    
    private func prepareHapticsAndSounds() {
        // Prepare all haptic generators
        let softHaptic = UIImpactFeedbackGenerator(style: .soft)
        let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
        let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
        let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
        let notificationHaptic = UINotificationFeedbackGenerator()
        
        softHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        rigidHaptic.prepare()
        notificationHaptic.prepare()
        
        // Preload sounds by accessing shared instance
        _ = SoundManager.shared
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Tasky")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
}

extension Notification.Name {
    static let showNewTaskSheet = Notification.Name("showNewTaskSheet")
    static let showTodayTasks = Notification.Name("showTodayTasks")
} 
