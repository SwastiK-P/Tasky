import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    private let features: [(icon: String, title: String, description: String)] = [
        (
            icon: "checkmark.circle.fill",
            title: "Track Your Tasks",
            description: "Keep track of your daily tasks and monitor your progress"
        ),
        (
            icon: "timer",
            title: "Focus Timer",
            description: "Use built-in timer to stay focused and get things done"
        ),
        (
            icon: "slider.horizontal.3",
            title: "Smart Organization",
            description: "Filter and sort your tasks to find exactly what you need to work on"
        )
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            // App Icon and Title
            VStack(spacing: 24) {
                Image("AppIcon-Preview")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
                    .shadow(radius: 5)
                
                Text("Welcome to Tasky")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 60)
            
            // Features List
            VStack(alignment: .leading, spacing: 32) {
                ForEach(features, id: \.title) { feature in
                    HStack(spacing: 16) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(feature.description)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Get Started Button
            Button {
                withAnimation {
                    FeedbackManager.shared.playHaptic(style: .medium)
                    hasSeenOnboarding = true
                    dismiss()
                }
            } label: {
                Text("Get started")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView()
} 
