import Foundation

@objc public class TodoItem: NSObject, ObservableObject, Codable, Identifiable {
    public let id: UUID
    @Published public var title: String
    @Published public var isCompleted: Bool
    @Published public var dueDate: Date?
    @Published public var dueTime: Date?
    @Published public var category: Category
    @Published public var notes: String?
    @Published public var priority: Priority
    @Published public var images: [String]
    @Published public var notificationId: String?
    
    public enum Priority: String, Codable, CaseIterable {
        case low, medium, high
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, dueDate, dueTime, category, notes, priority, images, notificationId
    }
    
    public init(id: UUID = UUID(),
                title: String,
                isCompleted: Bool = false,
                dueDate: Date? = nil,
                dueTime: Date? = nil,
                category: Category,
                notes: String? = nil,
                priority: Priority,
                images: [String] = [],
                notificationId: String? = nil) {
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
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        dueTime = try container.decodeIfPresent(Date.self, forKey: .dueTime)
        category = try container.decode(Category.self, forKey: .category)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        priority = try container.decode(Priority.self, forKey: .priority)
        images = try container.decode([String].self, forKey: .images)
        notificationId = try container.decodeIfPresent(String.self, forKey: .notificationId)
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(dueTime, forKey: .dueTime)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(priority, forKey: .priority)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(notificationId, forKey: .notificationId)
    }
} 