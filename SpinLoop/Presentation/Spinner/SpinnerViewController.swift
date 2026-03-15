//
//  SpinnerViewController.swift
//  SpinLoop
//
//  Created by 김경호 on 2/21/26.
//

import UIKit

final class SpinnerViewController: UIViewController {

    private let spinnerView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Spinner5"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let speedLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00 RPM"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    // Physics-ish state
    private var angle: CGFloat = 0
    // 회전 속도
    private var omega: CGFloat = 0 {
        didSet {
            updateSpeedLabel()
        }
    }

    // Tuning
    private let drag: CGFloat = 3.0
    private let maxOmega: CGFloat = 40.0
    private let omegaSmoothing: CGFloat = 0.25

    // Shake tuning
    private let shakeOmegaBoost: CGFloat = 18.0   // 흔들 때 추가 회전 속도
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(spinnerView)
        view.addSubview(speedLabel)

        // transform 회전 시 앵커 포인트가 뷰 정중앙에 고정되도록 명시합니다.
        spinnerView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            speedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            speedLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            speedLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            speedLabel.heightAnchor.constraint(equalToConstant: 100),
            
            spinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinnerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            spinnerView.heightAnchor.constraint(equalTo: spinnerView.widthAnchor)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        updateLabelFont()
        startDisplayLink()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLabelFont()
        fixAnchorPoint()
    }

    deinit {
        displayLink?.invalidate()
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

        omega += shakeOmegaBoost * direction
        omega = clamp(omega, -maxOmega, maxOmega)
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        let now = CACurrentMediaTime()
        let point = gr.location(in: view)
        let center = spinnerView.center

        let dx = point.x - center.x
        let dy = point.y - center.y
        let r2 = dx * dx + dy * dy

        // 중심 너무 가까우면 무시
        if r2 < 25 {
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
            omega = omega * (1 - omegaSmoothing) + measuredOmega * omegaSmoothing
            omega = clamp(omega, -maxOmega, maxOmega)

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

        omega *= exp(-drag * dt)
        angle += omega * dt
        applyRotation(angle)
    }

    // MARK: - Helpers

    private func applyRotation(_ radians: CGFloat) {
        spinnerView.transform = CGAffineTransform(rotationAngle: radians)
    }

    /// anchorPoint 가 CGAffineTransform 적용 후 밀리지 않도록 중앙(0.5, 0.5)으로 고정합니다.
    private func fixAnchorPoint() {
        let layer = spinnerView.layer
        guard layer.anchorPoint != CGPoint(x: 0.5, y: 0.5) else { return }
        let oldOrigin = layer.frame.origin
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.frame.origin = oldOrigin
    }

    private func clamp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        min(max(x, a), b)
    }
    
    private func updateSpeedLabel() {
        let rpm = Double(omega) * 60.0 / (2.0 * .pi)
        speedLabel.text = String(format: "%.2f RPM", abs(rpm))
    }

    private func updateLabelFont() {
        let fontSize = max(24, view.bounds.width * 0.1)
        speedLabel.font = .systemFont(ofSize: fontSize, weight: .bold)
    }
}
