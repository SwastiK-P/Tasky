import Foundation
import SwiftUI

struct Tag: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var color: TagColor
    
    init(id: UUID = UUID(), name: String, color: TagColor = .blue) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    enum TagColor: String, Codable, CaseIterable {
        case blue, red, green, yellow, purple, orange
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .red: return .red
            case .green: return .green
            case .yellow: return .yellow
            case .purple: return .purple
            case .orange: return .orange
            }
        }
    }
} 