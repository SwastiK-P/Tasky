import SwiftUI
import SharedModels

enum AppIcon: String, CaseIterable {
    case primary = "AppIcon"
    case pink = "Pink"
    case cyan = "Cyan"
    
    var name: String {
        switch self {
        case .primary: return "Default"  // This is just the display name
        case .pink: return "Pink"
        case .cyan: return "Cyan"
        }
    }
    
    var preview: String {
        switch self {
        case .primary: return "AppIcon-Preview"
        case .pink: return "Pink-Preview"
        case .cyan: return "Cyan-Preview"
        }
    }
} 
