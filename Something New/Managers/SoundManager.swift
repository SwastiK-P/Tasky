import AVFoundation
import Foundation

class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    private let supportedExtensions = ["wav", "mp3"]
    
    private init() {
        preloadSounds()
        prepareAllPlayers()
    }
    
    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            loadSound(effect.soundFileName)
        }
        // Preload additional sounds
        loadSound("Open")
        print("Available sounds in bundle:", Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) ?? [])
    }
    
    private func prepareAllPlayers() {
        players.values.forEach { player in
            player.prepareToPlay()
        }
    }
    
    private func loadSound(_ name: String) {
        // Try each supported file extension
        for ext in supportedExtensions {
            if let path = Bundle.main.path(forResource: name, ofType: ext) {
                print("Found sound file at path:", path)
                do {
                    let url = URL(fileURLWithPath: path)
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[name] = player
                    print("Successfully loaded sound:", name)
                    return
                } catch {
                    print("Error loading sound \(name).\(ext):", error.localizedDescription)
                }
            }
        }
        print("Could not find sound file:", name, "in formats:", supportedExtensions)
    }
    
    static func playSound(_ name: String) {
        // Check if sound effects are enabled
        guard FeedbackManager.shared.isSoundEnabled else { return }
        shared.playSound(name)
    }
    
    func playSound(_ effect: SoundEffect) {
        // Check if sound effects are enabled
        guard FeedbackManager.shared.isSoundEnabled else { return }
        playSound(effect.soundFileName)
    }
    
    private func playSound(_ name: String) {
        if let player = players[name] {
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0
            player.play()
        } else {
            print("No player found for sound:", name)
            loadSound(name)
        }
    }
} 
