//
//  GameViewController+Extensions.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import UIKit

// MARK: - GameViewController Builder Extensions
extension GameViewController {
    
    // MARK: - View Builders
    struct ViewBuilder {
        
        static func buildStatusContainer() -> UIView {
            let containerView = TerminalContainerView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            // Terminal prompt
            let promptLabel = TerminalLabel()
            promptLabel.style = .terminal
            promptLabel.text = "chamber> anomaly_stabilization_active"
            promptLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(promptLabel)
            
            // Status message
            let statusLabel = TerminalLabel()
            statusLabel.style = .body
            statusLabel.text = "Neutralize all field anomalies"
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(statusLabel)
            
            // Set constraints
            NSLayoutConstraint.activate([
                promptLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
                promptLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
                promptLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
                
                statusLabel.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 8),
                statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
                statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
                statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
            ])
            
            // Height constraint
            let heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 70)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            
            return containerView
        }
        
        static func buildProgressBar() -> UIProgressView {
            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
            progressBar.progressTintColor = TerminalTheme.Colors.primaryGreen
            progressBar.layer.cornerRadius = 5
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false
            return progressBar
        }
        
        static func buildProgressLabel() -> UILabel {
            let label = TerminalLabel()
            label.style = .terminal
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }
        
        static func buildGridView(size: CGFloat = 300) -> UIView {
            let gridView = UIView()
            gridView.backgroundColor = UIColor.white
            gridView.layer.cornerRadius = 8
            gridView.layer.borderWidth = 2
            gridView.layer.borderColor = TerminalTheme.Colors.borderGreen.cgColor
            gridView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add glow effect
            gridView.layer.shadowColor = TerminalTheme.Colors.primaryGreen.cgColor
            gridView.layer.shadowOffset = CGSize.zero
            gridView.layer.shadowRadius = 10
            gridView.layer.shadowOpacity = 0.3
            
            return gridView
        }
        
        static func buildControlButton(icon: String, action: Selector, target: Any?) -> UIButton {
            let button = UIButton(type: .system)
            button.backgroundColor = TerminalTheme.Colors.backgroundBlack
            button.layer.borderWidth = 2
            button.layer.borderColor = TerminalTheme.Colors.borderGreen.cgColor
            button.setTitleColor(TerminalTheme.Colors.primaryGreen, for: .normal)
            button.layer.cornerRadius = 30
            
            let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            let image = UIImage(systemName: icon, withConfiguration: configuration)
            button.setImage(image, for: .normal)
            button.tintColor = TerminalTheme.Colors.primaryGreen
            
            if let target = target {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Add button press effects
            addButtonPressEffects(to: button, target: target)
            
            return button
        }
        
        private static func addButtonPressEffects(to button: UIButton, target: Any?) {
            if let target = target as? GameViewController {
                button.addTarget(target, action: #selector(target.buttonTouchDown(_:)), for: .touchDown)
                button.addTarget(target, action: #selector(target.buttonTouchUpOutside(_:)), for: [.touchUpOutside, .touchCancel])
            }
        }
    }
}

// MARK: - Tutorial Accessible Protocol
protocol TutorialAccessible: AnyObject {
    func getStabilizerButton() -> UIView?
    func getSuppressorButton() -> UIView?
    func getGridView() -> UIView?
    func getCellView(at row: Int, col: Int) -> UIView?
}

// MARK: - Grid Position Helper (already defined in FieldCalculator.swift)

// MARK: - Enhanced Game Animation Controller
class GameAnimationController {
    weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    // MARK: - Magnet Placement Animation
    func animateMagnetPlacement(at position: GridPosition, cellView: CellView, magnetType: Int, sourceButton: UIButton?, completion: (() -> Void)? = nil) {
        
        // Create a flying magnet effect from button to cell (if source button is available)
        if let sourceButton = sourceButton, let gameView = viewController?.view {
            createFlyingMagnetEffect(from: sourceButton, to: cellView, magnetType: magnetType, in: gameView)
        }
        
        // Animate the cell's magnet placement
        cellView.animateMagnetPlacement(magnetType: magnetType) {
            completion?()
        }
        
        // Add subtle screen shake for impact
        addSubtleScreenShake()
        
        // Create ripple effect emanating from the cell
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.createRippleEffect(at: cellView)
        }
    }
    
    // MARK: - Magnet Removal Animation
    func animateMagnetRemoval(at position: GridPosition, cellView: CellView, removedType: Int, completion: (() -> Void)? = nil) {
        
        // Animate the cell's magnet removal
        cellView.animateMagnetRemoval {
            completion?()
        }
        
        // Create energy dissipation effect
        createEnergyDissipationEffect(at: cellView, magnetType: removedType)
    }
    
    // MARK: - Flying Magnet Effect
    private func createFlyingMagnetEffect(from sourceButton: UIButton, to targetCell: CellView, magnetType: Int, in containerView: UIView) {
        
        // Create temporary magnet view
        let flyingMagnet = UIView()
        flyingMagnet.backgroundColor = magnetType == 1 ?
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0) :
            UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
        flyingMagnet.layer.cornerRadius = 12
        flyingMagnet.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        
        // Add symbol
        let symbolLabel = UILabel()
        symbolLabel.text = magnetType == 1 ? "+" : "-"
        symbolLabel.textColor = .white
        symbolLabel.font = UIFont.boldSystemFont(ofSize: 16)
        symbolLabel.textAlignment = .center
        symbolLabel.frame = flyingMagnet.bounds
        flyingMagnet.addSubview(symbolLabel)
        
        // Position at source button center
        let sourceCenter = containerView.convert(sourceButton.center, from: sourceButton.superview)
        flyingMagnet.center = sourceCenter
        
        containerView.addSubview(flyingMagnet)
        
        // Calculate target position
        let targetCenter = containerView.convert(targetCell.center, from: targetCell.superview)
        
        // Animate flight path with slight arc
        let controlPoint = CGPoint(
            x: (sourceCenter.x + targetCenter.x) / 2,
            y: min(sourceCenter.y, targetCenter.y) - 30
        )
        
        // Create bezier path for curved flight
        let path = UIBezierPath()
        path.move(to: sourceCenter)
        path.addQuadCurve(to: targetCenter, controlPoint: controlPoint)
        
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.path = path.cgPath
        pathAnimation.duration = 0.4
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Scale animation (grows then shrinks)
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.3, 0.8]
        scaleAnimation.keyTimes = [0.0, 0.5, 1.0]
        scaleAnimation.duration = 0.4
        
        // Combine animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [pathAnimation, scaleAnimation]
        animationGroup.duration = 0.4
        animationGroup.delegate = AnimationDelegate { [weak flyingMagnet] in
            flyingMagnet?.removeFromSuperview()
        }
        
        flyingMagnet.layer.add(animationGroup, forKey: "flyingMagnet")
    }
    
    // MARK: - Visual Effects
    private func createRippleEffect(at cellView: CellView) {
        guard let containerView = cellView.superview else { return }
        
        // Create ripple view
        let rippleView = UIView()
        rippleView.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        rippleView.layer.borderWidth = 2
        rippleView.backgroundColor = UIColor.clear
        rippleView.layer.cornerRadius = cellView.bounds.width / 2
        rippleView.frame = cellView.frame
        rippleView.alpha = 0.8
        
        containerView.addSubview(rippleView)
        
        // Animate ripple expansion
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
            rippleView.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
            rippleView.alpha = 0
        } completion: { _ in
            rippleView.removeFromSuperview()
        }
    }
    
    private func createEnergyDissipationEffect(at cellView: CellView, magnetType: Int) {
        let baseColor = magnetType == 1 ? UIColor.red : UIColor.blue
        let particleCount = 8
        
        guard let containerView = cellView.superview else { return }
        
        for i in 0..<particleCount {
            let particle = UIView()
            particle.backgroundColor = baseColor.withAlphaComponent(0.7)
            particle.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
            particle.layer.cornerRadius = 2
            particle.center = cellView.center
            
            containerView.addSubview(particle)
            
            // Calculate random direction
            let angle = Double(i) * (2 * Double.pi / Double(particleCount)) + Double.random(in: -0.3...0.3)
            let distance = CGFloat.random(in: 30...50)
            let endPoint = CGPoint(
                x: cellView.center.x + CGFloat(cos(angle)) * distance,
                y: cellView.center.y + CGFloat(sin(angle)) * distance
            )
            
            // Animate particle dissipation
            UIView.animate(withDuration: 0.8, delay: Double.random(in: 0...0.2), options: .curveEaseOut) {
                particle.center = endPoint
                particle.alpha = 0
                particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            } completion: { _ in
                particle.removeFromSuperview()
            }
        }
    }
    
    private func addSubtleScreenShake() {
        guard let view = viewController?.view else { return }
        
        let shakeAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        shakeAnimation.fromValue = -2
        shakeAnimation.toValue = 2
        shakeAnimation.duration = 0.1
        shakeAnimation.autoreverses = true
        shakeAnimation.repeatCount = 2
        
        view.layer.add(shakeAnimation, forKey: "subtleShake")
    }
    
    // MARK: - Puzzle Completion Animation (Enhanced)
    func animatePuzzleCompletion() {
        guard let gameVC = viewController as? GameViewController,
              let view = gameVC.view,
              let gridView = gameVC.gridView else { return }
        
        // Start the completion sequence
        performCompletionSequence(gameView: view, gridView: gridView, gameVC: gameVC)
    }
    
    private func performCompletionSequence(gameView: UIView, gridView: UIView, gameVC: GameViewController) {
        // Stage 1: Grid scan effect
        performGridScan(gridView: gridView) { [weak self] in
            // Stage 2: Energy discharge wave
            self?.performEnergyWave(gameView: gameView, gridView: gridView) { [weak self] in
                // Stage 3: Celebration burst
                self?.performCelebrationBurst(gameView: gameView, gridView: gridView) { [weak self] in
                    // Stage 4: Final success display
                    self?.performFinalSuccess(gameView: gameView, gameVC: gameVC)
                }
            }
        }
    }
    
    // MARK: - Stage 1: Grid Scan Effect
    private func performGridScan(gridView: UIView, completion: @escaping () -> Void) {
        // Create scanning line effect
        let scanLine = UIView()
        scanLine.backgroundColor = TerminalTheme.Colors.primaryGreen
        scanLine.frame = CGRect(x: 0, y: 0, width: gridView.bounds.width, height: 2)
        scanLine.alpha = 0.8
        gridView.addSubview(scanLine)
        
        // Add glow effect
        scanLine.layer.shadowColor = TerminalTheme.Colors.primaryGreen.cgColor
        scanLine.layer.shadowOffset = CGSize.zero
        scanLine.layer.shadowRadius = 8
        scanLine.layer.shadowOpacity = 1.0
        
        // Animate scan line moving down
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations: {
            scanLine.frame.origin.y = gridView.bounds.height
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                scanLine.alpha = 0
            }) { _ in
                scanLine.removeFromSuperview()
                completion()
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Stage 2: Energy Wave Effect
    private func performEnergyWave(gameView: UIView, gridView: UIView, completion: @escaping () -> Void) {
        let centerPoint = CGPoint(x: gridView.bounds.width / 2, y: gridView.bounds.height / 2)
        let maxRadius = max(gridView.bounds.width, gridView.bounds.height)
        
        // Create multiple wave rings
        for i in 0..<3 {
            let delay = Double(i) * 0.1
            createWaveRing(in: gridView, center: centerPoint, maxRadius: maxRadius, delay: delay)
        }
        
        // Medium haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        // Complete after all waves
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }
    
    private func createWaveRing(in containerView: UIView, center: CGPoint, maxRadius: CGFloat, delay: TimeInterval) {
        let waveRing = UIView()
        waveRing.frame = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
        waveRing.layer.cornerRadius = 5
        waveRing.layer.borderWidth = 2
        waveRing.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        waveRing.backgroundColor = UIColor.clear
        waveRing.alpha = 0.8
        containerView.addSubview(waveRing)
        
        // Add glow
        waveRing.layer.shadowColor = TerminalTheme.Colors.primaryGreen.cgColor
        waveRing.layer.shadowOffset = CGSize.zero
        waveRing.layer.shadowRadius = 4
        waveRing.layer.shadowOpacity = 0.8
        
        UIView.animate(withDuration: 0.8, delay: delay, options: .curveEaseOut, animations: {
            let finalSize = maxRadius * 2
            waveRing.frame = CGRect(
                x: center.x - finalSize / 2,
                y: center.y - finalSize / 2,
                width: finalSize,
                height: finalSize
            )
            waveRing.layer.cornerRadius = finalSize / 2
            waveRing.alpha = 0
        }) { _ in
            waveRing.removeFromSuperview()
        }
    }
    
    // MARK: - Stage 3: Celebration Burst
    private func performCelebrationBurst(gameView: UIView, gridView: UIView, completion: @escaping () -> Void) {
        let centerPoint = gameView.convert(CGPoint(x: gridView.bounds.midX, y: gridView.bounds.midY), from: gridView)
        
        // Create particle burst effect
        for _ in 0..<15 {
            let particle = createCelebrationParticle()
            particle.center = centerPoint
            gameView.addSubview(particle)
            
            animateCelebrationParticle(particle, from: centerPoint)
        }
        
        // Strong haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Complete after particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion()
        }
    }
    
    private func createCelebrationParticle() -> UIView {
        let particle = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        particle.backgroundColor = [UIColor.green, UIColor.yellow, TerminalTheme.Colors.primaryGreen].randomElement()
        particle.layer.cornerRadius = 3
        particle.alpha = 0.9
        
        // Add glow
        particle.layer.shadowColor = particle.backgroundColor?.cgColor
        particle.layer.shadowOffset = CGSize.zero
        particle.layer.shadowRadius = 4
        particle.layer.shadowOpacity = 1.0
        
        return particle
    }
    
    private func animateCelebrationParticle(_ particle: UIView, from startPoint: CGPoint) {
        let angle = Double.random(in: 0...(2 * Double.pi))
        let distance = CGFloat.random(in: 80...150)
        
        let endX = startPoint.x + CGFloat(cos(angle)) * distance
        let endY = startPoint.y + CGFloat(sin(angle)) * distance
        
        UIView.animate(withDuration: 1.5, delay: Double.random(in: 0...0.3), options: .curveEaseOut, animations: {
            particle.center = CGPoint(x: endX, y: endY)
            particle.alpha = 0
            particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { _ in
            particle.removeFromSuperview()
        }
    }
    
    // MARK: - Stage 4: Final Success
    private func performFinalSuccess(gameView: UIView, gameVC: GameViewController) {
        // Show success message with enhanced styling
        gameVC.showCompletionMessage()
        
        // Final haptic sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    func animateSelection(for view: UIView) {
        UIView.animate(withDuration: 0.1) {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        }
    }
}

// MARK: - Animation Delegate Helper
private class AnimationDelegate: NSObject, CAAnimationDelegate {
    private let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion()
    }
}

