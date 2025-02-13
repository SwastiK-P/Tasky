import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var feedbackManager = FeedbackManager.shared
    @AppStorage("appTheme") private var appTheme = "Default"
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCategory") private var defaultCategory = Category.personal.rawValue
    @AppStorage("defaultPriority") private var defaultPriority = TodoItem.Priority.medium.rawValue
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var heartTapped = false
    
    private let themes = [
        AppTheme(name: "Default", color: .black, darkModeColor: .white, iconName: "AppIcon-Preview"),
        AppTheme(name: "Pink", color: .pink, iconName: "Pink-Preview"),
        AppTheme(name: "Cyan", color: .cyan, iconName: "Cyan-Preview")
    ]
    
    private let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    var body: some View {
        NavigationView {
            List {
                feedbackSection
                defaultsSection
                themeSection
                aboutSection
                securitySection
                shortcutsSection
            }
            .navigationTitle("Settings")
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(themeManager.currentColor)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var feedbackSection: some View {
        Section {
            SettingToggleRow(
                title: "Haptic Feedback",
                icon: "water.waves",
                isOn: $feedbackManager.isHapticsEnabled
            )
            .onChange(of: feedbackManager.isHapticsEnabled) { _ in
                feedbackManager.playHaptic(style: .rigid)
            }
            
            SettingToggleRow(
                title: "Sound Effects",
                icon: "speaker.wave.2",
                isOn: $feedbackManager.isSoundEnabled
            )
            .onChange(of: feedbackManager.isSoundEnabled) { _ in
                feedbackManager.playHaptic(style: .rigid)
            }
        } header: {
            Text("Feedback")
        }
    }
    
    private var defaultsSection: some View {
        Section("Defaults") {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .frame(width: 25)
                Text("Default Category")
                Spacer()
                Text(defaultCategory)
                    .foregroundStyle(themeManager.currentColor)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(themeManager.currentColor)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .overlay {
                Picker("", selection: $defaultCategory) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Text(category.rawValue)
                            .tag(category.rawValue)
                    }
                }
                .opacity(0.02)
            }
            .onChange(of: defaultCategory) { _ in
                feedbackManager.playHaptic(style: .light)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .frame(width: 25)
                Text("Default Priority")
                Spacer()
                Text(defaultPriority.capitalized)
                    .foregroundStyle(themeManager.currentColor)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(themeManager.currentColor)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .overlay {
                Picker("", selection: $defaultPriority) {
                    ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized)
                            .tag(priority.rawValue)
                    }
                }
                .opacity(0.02)
            }
            .onChange(of: defaultPriority) { _ in
                feedbackManager.playHaptic(style: .light)
            }
            
            if feedbackManager.isSoundEnabled == true {
                
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .frame(width: 25)
                    Text("Completion Sound")
                    Spacer()
                    Text(feedbackManager.completionSound.displayName)
                        .foregroundStyle(themeManager.currentColor)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(themeManager.currentColor)
                }
                .frame(height: 28)
                .contentShape(Rectangle())
                .overlay {
                    Picker("", selection: $feedbackManager.completionSound) {
                        ForEach(SoundEffect.completionSounds, id: \.self) { sound in
                            Text(sound.displayName)
                                .tag(sound)
                        }
                    }
                    .opacity(0.02)
                    .onChange(of: feedbackManager.completionSound) { newValue in
                        feedbackManager.previewCompletionSound(newValue)
                    }
                }
            }
        }
    }
    
    private var themeSection: some View {
        Section("App Theme") {
            ForEach(themes, id: \.name) { theme in
                ThemeRow(
                    theme: theme,
                    isSelected: appTheme == theme.name,
                    action: {
                        feedbackManager.playHaptic(style: .soft)
                        changeTheme(to: theme)
                    }
                )
            }
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .frame(width: 25)
                Text("Version")
                Spacer()
                Text(Bundle.main.appVersion)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    heartTapped.toggle()
                }
                feedbackManager.playHaptic(style: .soft)
                
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        heartTapped = false
                    }
                }
            } label: {
                HStack {
                    Image(systemName: heartTapped ? "heart.fill" : "heart")
                        .foregroundStyle(.red)
                        .frame(width: 25)
                        .scaleEffect(heartTapped ? 1.3 : 1.0)
                    Text("Made by Swastik")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("About")
        }
    }
    
    private var shortcutsSection: some View {
        Section {
            HStack {
                Image(systemName: "wand.and.stars")
                    .frame(width: 25)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Siri Integration")
                    Text("Available in upcoming updates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Coming Soon")
        } footer: {
            Text("Add tasks quickly using Siri when developer account is set up")
        }
    }
    
    private var securitySection: some View {
        Section {
            if authManager.canUseBiometrics {
                SettingToggleRow(
                    title: "Lock App",
                    icon: "faceid",
                    isOn: .init(
                        get: { authManager.isAppLocked },
                        set: { _ in
                            feedbackManager.playHaptic(style: .rigid)
                            authManager.toggleAppLock()
                        }
                    )
                )
                
                if authManager.isAppLocked {
                    SettingToggleRow(
                        title: "Lock Immediately",
                        icon: "clock",
                        isOn: .init(
                            get: { authManager.lockImmediately },
                            set: { _ in
                                feedbackManager.playHaptic(style: .rigid)
                                authManager.toggleLockTiming()
                            }
                        )
                    )
                }
            }
        } header: {
            Text("Security")
        } footer: {
            if authManager.canUseBiometrics {
                Text("Lock your app with \(authManager.biometricType) for added security")
            }
        }
    }
    
    private func changeTheme(to theme: AppTheme) {
        appTheme = theme.name
        NotificationCenter.default.post(
            name: .appThemeChanged,
            object: nil,
            userInfo: ["theme": theme]
        )
    }
    
    private func updateHapticsSetting(isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: "hapticsEnabled")
    }
}

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPreview = false
    @State private var isPressed = false
    @StateObject private var feedbackManager = FeedbackManager.shared
    
    var themeColor: Color {
        if theme.name == "Default" && colorScheme == .dark {
            return theme.darkModeColor
        }
        return theme.color
    }
    
    var body: some View {
        HStack {
            Button {
                feedbackManager.playHaptic(style: .medium)
                action()
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(width: 40, height: 40)
                        
                        VStack(spacing: 4) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(themeColor)
                                    .frame(width: 25, height: 5)
                            }
                        }
                    }
                    
                    Text(theme.name)
                        .padding(.leading)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(themeColor)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                feedbackManager.playHaptic(style: .soft)
                
                // Reset animation and show preview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                    showingPreview = true
                }
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(themeColor)
                    .scaleEffect(isPressed ? 0.8 : 1.0)
            }
            .padding(.leading, 8)
        }
        .sheet(isPresented: $showingPreview) {
            ThemePreviewModal(
                theme: theme,
                applyTheme: {
                    withAnimation {
                        action()
                    }
                }
            )
            .presentationBackground(.clear)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(350)])
        }
    }
}

struct AppTheme {
    let name: String
    let color: Color
    let darkModeColor: Color
    let iconName: String
    
    init(name: String, color: Color, darkModeColor: Color? = nil, iconName: String) {
        self.name = name
        self.color = color
        self.darkModeColor = darkModeColor ?? color
        self.iconName = iconName
    }
}

// Add back the SettingToggleRow
struct SettingToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    @Binding var isOn: Bool
    @StateObject private var feedbackManager = FeedbackManager.shared
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 25)
                if let subtitle = subtitle {
                    VStack(alignment: .leading) {
                        Text(title)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(title)
                }
            }
        }
        .onChange(of: isOn) { _ in
            feedbackManager.playHaptic(style: .rigid)
        }
    }
}

extension Notification.Name {
    static let appThemeChanged = Notification.Name("appThemeChanged")
}

// Helper extension to get app version
extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "\(version)"
    }
}

struct ThemedPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [String]
    let capitalized: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 25)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(capitalized ? option.capitalized : option)
                        .tag(option)
                }
            }
            .tint(themeManager.currentColor)
        }
        .frame(height: 28)
    }
}
