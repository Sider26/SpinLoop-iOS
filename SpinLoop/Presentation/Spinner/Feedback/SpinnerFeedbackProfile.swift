//
//  SpinnerFeedbackProfile.swift
//  SpinLoop
//
//  Created by yungsix on 3/19/26.
//

import AudioToolbox
import Foundation

enum SpinnerFeedbackProfile {
    case idle
    case low
    case medium
    case high
    case maxed

    var angleStep: CGFloat {
        switch self {
        case .idle:
            return .greatestFiniteMagnitude
        case .low:
            return (.pi * 2) / 4
        case .medium:
            return (.pi * 2) / 6
        case .high:
            return (.pi * 2) / 9
        case .maxed:
            return (.pi * 2) / 12
        }
    }

    var minimumInterval: TimeInterval {
        switch self {
        case .idle:
            return 1
        case .low:
            return 0.11
        case .medium:
            return 0.075
        case .high:
            return 0.05
        case .maxed:
            return 0.035
        }
    }

    var soundID: SystemSoundID {
        switch self {
        case .idle, .low:
            return 1104
        case .medium:
            return 1105
        case .high, .maxed:
            return 1106
        }
    }
}
