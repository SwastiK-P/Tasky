import Foundation
import SwiftUI
import UserNotifications
import Combine

@MainActor
final class WorkSessionViewModel: ObservableObject {
    @Published var currentSession: WorkSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive = false
    @Published var showCompletionAlert = false
    @Published var isPaused = false
    @Published private(set) var isCompleted = false
    
    private var startTime: Date?
    private var elapsedTimeWhenPaused: TimeInterval = 0
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        restoreState()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    func startSession(for todoId: UUID, duration: TimeInterval = 25 * 60) {
        // Clear any existing session first
        resetSession()
        
        let session = WorkSession(todoId: todoId, duration: duration)
        currentSession = session
        timeRemaining = duration
        startTime = Date().addingTimeInterval(-elapsedTimeWhenPaused)
        isActive = true
        isPaused = false
        isCompleted = false
        showCompletionAlert = false
        
        startTimer()
        saveState()
        scheduleCompletionNotification(duration: duration)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.startTime,
                  let session = self.currentSession else { return }
            
            let currentElapsed = Date().timeIntervalSince(startTime) + self.elapsedTimeWhenPaused
            self.timeRemaining = max(0, session.plannedDuration - currentElapsed)
            
            if self.timeRemaining == 0 && !self.isCompleted {
                self.completeSession()
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func completeSession() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        isCompleted = true
        
        // Calculate actual time worked
        if var session = currentSession {
            let actualTimeWorked = session.plannedDuration - timeRemaining
            session.endTime = Date()
            session.isCompleted = actualTimeWorked >= session.plannedDuration
            session.duration = actualTimeWorked
            currentSession = session
        }
        
        timeRemaining = 0
        
        // Send immediate notification
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "Your work session has finished."
        content.sound = .defaultRingtone
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: "sessionComplete",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
        saveState()
        
        // Show alert after a slight delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            withAnimation {
                self.showCompletionAlert = true
            }
        }
    }
    
    func pauseSession() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = true
        if let startTime = startTime {
            elapsedTimeWhenPaused += Date().timeIntervalSince(startTime)
        }
        startTime = nil
        saveState()
        FeedbackManager.shared.playHaptic(style: .soft)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["sessionComplete"])
    }
    
    func resumeSession() {
        startTime = Date()
        isActive = true
        isPaused = false
        startTimer()
        saveState()
        FeedbackManager.shared.playHaptic(style: .soft)
        scheduleCompletionNotification(duration: timeRemaining)
    }
    
    func endSession() {
        completeSession()
        FeedbackManager.shared.playHaptic(style: .light)
    }
    
    func resetSession() {
        timer?.invalidate()
        timer = nil
        currentSession = nil
        timeRemaining = 0
        isActive = false
        isPaused = false
        isCompleted = false
        startTime = nil
        elapsedTimeWhenPaused = 0
        showCompletionAlert = false
        clearState()
    }
    
    private func saveState() {
        let state: [String: Any] = [
            "todoId": currentSession?.todoId.uuidString ?? "",
            "duration": currentSession?.duration ?? 0,
            "plannedDuration": currentSession?.plannedDuration ?? 0,
            "startTime": startTime ?? Date(),
            "elapsedTimeWhenPaused": elapsedTimeWhenPaused,
            "isActive": isActive,
            "isPaused": isPaused,
            "isCompleted": isCompleted,
            "timeRemaining": timeRemaining,
            "showCompletionAlert": showCompletionAlert,
            "hasSession": currentSession != nil
        ]
        
        userDefaults.set(state, forKey: "WorkSession")
        userDefaults.synchronize()
    }
    
    private func restoreState() {
        guard let state = userDefaults.dictionary(forKey: "WorkSession"),
              let todoIdString = state["todoId"] as? String,
              let todoId = UUID(uuidString: todoIdString),
              let duration = state["duration"] as? TimeInterval,
              let plannedDuration = state["plannedDuration"] as? TimeInterval,
              let startTime = state["startTime"] as? Date,
              let elapsedTimeWhenPaused = state["elapsedTimeWhenPaused"] as? TimeInterval,
              let timeRemaining = state["timeRemaining"] as? TimeInterval,
              let isActive = state["isActive"] as? Bool,
              let isPaused = state["isPaused"] as? Bool,
              let isCompleted = state["isCompleted"] as? Bool,
              let hasSession = state["hasSession"] as? Bool else {
            return
        }
        
        if hasSession {
            var session = WorkSession(todoId: todoId, duration: plannedDuration)
            session.duration = duration
            self.currentSession = session
            self.startTime = startTime
            self.elapsedTimeWhenPaused = elapsedTimeWhenPaused
            self.timeRemaining = timeRemaining
            self.isActive = isActive
            self.isPaused = isPaused
            self.isCompleted = isCompleted
            
            // If session was completed, show alert after a longer delay to ensure UI is ready
            if isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return }
                    withAnimation {
                        self.showCompletionAlert = true
                    }
                }
            } else if isActive && timeRemaining > 0 {
                startTimer()
            }
        }
    }
    
    private func clearState() {
        userDefaults.removeObject(forKey: "WorkSession")
        userDefaults.synchronize()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["sessionComplete"])
    }
    
    private func scheduleCompletionNotification(duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "Your work session has finished."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: "sessionComplete", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    @objc private func appDidEnterBackground() {
        if isActive || timeRemaining > 0 || isPaused || isCompleted {
            saveState()
        }
    }
    
    @objc private func appWillEnterForeground() {
        if let session = currentSession {
            if isCompleted && !showCompletionAlert {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return }
                    withAnimation {
                        self.showCompletionAlert = true
                    }
                }
            } else if isActive {
                // Recalculate elapsed time and update timer
                let now = Date()
                if let startTime = startTime {
                    let backgroundElapsed = now.timeIntervalSince(startTime)
                    elapsedTimeWhenPaused += backgroundElapsed
                }
                startTime = now
                startTimer()
            }
        }
    }
    
    @objc private func appWillTerminate() {
        saveState()
    }
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard let session = currentSession else { return 0 }
        return 1 - (timeRemaining / session.duration)
    }
} 
