//
//  SpinnerFeedbackController.swift
//  SpinLoop
//
//  Created by yungsix on 3/19/26.
//

import AudioToolbox
import UIKit

final class SpinnerFeedbackController {

    private let softFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    private let maxOmega: CGFloat

    private var accumulatedAngle: CGFloat = 0
    private var lastFeedbackTime: CFTimeInterval = 0

    init(maxOmega: CGFloat) {
        self.maxOmega = maxOmega
    }

    func prepare() {
        softFeedbackGenerator.prepare()
        lightFeedbackGenerator.prepare()
        mediumFeedbackGenerator.prepare()
        rigidFeedbackGenerator.prepare()
    }

    func reset() {
        accumulatedAngle = 0
        lastFeedbackTime = 0
    }

    func consumeRotation(_ deltaAngle: CGFloat, omega: CGFloat, timestamp: CFTimeInterval) {
        guard deltaAngle > 0 else { return }

        let profile = feedbackProfile(for: abs(omega))
        guard profile != .idle else {
            accumulatedAngle = 0
            return
        }

        accumulatedAngle += deltaAngle

        while accumulatedAngle >= profile.angleStep {
            guard timestamp - lastFeedbackTime >= profile.minimumInterval else { return }

            accumulatedAngle -= profile.angleStep
            lastFeedbackTime = timestamp
            playPulse(for: profile, speed: abs(omega))
        }
    }

    private func playPulse(for profile: SpinnerFeedbackProfile, speed: CGFloat) {
        let normalizedSpeed = normalizedSpeed(for: speed)

        switch profile {
        case .idle:
            return
        case .low:
            softFeedbackGenerator.impactOccurred(intensity: 0.25 + normalizedSpeed * 0.15)
        case .medium:
            lightFeedbackGenerator.impactOccurred(intensity: 0.4 + normalizedSpeed * 0.2)
        case .high:
            mediumFeedbackGenerator.impactOccurred(intensity: 0.55 + normalizedSpeed * 0.25)
        case .maxed:
            rigidFeedbackGenerator.impactOccurred(intensity: 0.75 + normalizedSpeed * 0.25)
        }

        prepare()
        AudioServicesPlaySystemSound(profile.soundID)
    }

    private func feedbackProfile(for speed: CGFloat) -> SpinnerFeedbackProfile {
        switch normalizedSpeed(for: speed) {
        case ..<0.12:
            return .idle
        case ..<0.3:
            return .low
        case ..<0.55:
            return .medium
        case ..<0.82:
            return .high
        default:
            return .maxed
        }
    }

    private func normalizedSpeed(for speed: CGFloat) -> CGFloat {
        min(max(speed / maxOmega, 0), 1)
    }
}
