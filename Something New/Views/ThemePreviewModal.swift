import SwiftUI

struct ThemePreviewModal: View {
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var feedbackManager = FeedbackManager.shared
    let applyTheme: () -> Void
    
    @State private var isIconPressed = false
    @State private var isToolbarPressed = false
    @State private var isTabbarPressed = false
    
    var themeColor: Color {
        if theme.name == "Default" && colorScheme == .dark {
            return theme.darkModeColor
        }
        return theme.color
    }
    
    private var toolbarImageName: String {
        "\(theme.name)-Toolbar"
    }
    
    private var tabbarImageName: String {
        "\(theme.name)-Tabbar"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.color
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.05), radius: 2)
                                
                                Image(theme.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(20)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(lineWidth: 2)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                            }
                            .scaleEffect(isIconPressed ? 0.95 : 1.0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isIconPressed = true
                                }
                                feedbackManager.playHaptic(style: .soft)
                                SoundManager.playSound("Click")

                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.spring(response: 0.3)) {
                                        isIconPressed = false
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.05), radius: 2)
                                
                                Image(toolbarImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.top, 5)
                            }
                            .scaleEffect(isToolbarPressed ? 0.95 : 1.0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isToolbarPressed = true
                                }
                                feedbackManager.playHaptic(style: .soft)
                                SoundManager.playSound("Click")
                                
                                // Reset animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.spring(response: 0.3)) {
                                        isToolbarPressed = false
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                        }
                        
                        // Tabbar Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.05), radius: 2)
                            
                            Image(tabbarImageName)
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, 16)
                        }
                        .scaleEffect(isTabbarPressed ? 0.95 : 1.0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isTabbarPressed = true
                            }
                            feedbackManager.playHaptic(style: .soft)
                            SoundManager.playSound("Click")
                            
                            // Reset animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3)) {
                                    isTabbarPressed = false
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer()
                }
            }
            .navigationTitle("Theme Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyTheme()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            SoundManager.playSound("Open")
        }
    }
}

#Preview {
    ThemePreviewModal(theme: AppTheme(name: "Custom", color: .blue, iconName: "AppIcon")) {
    }
}
