//
//  SoundManager.swift
//  KnockBites-Business
//
//  Created by Claude Code on 12/15/25.
//

import AVFoundation
import UIKit

/// Manages sound notifications for the business app
@MainActor
class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    private var synthesizer: AVSpeechSynthesizer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    /// Play a recognizable "ding-ding-ding" notification sound for new orders
    func playNewOrderSound() {
        // Use system sound for reliable playback
        // 1007 = "Tink" - a pleasant notification sound
        // 1016 = "Tweet" - bird chirp
        // 1057 = "Sherwood Forest" - distinctive tri-tone
        // 1304 = Alert sound

        // Play a triple notification pattern for attention
        playSystemSoundSequence()
    }

    private func playSystemSoundSequence() {
        // Play 3 alert sounds in sequence for "ding-ding-ding" effect
        let soundID: SystemSoundID = 1007 // Tink sound

        // First ding
        AudioServicesPlaySystemSound(soundID)

        // Second ding after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(soundID)
        }

        // Third ding after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioServicesPlaySystemSound(soundID)
        }

        // Final higher tone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            AudioServicesPlaySystemSound(1016) // Tweet - higher pitch finish
        }

        // Also vibrate for haptic feedback
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    /// Play sound when order is ready
    func playOrderReadySound() {
        // Use a different sound for "ready" status
        let soundID: SystemSoundID = 1025 // "New Mail" sound
        AudioServicesPlaySystemSound(soundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    /// Speak the order number aloud (accessibility feature)
    func announceNewOrder(orderNumber: String) {
        if synthesizer == nil {
            synthesizer = AVSpeechSynthesizer()
        }

        let utterance = AVSpeechUtterance(string: "New order received: \(orderNumber)")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0

        synthesizer?.speak(utterance)
    }

    /// Combined notification: sound + optional speech
    func notifyNewOrder(orderNumber: String, withSpeech: Bool = false) {
        playNewOrderSound()

        if withSpeech {
            // Slight delay so sound plays first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.announceNewOrder(orderNumber: orderNumber)
            }
        }
    }
}
