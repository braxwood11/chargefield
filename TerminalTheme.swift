//
//  TerminalTheme.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import UIKit

// MARK: - Terminal Theme Manager
// Centralizes all terminal-style UI theming to eliminate code duplication

class TerminalTheme {
    
    // MARK: - Colors
    struct Colors {
        static let primaryGreen = UIColor.green
        static let backgroundBlack = UIColor.black
        static let gridLineGreen = UIColor.green.withAlphaComponent(0.2)
        static let borderGreen = UIColor.green.withAlphaComponent(0.7)
        static let textWhite = UIColor.white
        static let dimmedWhite = UIColor.white.withAlphaComponent(0.7)
    }
    
    // MARK: - Fonts
    struct Fonts {
        static func monospaced(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        }
    }
    
    // MARK: - Grid Background
    static func createGridBackground(for bounds: CGRect) -> UIView {
        let backgroundView = UIView(frame: bounds)
        backgroundView.backgroundColor = .clear
        
        // Grid configuration
        let gridSize: CGFloat = 30
        let lineWidth: CGFloat = 0.5
        let lineColor = Colors.gridLineGreen
        
        // Horizontal lines
        for y in stride(from: 0, to: bounds.height, by: gridSize) {
            let lineView = UIView(frame: CGRect(x: 0, y: y, width: bounds.width, height: lineWidth))
            lineView.backgroundColor = lineColor
            backgroundView.addSubview(lineView)
        }
        
        // Vertical lines
        for x in stride(from: 0, to: bounds.width, by: gridSize) {
            let lineView = UIView(
                frame: CGRect(x: x,
                              y: 0,
                              width: lineWidth,
                              height: bounds.height)
            )
            lineView.backgroundColor = lineColor
            backgroundView.addSubview(lineView)
        }
        
        // Add glow dots at random intersections
        let intersections = min(15, Int((bounds.width / gridSize) * (bounds.height / gridSize) / 12))
        
        for _ in 0..<intersections {
            let randomX = Int.random(in: 1..<Int(bounds.width / gridSize)) * Int(gridSize)
            let randomY = Int.random(in: 1..<Int(bounds.height / gridSize)) * Int(gridSize)
            
            let dotView = createGlowDot(at: CGPoint(x: CGFloat(randomX), y: CGFloat(randomY)))
            backgroundView.addSubview(dotView)
        }
        
        return backgroundView
    }
    
    private static func createGlowDot(at position: CGPoint) -> UIView {
        let dotSize: CGFloat = 4
        let dotView = UIView(frame: CGRect(
            x: position.x - dotSize/2,
            y: position.y - dotSize/2,
            width: dotSize,
            height: dotSize
        ))
        dotView.backgroundColor = Colors.primaryGreen
        dotView.layer.cornerRadius = dotSize/2
        dotView.alpha = CGFloat.random(in: 0.2...0.6)
        
        // Add pulse animation to some dots
        if Bool.random() {
            animateDotPulse(dotView)
        }
        
        return dotView
    }
    
