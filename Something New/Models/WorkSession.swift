import Foundation

struct WorkSession: Identifiable, Equatable, Codable {
    let id: UUID
    let todoId: UUID
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval  // This will store actual time worked
    let plannedDuration: TimeInterval  // This stores the originally planned duration
    var isCompleted: Bool
    
    init(todoId: UUID, duration: TimeInterval = 25 * 60) { // Default 25 minutes
        self.id = UUID()
        self.todoId = todoId
        self.startTime = Date()
        self.duration = duration  // Initially set to planned duration
        self.plannedDuration = duration  // Store the planned duration
        self.isCompleted = false
    }
} 