//
//  SpinnerView.swift
//  SpinLoop
//
//  Created by yungsix on 3/19/26.
//

import UIKit

final class SpinnerView: UIView {

    private let spinnerImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Spinner5"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return imageView
    }()

    private let speedLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00 RPM"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupLayout()
        updateLabelFont(for: bounds.size)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLabelFont(for: bounds.size)
        fixSpinnerAnchorPoint()
    }

    var spinnerCenter: CGPoint {
        spinnerImageView.center
    }

    func applyRotation(_ radians: CGFloat) {
        spinnerImageView.transform = CGAffineTransform(rotationAngle: radians)
    }

    func updateSpeed(rpm: Double) {
        speedLabel.text = String(format: "%.2f RPM", abs(rpm))
    }

    private func setupLayout() {
        addSubview(spinnerImageView)
        addSubview(speedLabel)

        NSLayoutConstraint.activate([
            speedLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            speedLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            speedLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            speedLabel.heightAnchor.constraint(equalToConstant: 100),

            spinnerImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinnerImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            spinnerImageView.heightAnchor.constraint(equalTo: spinnerImageView.widthAnchor)
        ])
    }

    private func updateLabelFont(for size: CGSize) {
        let fontSize = max(24, size.width * 0.1)
        speedLabel.font = .systemFont(ofSize: fontSize, weight: .bold)
    }

    private func fixSpinnerAnchorPoint() {
        let layer = spinnerImageView.layer
        let expectedAnchorPoint = CGPoint(x: 0.5, y: 0.5)

        guard layer.anchorPoint != expectedAnchorPoint else { return }

        let oldOrigin = layer.frame.origin
        layer.anchorPoint = expectedAnchorPoint
        layer.frame.origin = oldOrigin
    }
}
