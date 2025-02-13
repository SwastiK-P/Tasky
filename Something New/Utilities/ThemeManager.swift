import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") private var appTheme = "Default"
    @Published var currentColor: Color = .black
    
    init() {
        updateTheme()
    }
    
    func updateTheme() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        switch appTheme {
        case "Pink":
            currentColor = .pink
        case "Cyan":
            currentColor = .cyan
        default:
            currentColor = isDarkMode ? .white : .black
        }
    }
    
    func handleTraitCollectionChange() {
        updateTheme()
    }
}
