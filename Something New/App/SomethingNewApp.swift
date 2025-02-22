import SwiftUI
import WidgetKit
import AppIntents
import UIKit

@main
struct SomethingNewApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = TodoListViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var imageViewerData: ImageViewerData?
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: viewModel,
                imageViewerData: $imageViewerData
            )
            .tint(themeManager.currentColor)
            .environmentObject(themeManager)
            .environmentObject(authManager)
            .onReceive(NotificationCenter.default.publisher(for: .appThemeChanged)) { _ in
                themeManager.updateTheme()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                themeManager.handleTraitCollectionChange()
            }
            .sheet(item: $imageViewerData) { data in
                ImageViewer(image: data.image)
                    .environmentObject(themeManager)
            }
            .onOpenURL { url in
                // Handle deep links if needed
            }
            .onContinueUserActivity("") { _ in
                // Handle user activities if needed
            }
        }
    }
}


struct WidgetConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedWidgetCategory", store: UserDefaults(suiteName: "group.com.swastik.Something-New"))
    private var selectedCategory: String?
    
    var body: some View {
        NavigationView {
            List {
                Button("All Categories") {
                    selectedCategory = nil
                    WidgetCenter.shared.reloadAllTimelines()
                    dismiss()
                }
                
                ForEach(Category.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        selectedCategory = category.rawValue
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Widget Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Make ImageViewerData conform to Identifiable
extension ImageViewerData: Identifiable {
    var id: String {
        image.hashValue.description
    }
} 
