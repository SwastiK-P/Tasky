//
//  Category.swift
//  Something New
//
//  Created by Swastik Patil on 2/12/25.
//

import SwiftUI

enum Category: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    case college = "College"
    
    var color: Color {
        switch self {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .college: return "graduationcap.fill"
        }
    }
}