// MARK: - Enhanced Message View
extension GameViewController {
    
     func showCompletionMessage() {
        guard let messageView = messageView else { return }
        
        // Update the message
        messageView.setMessage("⚡ MISSION ACCOMPLISHED ⚡")
        messageView.isHidden = false
        
        // Enhanced appearance animation
        messageView.alpha = 0
        messageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Add border glow effect
        messageView.layer.shadowColor = TerminalTheme.Colors.primaryGreen.cgColor
        messageView.layer.shadowOffset = CGSize.zero
        messageView.layer.shadowRadius = 15
        messageView.layer.shadowOpacity = 0.8
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
            messageView.alpha = 1
            messageView.transform = .identity
        }) { _ in
            // Add pulsing glow
            self.addPulsingGlow(to: messageView)
        }
    }
    
    private func addPulsingGlow(to view: UIView) {
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            view.layer.shadowOpacity = 0.4
        })
    }
    
     func hideCompletionMessage() {
        UIView.animate(withDuration: 0.5, animations: {
            self.messageView?.alpha = 0
            self.messageView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.messageView?.isHidden = true
            self.messageView?.layer.removeAllAnimations()
            self.messageView?.layer.shadowOpacity = 0
        }
    }
}


// MARK: - Game State Tracking
extension GameViewController {
    struct GameSession {
        let startTime: Date
        var moveCount: Int = 0
        var undoCount: Int = 0
        let puzzleId: String
        let puzzleType: GameProgressManager.PuzzleSaveState.PuzzleType
        let difficulty: String?
        
