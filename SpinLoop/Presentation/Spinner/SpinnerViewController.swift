//
//  SpinnerViewController.swift
//  SpinLoop
//
//  Created by 김경호 on 2/21/26.
//

import UIKit

final class SpinnerViewController: UIViewController {

    private let spinnerView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Spinner")) // Assets에 spinner 이미지 추가
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()

    // Physics-ish state
    private var angle: CGFloat = 0            // radians
    private var omega: CGFloat = 0            // rad/s

    // Tuning
    private let drag: CGFloat = 3.0           // 1/s (클수록 빨리 멈춤)
    private let maxOmega: CGFloat = 40.0      // rad/s (과속 방지)
    private let omegaSmoothing: CGFloat = 0.25 // 0~1 (측정치 반영 비율)

    // Gesture tracking
    private var isDragging = false
    private var lastTouchAngle: CGFloat = 0
    private var lastTime: CFTimeInterval = 0

    // Animation loop
    private var displayLink: CADisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(spinnerView)
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinnerView.widthAnchor.constraint(equalToConstant: 260),
            spinnerView.heightAnchor.constraint(equalTo: spinnerView.widthAnchor)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        spinnerView.addGestureRecognizer(pan)
        view.addGestureRecognizer(pan)

        startDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        let now = CACurrentMediaTime()
        let point = gr.location(in: view)
        let center = spinnerView.center

        // 중심과 너무 가까우면 계산이 튈 수 있으니 최소 거리 제한
        let dx = point.x - center.x
        let dy = point.y - center.y
        let r2 = dx*dx + dy*dy
        if r2 < 25 { return } // 반경 5px 이내 무시(원하면 조정)

        let touchAngle = atan2(dy, dx) // -π ~ π

        switch gr.state {
        case .began:
            isDragging = true
            lastTouchAngle = touchAngle
            lastTime = now
            // 드래그 시작 시 기존 관성은 유지할 수도, 리셋할 수도 있음
            // omega = 0

        case .changed:
            let dt = max(now - lastTime, 1.0 / 240.0)

            // 각도 변화량(unwrap 처리)
            var dTheta = touchAngle - lastTouchAngle
            if dTheta > .pi { dTheta -= 2 * .pi }
            if dTheta < -.pi { dTheta += 2 * .pi }

            // 즉시 회전 반영
            angle += dTheta
            applyRotation(angle)

            // 측정 각속도 -> 스무딩 적용
            let measuredOmega = CGFloat(dTheta) / CGFloat(dt)
            omega = omega * (1 - omegaSmoothing) + measuredOmega * omegaSmoothing

            // 과속 방지
            omega = clamp(omega, -maxOmega, maxOmega)

            lastTouchAngle = touchAngle
            lastTime = now

        case .ended, .cancelled, .failed:
            isDragging = false
            // 손 떼면 displayLink에서 omega를 감쇠시키며 계속 회전

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
        // 드래그 중이면 이미 handlePan에서 각도 업데이트하므로 여기선 "관성"만 처리
        guard !isDragging else { return }

        let dt = CGFloat(link.targetTimestamp - link.timestamp)
        if dt <= 0 { return }

        // 충분히 느리면 정지 처리
        if abs(omega) < 0.02 {
            omega = 0
            return
        }

        // 감쇠(지수 감쇠) + 각도 업데이트
        omega *= exp(-drag * dt)
        angle += omega * dt
        applyRotation(angle)
    }

    // MARK: - Helpers

    private func applyRotation(_ radians: CGFloat) {
        spinnerView.transform = CGAffineTransform(rotationAngle: radians)
    }

    private func clamp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        min(max(x, a), b)
    }
}
