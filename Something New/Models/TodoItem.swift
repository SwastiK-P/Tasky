//
//  TodoItem.swift
//  Something New
//
//  Created by Swastik Patil on 2/12/25.
//

import Foundation

struct TodoItem: Identifiable, Codable {
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
    
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high
    }
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, dueTime: Date? = nil, category: Category = .personal, notes: String? = nil, priority: Priority = .medium, images: [String]? = nil, notificationId: String? = nil) {
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
    }
}
