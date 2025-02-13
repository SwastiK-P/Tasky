import Foundation
import SharedModels

struct TaskFilters {
    enum SortOrder: Equatable {
        case none
        case dueDate(ascending: Bool)
        case priority
        
        var text: String {
            switch self {
            case .none: return "Sort"
            case .dueDate(let ascending): return "Due Date \(ascending ? "↑" : "↓")"
            case .priority: return "Priority"
            }
        }
    }
    
    var selectedCategory: SharedModels.Category?
    var sortOrder: SortOrder = .none
} 
