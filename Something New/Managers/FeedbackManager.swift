import SwiftUI
import AVFoundation
import SharedModels

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New")!
    private let soundManager = SoundManager.shared
    
    @AppStorage("hapticsEnabled") var isHapticsEnabled = true
    @AppStorage("soundEnabled") var isSoundEnabled = true
    @AppStorage("completionSound") private var completionSoundRawValue: String = SoundEffect.complete3.rawValue
    
    var completionSound: SoundEffect {
        get {
            SoundEffect(rawValue: completionSoundRawValue) ?? .complete3
        }
        set {
            completionSoundRawValue = newValue.rawValue
        }
    }
    
    private init() {
        if !userDefaults.contains(key: "hapticsEnabled") {
            self.isHapticsEnabled = true
            userDefaults.set(true, forKey: "hapticsEnabled")
        }
        if !userDefaults.contains(key: "soundEnabled") {
            self.isSoundEnabled = true
            userDefaults.set(true, forKey: "soundEnabled")
        }
    }
    
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
        
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        soundManager.playSound(effect)
    }
    
    func playDoneSound() {
        playSound(completionSound)
    }
    
    func previewCompletionSound(_ effect: SoundEffect) {
        playSound(effect)
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
} 
