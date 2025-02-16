import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    private let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    
    @Published var todayEvents: [EKEvent] = []
    @Published var tomorrowEvents: [EKEvent] = []
    @Published var hasCalendarAccess = false
    @Published var availableCalendars: [EKCalendar] = []
    
    private var selectedCalendarIDs: [String] {
        get {
            userDefaults.stringArray(forKey: "selectedCalendarIDs") ?? []
        }
        set {
            userDefaults.set(newValue, forKey: "selectedCalendarIDs")
            userDefaults.synchronize()
            objectWillChange.send()
        }
    }
    
    var selectedCalendarCount: Int {
        selectedCalendarIDs.count
    }
    
    private init() {
        checkCalendarAuthorization()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveCalendarSelections),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func saveCalendarSelections() {
        userDefaults.synchronize()
    }
    
    private func checkCalendarAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            hasCalendarAccess = true
            loadAvailableCalendars()
            fetchTodayEvents()
        case .notDetermined:
            requestAccess()
        default:
            hasCalendarAccess = false
        }
    }
    
    func requestAccess() {
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    DispatchQueue.main.async {
                        self.hasCalendarAccess = granted
                        if granted {
                            self.loadAvailableCalendars()
                            self.fetchTodayEvents()
                        }
                    }
                } catch {
                    print("Error requesting calendar access: \(error)")
                    DispatchQueue.main.async {
                        self.hasCalendarAccess = false
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.loadAvailableCalendars()
                        self?.fetchTodayEvents()
                    }
                }
            }
        }
    }
    
    func loadAvailableCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
            .sorted { $0.title < $1.title }
        
        if !userDefaults.contains(key: "selectedCalendarIDs") {
            selectedCalendarIDs = availableCalendars.map { $0.calendarIdentifier }
        }
        
        fetchTodayEvents()
        fetchTomorrowEvents()
    }
    
    func isCalendarSelected(_ calendar: EKCalendar) -> Bool {
        selectedCalendarIDs.contains(calendar.calendarIdentifier)
    }
    
    func toggleCalendarSelection(_ calendar: EKCalendar) {
        if let index = selectedCalendarIDs.firstIndex(of: calendar.calendarIdentifier) {
            selectedCalendarIDs.remove(at: index)
        } else {
            selectedCalendarIDs.append(calendar.calendarIdentifier)
        }
        fetchTodayEvents()
        fetchTomorrowEvents()
    }
    
    func fetchTodayEvents() {
        guard hasCalendarAccess, !selectedCalendarIDs.isEmpty else {
            todayEvents = []
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else { return }
        
        let selectedCalendars = availableCalendars.filter { isCalendarSelected($0) }
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )
        
        DispatchQueue.main.async {
            self.todayEvents = self.eventStore.events(matching: predicate)
        }
    }
    
    func fetchTomorrowEvents() {
        guard hasCalendarAccess, !selectedCalendarIDs.isEmpty else {
            tomorrowEvents = []
            return
        }
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startDate = calendar.startOfDay(for: tomorrow)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else { return }
        
        let selectedCalendars = availableCalendars.filter { isCalendarSelected($0) }
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )
        
        DispatchQueue.main.async {
            self.tomorrowEvents = self.eventStore.events(matching: predicate)
        }
    }
} 