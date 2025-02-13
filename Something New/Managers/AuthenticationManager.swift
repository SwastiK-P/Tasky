import LocalAuthentication
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @AppStorage("isAppLocked") private(set) var isAppLocked = false
    @AppStorage("lockImmediately") private(set) var lockImmediately = true
    @Published var isAuthenticated = false
    
    private let context = LAContext()
    private var error: NSError?
    
    private init() {
        isAuthenticated = !isAppLocked
    }
    
    var biometricType: String {
        context.biometricType == .faceID ? "Face ID" : "Touch ID"
    }
    
    var canUseBiometrics: Bool {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func toggleAppLock() {
        isAppLocked.toggle()
        isAuthenticated = !isAppLocked
    }
    
    func toggleLockTiming() {
        lockImmediately.toggle()
    }
    
    func handleScenePhase(_ phase: ScenePhase) {
        guard isAppLocked else { return }
        
        switch phase {
        case .background, .inactive:
            if lockImmediately {
                isAuthenticated = false
            }
        case .active:
            if !isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.authenticate()
                }
            }
        @unknown default:
            break
        }
    }
    
    func authenticate() {
        guard isAppLocked else {
            isAuthenticated = true
            return
        }
        
        let reason = getBiometricAuthReason()
        
        let context = LAContext()
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                } else {
                    self.isAuthenticated = false
                    if let error {
                        print("Authentication error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func lock() {
        guard isAppLocked else { return }
        if lockImmediately {
            isAuthenticated = false
        }
    }
    
    private func getBiometricAuthReason() -> String {
        switch context.biometricType {
        case .faceID:
            return "Unlock app using Face ID"
        case .touchID:
            return "Unlock app using Touch ID"
        default:
            return "Unlock app using biometric authentication"
        }
    }
    
    private func getBiometricButtonText() -> String {
        switch context.biometricType {
        case .faceID:
            return "Use Face ID"
        case .touchID:
            return "Use Touch ID"
        default:
            return "Use Biometrics"
        }
    }
}

extension LAContext {
    var biometricType: LABiometryType {
        var error: NSError?
        guard canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return biometryType
    }
} 