import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingAddTodo = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var showCompletedTodos = false
    @Binding var imageViewerData: ImageViewerData?
    @State private var currentDate = Date()
    @AppStorage("selectedIconStyle") private var selectedIconStyle = "Default"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var accentColor: Color = .black
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var isInitialized = false
    
    init(viewModel: TodoListViewModel, imageViewerData: Binding<ImageViewerData?>) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._imageViewerData = imageViewerData
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                todayTab
                dashboardTab
                todoListTab
            }
            .toolbarBackground(.thinMaterial, for: .tabBar)
            .tint(themeManager.currentColor)
            .onChange(of: selectedTab) { _ in
                FeedbackManager.shared.playHaptic(style: .light)
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: .init(
                get: { !hasSeenOnboarding && isInitialized },
                set: { hasSeenOnboarding = !$0 }
            )) {
                OnboardingView()
            }
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isInitialized = true
                updateAccentColor()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppStyleChanged"))) { notification in
                if let style = notification.userInfo?["style"] as? String {
                    withAnimation {
                        accentColor = getAccentColor(for: style)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showNewTaskSheet)) { _ in
                showingAddTodo = true
            }
            
            if authManager.isAppLocked && !authManager.isAuthenticated && isInitialized {
                LockView()
                    .transition(.opacity)
            }
        }
        .animation(.default, value: authManager.isAuthenticated)
        .onChange(of: scenePhase) { phase in
            if isInitialized {
                authManager.handleScenePhase(phase)
            }
        }
    }
    
    private func getAccentColor(for style: String) -> Color {
        switch style {
        case "Pink": return .pink
        case "Cyan": return .cyan
        default: return Color(.label)
        }
    }
    
    private func updateAccentColor() {
        accentColor = getAccentColor(for: selectedIconStyle)
    }
    
    private var dashboardTab: some View {
        NavigationStack {
            DashboardView(
                viewModel: viewModel,
                imageViewerData: $imageViewerData
            )
            .navigationTitle("Dashboard")
            .navigationBarItems(trailing: settingsButton)
        }
        .tabItem {
            Label("Dashboard", systemImage: "chart.bar.fill")
                .environment(\.colorScheme, .light)
        }
        .tag(1)
    }
    
    private var settingsButton: some View {
        Button {
            SoundManager.playSound("Open")
            FeedbackManager.shared.playHaptic(style: .medium)
            showingSettings = true
        } label: {
            Image(systemName: "gear")
                .foregroundColor(themeManager.currentColor)
        }
    }
    
    private var todoListTab: some View {
        NavigationStack {
            TodoListMainView(
                viewModel: viewModel,
                showingAddTodo: $showingAddTodo,
                showCompletedTodos: $showCompletedTodos,
                imageViewerData: $imageViewerData
            )
        }
        .tabItem {
            Label("Tasks", systemImage: "checkmark.circle.fill")
                .environment(\.colorScheme, .light)
        }
        .tag(2)
    }
    
    private var todayTab: some View {
        NavigationStack {
            TodayView(
                viewModel: viewModel
            )
        }
        .tabItem {
            Label("Today", systemImage: "\(Calendar.current.component(.day, from: currentDate)).circle.fill")
                .environment(\.colorScheme, .light)
        }
        .tag(0)
    }
}

#Preview {
    ContentView(
        viewModel: TodoListViewModel(),
        imageViewerData: .constant(nil)
    )
}
