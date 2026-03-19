//
//  SpinnerPhysicsConfiguration.swift
//  SpinLoop
//
//  Created by yungsix on 3/19/26.
//

import CoreGraphics

struct SpinnerPhysicsConfiguration {
    let drag: CGFloat
    let maxOmega: CGFloat
    let omegaSmoothing: CGFloat
    let shakeOmegaBoost: CGFloat
    let ignoresTouchesWithinRadiusSquared: CGFloat

    static let `default` = SpinnerPhysicsConfiguration(
        drag: 3.0,
        maxOmega: 40.0,
        omegaSmoothing: 0.25,
        shakeOmegaBoost: 18.0,
        ignoresTouchesWithinRadiusSquared: 25
    )
}
