import SwiftUI
import WidgetKit
import AppIntents

struct SomethingNewApp: App {
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
            .overlay {
                if let data = imageViewerData {
                    ImageViewer(image: data.image)
                }
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
