import Foundation

enum SoundEffect: String, CaseIterable {
    case add = "add"
    case delete = "delete"
    case complete1 = "complete1"
    case complete2 = "complete2"
    case complete3 = "complete3"
    case complete4 = "complete4"
    
    static var completionSounds: [SoundEffect] {
        [.complete1, .complete2, .complete3, .complete4]
    }
    
    var displayName: String {
        switch self {
        case .complete1: return "Sound 1"
        case .complete2: return "Sound 2"
        case .complete3: return "Sound 3"
        case .complete4: return "Sound 4"
        case .add: return "Add Sound"
        case .delete: return "Delete Sound"
        }
    }
    
    var soundFileName: String {
        switch self {
        case .add: return "Done Sound 1"
        case .delete: return "Done Sound 2"
        case .complete1: return "Done Sound 1"
        case .complete2: return "Done Sound 2"
        case .complete3: return "Done Sound 3"
        case .complete4: return "Done Sound 4"
        }
    }
} 