        var elapsedTime: TimeInterval {
            return Date().timeIntervalSince(startTime)
        }
    }
}

// MARK: - UI Update Helpers
extension GameViewController {
    
    func updateProgressDisplay() {
        guard let viewModel = viewModel else { return }
        
        // Get puzzle info which includes all the counts we need
        let puzzleInfo = viewModel.getPuzzleInfo()
        
        // Calculate progress
        let progress = puzzleInfo.progress
        
        // Update progress bar
        UIView.animate(withDuration: 0.3) {
            self.progressBar?.setProgress(progress, animated: true)
        }
        
        // Update progress label
        progressLabel?.text = "\(puzzleInfo.neutralizedCells)/\(puzzleInfo.targetCells) FIELDS NEUTRALIZED"
    }
}

// MARK: - Cell View Management
extension GameViewController {
    
    func createCellViews(for gridSize: Int) -> [[CellView]] {
        var cellViews: [[CellView]] = []
        let cellSize = 300 / CGFloat(gridSize) - 4
        
        for row in 0..<gridSize {
            var rowViews: [CellView] = []
            
            for col in 0..<gridSize {
                let cellView = CellView(frame: .zero)
                
                // Configure cell
                cellView.backgroundColor = .white
                cellView.tag = row * 100 + col
                
                // Position the cell
                let x = CGFloat(col) * (cellSize + 4) + 2
                let y = CGFloat(row) * (cellSize + 4) + 2
                cellView.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                
                // Add tap gesture
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
                cellView.addGestureRecognizer(tapGesture)
                cellView.isUserInteractionEnabled = true
                
                gridView?.addSubview(cellView)
                rowViews.append(cellView)
            }
            
            cellViews.append(rowViews)
        }
        
        return cellViews
    }
    
    func updateCellView(_ cellView: CellView, with cell: MagnetCell) {
        cellView.cell = cell
        cellView.showHints = viewModel?.areHintsEnabled() ?? false
        cellView.selectedMagnetType = viewModel?.getSelectedMagnetType() ?? 1
    }
}
