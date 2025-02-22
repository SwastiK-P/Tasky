import Foundation
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit
import ZIPFoundation

struct AppData: Codable {
    let todos: [TodoItem]
    let settings: AppSettings
    let version: String
    
    struct AppSettings: Codable {
        let defaultCategory: String
        let defaultPriority: String
        let hasSeenOnboarding: Bool
        let selectedIconStyle: String
        let appTheme: String
        let isAppLocked: Bool
        let isHapticsEnabled: Bool
        let isSoundEnabled: Bool
        let completionSound: String
        let isDailyReminderEnabled: Bool
        let dailyReminderTime: Date
    }
}

class DataManager: ObservableObject {
    static let shared = DataManager()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @Published private(set) var todos: [TodoItem] = []
    private let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    init() {
        loadData()
    }
    
    // Export data to a file
    func exportData() throws -> URL {
        // Create a temporary directory for the backup
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Get current data
        let todos = try getTodos()
        
        let settings = AppData.AppSettings(
            defaultCategory: UserDefaults.standard.string(forKey: "defaultCategory") ?? Category.personal.rawValue,
            defaultPriority: UserDefaults.standard.string(forKey: "defaultPriority") ?? TodoItem.Priority.medium.rawValue,
            hasSeenOnboarding: UserDefaults.standard.bool(forKey: "hasSeenOnboarding"),
            selectedIconStyle: UserDefaults.standard.string(forKey: "selectedIconStyle") ?? "Default",
            appTheme: UserDefaults.standard.string(forKey: "appTheme") ?? "Default",
            isAppLocked: UserDefaults.standard.bool(forKey: "isAppLocked"),
            isHapticsEnabled: UserDefaults.standard.bool(forKey: "hapticsEnabled"),
            isSoundEnabled: UserDefaults.standard.bool(forKey: "soundEnabled"),
            completionSound: UserDefaults.standard.string(forKey: "completionSound") ?? "Success",
            isDailyReminderEnabled: UserDefaults.standard.bool(forKey: "dailyReminderEnabled"),
            dailyReminderTime: UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date ?? Date()
        )
        
        let appData = AppData(
            todos: todos,
            settings: settings,
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        let data = try encoder.encode(appData)
        let dataFile = tempDir.appendingPathComponent("data.json")
        try data.write(to: dataFile)
        
        // Create final backup file
        let backupURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("TaskyBackup.taskybackup")
        
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        
        // Create archive data
        let archiveData = try createZipArchive(from: tempDir)
        try archiveData.write(to: backupURL)
        
        // Clean up temp directory
        try FileManager.default.removeItem(at: tempDir)
        
        return backupURL
    }
    
    // Import data from a file
    func importData(from url: URL) throws {
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Extract archive
        let archiveData = try Data(contentsOf: url)
        try extractZipArchive(archiveData, to: tempDir)
        
        // Read data file
        let dataFile = tempDir.appendingPathComponent("data.json")
        let data = try Data(contentsOf: dataFile)
        let appData = try decoder.decode(AppData.self, from: data)
        
        // Save settings first
        saveSettings(appData.settings)
        
        // Save todos to both UserDefaults suites
        let encodedData = try encoder.encode(appData.todos)
        UserDefaults.standard.set(encodedData, forKey: "todos")
        UserDefaults.standard.synchronize()
        
        userDefaults.set(encodedData, forKey: "todos")
        userDefaults.synchronize()
        
        // Update the published todos property
        DispatchQueue.main.async {
            self.todos = appData.todos
            
            // Post notification for immediate UI update
            NotificationCenter.default.post(name: .dataImported, object: nil)
            WidgetCenter.shared.reloadAllTimelines()
            
            // Force a save to both UserDefaults again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UserDefaults.standard.set(encodedData, forKey: "todos")
                UserDefaults.standard.synchronize()
                
                self.userDefaults.set(encodedData, forKey: "todos")
                self.userDefaults.synchronize()
            }
        }
        
        // Clean up temp directory
        try FileManager.default.removeItem(at: tempDir)
    }
    
    private func createZipArchive(from directory: URL) throws -> Data {
        let fileManager = FileManager.default
        var archiveData = Data()
        
        // Get all files in directory
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        
        // Create archive
        guard let archive = Archive(data: archiveData, accessMode: .create) else {
            throw NSError(domain: "DataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create archive"])
        }
        
