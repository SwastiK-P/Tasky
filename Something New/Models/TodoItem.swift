//
//  TodoItem.swift
//  Something New
//
//  Created by Swastik Patil on 2/12/25.
//

import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var dueTime: Date?
    var isCompleted: Bool
    var category: Category
    var priority: Priority
    var images: [String]?
    var notificationId: String?
    var completedDate: Date?
    var workSessions: [WorkSession]?
    var location: Location?
    
    struct Location: Codable, Equatable {
        var latitude: Double
        var longitude: Double
        var name: String
        var address: String
    }
    
    enum Priority: String, Codable, CaseIterable, Equatable {
        case low, medium, high
    }
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, dueTime: Date? = nil, category: Category = .personal, notes: String? = nil, priority: Priority = .medium, images: [String]? = nil, notificationId: String? = nil, completedDate: Date? = nil, workSessions: [WorkSession]? = nil, location: Location? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.category = category
        self.notes = notes
        self.priority = priority
        self.images = images
        self.notificationId = notificationId
        self.completedDate = completedDate
        self.workSessions = workSessions
        self.location = location
    }
}
