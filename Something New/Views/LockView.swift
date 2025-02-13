import SwiftUI

struct LockView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("App Locked")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button {
                authManager.authenticate()
            } label: {
                Label("Unlock with \(authManager.biometricType)", systemImage: "faceid")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                authManager.lock()
            }
        }
    }
} 