    private static func animateDotPulse(_ dotView: UIView) {
        UIView.animate(
            withDuration: Double.random(in: 1.5...3.0),
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                dotView.alpha = CGFloat.random(in: 0.1...0.3)
            }
        )
    }
    
    // MARK: - Button Styling
    static func styleButton(_ button: UIButton, style: ButtonStyle = .primary) {
        button.backgroundColor = Colors.backgroundBlack
        button.layer.cornerRadius = 8
        button.layer.borderWidth = style == .primary ? 2 : 1
        button.layer.borderColor = style.borderColor.cgColor
        button.setTitleColor(style.titleColor, for: .normal)
        button.titleLabel?.font = Fonts.monospaced(size: style.fontSize, weight: .bold)
    }
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        
        var borderColor: UIColor {
            switch self {
            case .primary: return Colors.borderGreen
            case .secondary: return Colors.borderGreen.withAlphaComponent(0.5)
            case .danger: return UIColor.red.withAlphaComponent(0.7)
            }
        }
        
        var titleColor: UIColor {
            switch self {
            case .primary: return Colors.primaryGreen
            case .secondary: return Colors.primaryGreen.withAlphaComponent(0.7)
            case .danger: return UIColor.red
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .primary: return 16
            case .secondary: return 14
            case .danger: return 14
            }
        }
    }
    
    // MARK: - Container Styling
    static func styleContainer(_ view: UIView, borderOpacity: CGFloat = 0.7) {
        view.backgroundColor = Colors.backgroundBlack.withAlphaComponent(0.6)
        view.layer.borderColor = Colors.primaryGreen.withAlphaComponent(borderOpacity).cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
    }
    
    // MARK: - Label Styling
    static func styleLabel(_ label: UILabel, style: LabelStyle = .body) {
        label.font = Fonts.monospaced(size: style.fontSize, weight: style.fontWeight)
        label.textColor = style.textColor
    }
    
    enum LabelStyle {
        case title
        case heading
        case body
        case caption
        case terminal
        
        var fontSize: CGFloat {
            switch self {
            case .title: return 20
            case .heading: return 18
            case .body: return 16
            case .caption: return 12
            case .terminal: return 14
            }
        }
        
        var fontWeight: UIFont.Weight {
            switch self {
            case .title: return .bold
            case .heading: return .bold
            case .body: return .regular
            case .caption: return .regular
            case .terminal: return .regular
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .title: return Colors.textWhite
            case .heading: return Colors.textWhite
            case .body: return Colors.textWhite
            case .caption: return Colors.dimmedWhite
            case .terminal: return Colors.primaryGreen
            }
        }
    }
    
    // MARK: - Navigation Bar Styling
    static func styleNavigationBar(_ navigationBar: UINavigationBar?) {
        navigationBar?.tintColor = Colors.primaryGreen
        navigationBar?.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Colors.textWhite,
            NSAttributedString.Key.font: Fonts.monospaced(size: 18, weight: .bold)
        ]
        navigationBar?.barTintColor = Colors.backgroundBlack
        navigationBar?.isTranslucent = false
    }
    
    // MARK: - Apply Background Helper
    static func applyBackground(to viewController: UIViewController) {
        viewController.view.backgroundColor = Colors.backgroundBlack
        
        let gridBackground = createGridBackground(for: viewController.view.bounds)
        gridBackground.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(gridBackground)
        viewController.view.sendSubviewToBack(gridBackground)
        
        NSLayoutConstraint.activate([
            gridBackground.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            gridBackground.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            gridBackground.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            gridBackground.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
    }
}

// MARK: - Terminal Background View
// A reusable view that automatically applies the terminal grid background

class TerminalBackgroundView: UIView {
    private var gridBackgroundView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBackground()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Recreate grid when bounds change
        gridBackgroundView?.removeFromSuperview()
        setupBackground()
    }
    
    private func setupBackground() {
        backgroundColor = TerminalTheme.Colors.backgroundBlack
        
        gridBackgroundView = TerminalTheme.createGridBackground(for: bounds)
        if let gridBackgroundView = gridBackgroundView {
            addSubview(gridBackgroundView)
            sendSubviewToBack(gridBackgroundView)
        }
    }
}

// MARK: - Terminal-Styled Components
// Pre-configured UI components with terminal styling

class TerminalButton: UIButton {
    var style: TerminalTheme.ButtonStyle = .primary {
        didSet { updateStyle() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateStyle()
    }
    
    private func updateStyle() {
        TerminalTheme.styleButton(self, style: style)
    }
}

class TerminalLabel: UILabel {
    var style: TerminalTheme.LabelStyle = .body {
        didSet { updateStyle() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateStyle()
    }
    
    private func updateStyle() {
        TerminalTheme.styleLabel(self, style: style)
    }
}

class TerminalContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        TerminalTheme.styleContainer(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        TerminalTheme.styleContainer(self)
    }
}
