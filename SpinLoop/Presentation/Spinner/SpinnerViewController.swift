//
//  SpinnerViewController.swift
//  SpinLoop
//
//  Created by 김경호 on 2/21/26.
//

import UIKit

final class SpinnerViewController: UIViewController {
    private let contentView = SpinnerView()
    private let physics = SpinnerPhysicsConfiguration.default
    private lazy var feedbackController = SpinnerFeedbackController(maxOmega: physics.maxOmega)

    // Physics-ish state
    private var angle: CGFloat = 0
    private var omega: CGFloat = 0 {
        didSet {
            updateSpeedLabel()
        }
    }

    private let shakeRandomDirection = false

    // Gesture tracking
    private var isDragging = false
    private var lastTouchAngle: CGFloat = 0
    private var lastTime: CFTimeInterval = 0

    // Animation loop
    private var displayLink: CADisplayLink?

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        feedbackController.prepare()
        startDisplayLink()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        feedbackController.prepare()
    }

    deinit {
        displayLink?.invalidate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        omega = 0
        feedbackController.reset()
    }

    // MARK: - Motion (Shake)

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        guard motion == .motionShake else { return }
        applyShakeSpin()
    }

    private func applyShakeSpin() {
        let direction: CGFloat
        
        if shakeRandomDirection {
            direction = Bool.random() ? 1 : -1
        } else {
            direction = 1
        }

        omega += physics.shakeOmegaBoost * direction
        omega = clampedOmega(omega)
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        let now = CACurrentMediaTime()
        let point = gr.location(in: view)
        let center = contentView.spinnerCenter

        let dx = point.x - center.x
        let dy = point.y - center.y
        let r2 = dx * dx + dy * dy

        if r2 < physics.ignoresTouchesWithinRadiusSquared {
            return
        }

        let touchAngle = atan2(dy, dx)

        switch gr.state {
        case .began:
            isDragging = true
            lastTouchAngle = touchAngle
            lastTime = now

        case .changed:
            let dt = max(now - lastTime, 1.0 / 240.0)

            var dTheta = touchAngle - lastTouchAngle
            if dTheta > .pi { dTheta -= 2 * .pi }
            if dTheta < -.pi { dTheta += 2 * .pi }

            angle += dTheta
            applyRotation(angle)

            let measuredOmega = CGFloat(dTheta) / CGFloat(dt)
            omega = omega * (1 - physics.omegaSmoothing) + measuredOmega * physics.omegaSmoothing
            omega = clampedOmega(omega)
            feedbackController.consumeRotation(abs(dTheta), omega: omega, timestamp: now)

            lastTouchAngle = touchAngle
            lastTime = now

        case .ended, .cancelled, .failed:
            isDragging = false

        default:
            break
        }
    }

    // MARK: - DisplayLink loop

    private func startDisplayLink() {
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard !isDragging else { return }

        let dt = CGFloat(link.targetTimestamp - link.timestamp)
        if dt <= 0 { return }

        if abs(omega) < 0.02 {
            omega = 0
            return
        }

        omega *= exp(-physics.drag * dt)
        let deltaAngle = omega * dt
        angle += deltaAngle
        applyRotation(angle)
        feedbackController.consumeRotation(abs(deltaAngle), omega: omega, timestamp: link.targetTimestamp)
    }

    // MARK: - Helpers

    private func applyRotation(_ radians: CGFloat) {
        contentView.applyRotation(radians)
    }

    private func clamp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        min(max(x, a), b)
    }

    private func clampedOmega(_ value: CGFloat) -> CGFloat {
        clamp(value, -physics.maxOmega, physics.maxOmega)
    }
    
    private func updateSpeedLabel() {
        let rpm = Double(omega) * 60.0 / (2.0 * .pi)
        contentView.updateSpeed(rpm: rpm)
    }
}
