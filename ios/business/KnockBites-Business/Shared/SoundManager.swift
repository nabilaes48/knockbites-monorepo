//
//  SoundManager.swift
//  KnockBites-Business
//
//  Created by Claude Code on 12/15/25.
//
//  Unique KnockBites order notification sound system
//

import AVFoundation
import UIKit

/// Manages sound notifications for the business app
/// Features a unique, recognizable KnockBites notification melody
@MainActor
class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    private var synthesizer: AVSpeechSynthesizer?
    private var audioEngine: AVAudioEngine?
    private var tonePlayer: AVAudioPlayerNode?

    // KnockBites signature melody frequencies (musical notes)
    // Pattern: "Knock-Bites!" - ascending cheerful melody
    private let knockBitesMelody: [(frequency: Double, duration: Double)] = [
        (659.25, 0.12),  // E5 - "Knock"
        (783.99, 0.12),  // G5 - "-"
        (880.00, 0.15),  // A5 - "Bites"
        (1046.50, 0.25), // C6 - "!" (high finish)
    ]

    // Urgent order melody - for priority/rush orders
    private let urgentMelody: [(frequency: Double, duration: Double)] = [
        (880.00, 0.08),  // A5 - Quick
        (1046.50, 0.08), // C6
        (880.00, 0.08),  // A5
        (1046.50, 0.08), // C6
        (1174.66, 0.20), // D6 - Attention!
    ]

    private init() {
        setupAudioSession()
        setupAudioEngine()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        tonePlayer = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = tonePlayer else { return }

        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    // MARK: - KnockBites Signature Sound

    /// Play the unique KnockBites notification melody for new orders
    /// This is a distinctive, recognizable sound that staff will instantly associate with new orders
    func playNewOrderSound() {
        // Play the KnockBites signature melody
        playKnockBitesMelody()

        // Also provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Vibrate device
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    /// Play urgent/priority order sound - faster, more attention-grabbing
    func playUrgentOrderSound() {
        playMelody(urgentMelody, volume: 0.8)

        // Strong haptic for urgent
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        // Double vibrate for urgency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func playKnockBitesMelody() {
        // Play melody twice for better recognition
        playMelody(knockBitesMelody, volume: 0.7)

        // Second play after short pause
        let totalDuration = knockBitesMelody.reduce(0) { $0 + $1.duration }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.15) { [weak self] in
            self?.playMelody(self?.knockBitesMelody ?? [], volume: 0.6)
        }
    }

    private func playMelody(_ melody: [(frequency: Double, duration: Double)], volume: Float) {
        guard !melody.isEmpty else { return }

        var delay: Double = 0

        for note in melody {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: note.frequency, duration: note.duration, volume: volume)
            }
            delay += note.duration
        }
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1007)
            return
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        let data = buffer.floatChannelData![0]

        // Generate sine wave with envelope for pleasant sound
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            let envelope = min(1.0, min(time * 20, (duration - time) * 20)) // Attack/Release envelope
            let sample = Float(sin(2.0 * .pi * frequency * time) * envelope * Double(volume))
            data[frame] = sample
        }

        // Ensure engine is running
        if audioEngine?.isRunning == false {
            try? audioEngine?.start()
        }

        tonePlayer?.scheduleBuffer(buffer, completionHandler: nil)
        tonePlayer?.play()
    }

    // MARK: - Fallback System Sounds

    /// Fallback to system sounds if audio engine fails
    private func playSystemSoundSequence() {
        let soundID: SystemSoundID = 1007 // Tink sound

        AudioServicesPlaySystemSound(soundID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1016) // Tweet
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AudioServicesPlaySystemSound(soundID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioServicesPlaySystemSound(1016)
        }

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // MARK: - Order Status Sounds

    /// Play sound when order is ready for pickup
    func playOrderReadySound() {
        // Pleasant completion chime
        let readyMelody: [(frequency: Double, duration: Double)] = [
            (523.25, 0.1),  // C5
            (659.25, 0.1),  // E5
            (783.99, 0.2),  // G5 (sustained)
        ]
        playMelody(readyMelody, volume: 0.5)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Play sound when order is completed
    func playOrderCompletedSound() {
        let completedMelody: [(frequency: Double, duration: Double)] = [
            (783.99, 0.15), // G5
            (1046.50, 0.25), // C6 - higher completion tone
        ]
        playMelody(completedMelody, volume: 0.4)
    }

    // MARK: - Speech Announcements

    /// Speak the order number aloud (accessibility feature)
    func announceNewOrder(orderNumber: String, customerName: String? = nil) {
        if synthesizer == nil {
            synthesizer = AVSpeechSynthesizer()
        }

        var announcement = "New order received: \(orderNumber)"
        if let name = customerName, !name.isEmpty {
            announcement += ", for \(name)"
        }

        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for clarity

        synthesizer?.speak(utterance)
    }

    /// Announce order ready for pickup
    func announceOrderReady(orderNumber: String, customerName: String? = nil) {
        if synthesizer == nil {
            synthesizer = AVSpeechSynthesizer()
        }

        var announcement = "Order \(orderNumber) is ready"
        if let name = customerName, !name.isEmpty {
            announcement += " for \(name)"
        }

        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0

        synthesizer?.speak(utterance)
    }

    // MARK: - Combined Notifications

    /// Combined notification: unique sound + optional speech announcement
    func notifyNewOrder(orderNumber: String, customerName: String? = nil, isUrgent: Bool = false, withSpeech: Bool = false) {
        if isUrgent {
            playUrgentOrderSound()
        } else {
            playNewOrderSound()
        }

        if withSpeech {
            // Delay speech so melody plays first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.announceNewOrder(orderNumber: orderNumber, customerName: customerName)
            }
        }
    }

    /// Notify order is ready with sound and optional speech
    func notifyOrderReady(orderNumber: String, customerName: String? = nil, withSpeech: Bool = false) {
        playOrderReadySound()

        if withSpeech {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.announceOrderReady(orderNumber: orderNumber, customerName: customerName)
            }
        }
    }

    // MARK: - Settings

    /// Test the notification sound (for settings preview)
    func testOrderSound() {
        playKnockBitesMelody()
    }

    /// Test urgent sound
    func testUrgentSound() {
        playUrgentOrderSound()
    }
}
