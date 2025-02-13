import SwiftUI

public enum Category: String, Codable, CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case college = "College"
    
    public init?(rawValue: String) {
        switch rawValue {
        case "Personal": self = .personal
        case "Work": self = .work
        case "College": self = .college
        default: return nil
        }
    }
    
    public var color: Color {
        switch self {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        }
    }
} 