        // Add all files to archive
        for fileURL in contents {
            let relativePath = fileURL.lastPathComponent
            try archive.addEntry(with: relativePath, fileURL: fileURL)
        }
        
        // Safely unwrap the archive data
        guard let data = archive.data else {
            throw NSError(domain: "DataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve archive data"])
        }
        
        return data
    }
    
    private func extractZipArchive(_ data: Data, to directory: URL) throws {
        guard let archive = Archive(data: data, accessMode: .read) else {
            throw NSError(domain: "DataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read archive"])
        }
        
        try archive.forEach { entry in
            let entryPath = directory.appendingPathComponent(entry.path)
            do {
                try archive.extract(entry, to: entryPath)
            } catch {
                print("Failed to extract entry: \(entry.path), error: \(error)")
            }
        }
    }
    
    private func loadData() {
        print("Loading todos from UserDefaults...")
        
        // Try loading from shared UserDefaults first
        if let todosData = userDefaults.data(forKey: "todos"),
           let decodedTodos = try? decoder.decode([TodoItem].self, from: todosData) {
            self.todos = decodedTodos
            print("Loaded \(self.todos.count) todos from shared UserDefaults.")
            return
        }
        
        // Fallback to standard UserDefaults
        if let todosData = UserDefaults.standard.data(forKey: "todos"),
           let decodedTodos = try? decoder.decode([TodoItem].self, from: todosData) {
            self.todos = decodedTodos
            print("Loaded \(self.todos.count) todos from standard UserDefaults.")
            
            // Save to shared UserDefaults for future use
            userDefaults.set(todosData, forKey: "todos")
            userDefaults.synchronize()
        } else {
            print("No todos found or failed to decode.")
            self.todos = []
        }
    }
    
    private func getTodos() throws -> [TodoItem] {
        return self.todos
    }
    
    private func saveTodos(_ todos: [TodoItem]) throws {
        print("Saving \(todos.count) todos to UserDefaults...")
        let encodedData = try encoder.encode(todos)
        
        // Save to both UserDefaults suites
        UserDefaults.standard.set(encodedData, forKey: "todos")
        UserDefaults.standard.synchronize()
        
        userDefaults.set(encodedData, forKey: "todos")
        userDefaults.synchronize()
        
        print("Todos saved successfully to both UserDefaults suites.")
        
        // Force widget update
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func saveSettings(_ settings: AppData.AppSettings) {
        UserDefaults.standard.set(settings.defaultCategory, forKey: "defaultCategory")
        UserDefaults.standard.set(settings.defaultPriority, forKey: "defaultPriority")
        UserDefaults.standard.set(settings.hasSeenOnboarding, forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(settings.selectedIconStyle, forKey: "selectedIconStyle")
        UserDefaults.standard.set(settings.appTheme, forKey: "appTheme")
        UserDefaults.standard.set(settings.isAppLocked, forKey: "isAppLocked")
        UserDefaults.standard.set(settings.isHapticsEnabled, forKey: "hapticsEnabled")
        UserDefaults.standard.set(settings.isSoundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(settings.completionSound, forKey: "completionSound")
        UserDefaults.standard.set(settings.isDailyReminderEnabled, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(settings.dailyReminderTime, forKey: "dailyReminderTime")
        
        // Force synchronize
        UserDefaults.standard.synchronize()
        
        // Update FeedbackManager settings
        FeedbackManager.shared.isHapticsEnabled = settings.isHapticsEnabled
        FeedbackManager.shared.isSoundEnabled = settings.isSoundEnabled
        if let sound = SoundEffect(rawValue: settings.completionSound) {
            FeedbackManager.shared.completionSound = sound
        }
        
        // Update daily reminder if needed
        if settings.isDailyReminderEnabled {
            NotificationManager.shared.scheduleDailyReminder(at: settings.dailyReminderTime)
        }
        
        // Post notification for theme change
        NotificationCenter.default.post(
            name: .appThemeChanged,
            object: nil,
            userInfo: ["style": settings.appTheme]
        )
        
        // Post notification for settings change
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}

// MARK: - Document Picker Support
extension UTType {
    static var taskyBackup: UTType {
        UTType(importedAs: "com.swastik.Something-New.backup", conformingTo: .data)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let dataImported = Notification.Name("dataImported")
    static let appThemeChanged = Notification.Name("appThemeChanged")
    static let settingsChanged = Notification.Name("settingsChanged")
} 
