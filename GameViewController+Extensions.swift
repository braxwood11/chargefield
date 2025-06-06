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

// MARK: - Enhanced Game Animation Controller
class GameAnimationController {
    weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func animateMagnetPlacement(at position: GridPosition, completion: (() -> Void)? = nil) {
        guard let view = viewController?.view else { return }
        
        // Create a pulse effect at the position
        let pulseView = UIView()
        pulseView.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.3)
        pulseView.layer.cornerRadius = 20
        pulseView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        pulseView.center = view.center // This should be calculated based on grid position
        view.addSubview(pulseView)
        
        UIView.animate(withDuration: 0.3, animations: {
            pulseView.transform = CGAffineTransform(scaleX: 2, y: 2)
            pulseView.alpha = 0
        }) { _ in
            pulseView.removeFromSuperview()
            completion?()
        }
    }
    
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
                // Stage 3: Terminal success sequence
                self?.performTerminalSuccess(gameView: gameView, gameVC: gameVC) { [weak self] in
                    // Stage 4: Final celebration
                    self?.performFinalCelebration(gameView: gameView, gameVC: gameVC)
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
    
    // MARK: - Stage 3: Terminal Success Sequence
    private func performTerminalSuccess(gameView: UIView, gameVC: GameViewController, completion: @escaping () -> Void) {
        // Create terminal overlay
        let terminalOverlay = createTerminalOverlay(frame: gameView.bounds)
        gameView.addSubview(terminalOverlay)
        
        // Animate terminal text
        animateTerminalText(in: terminalOverlay) {
            // Remove overlay after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.5, animations: {
                    terminalOverlay.alpha = 0
                }) { _ in
                    terminalOverlay.removeFromSuperview()
                    completion()
                }
            }
        }
        
        // Strong haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func createTerminalOverlay(frame: CGRect) -> UIView {
        let overlay = UIView(frame: frame)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        overlay.alpha = 0
        
        // Add scan lines effect
        addScanLinesEffect(to: overlay)
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }
        
        return overlay
    }
    
    private func addScanLinesEffect(to view: UIView) {
        let scanLinesView = UIView(frame: view.bounds)
        view.addSubview(scanLinesView)
        
        for i in stride(from: 0, to: Int(view.bounds.height), by: 4) {
            let line = UIView(frame: CGRect(x: 0, y: CGFloat(i), width: view.bounds.width, height: 1))
            line.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.1)
            scanLinesView.addSubview(line)
        }
        
        // Animate scan lines
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            scanLinesView.alpha = 0.7
        })
    }
    
    private func animateTerminalText(in container: UIView, completion: @escaping () -> Void) {
        let messages = [
            "FIELD HARMONIZATION COMPLETE",
            "ALL ENERGY ANOMALIES NEUTRALIZED",
            "CONTAINMENT SUCCESSFUL",
            "EXCELLENT WORK, SPECIALIST"
        ]
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
            containerView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        var currentMessageIndex = 0
        
        func showNextMessage() {
            guard currentMessageIndex < messages.count else {
                completion()
                return
            }
            
            let messageLabel = TerminalLabel()
            messageLabel.style = .terminal
            messageLabel.text = messages[currentMessageIndex]
            messageLabel.textAlignment = .center
            messageLabel.font = TerminalTheme.Fonts.monospaced(size: 18, weight: .bold)
            messageLabel.alpha = 0
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(messageLabel)
            
            NSLayoutConstraint.activate([
                messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: CGFloat(currentMessageIndex * 40)),
                messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            
            // Type-writer effect
            typeWriterEffect(for: messageLabel, text: messages[currentMessageIndex]) {
                currentMessageIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showNextMessage()
                }
            }
        }
        
        showNextMessage()
    }
    
    private func typeWriterEffect(for label: UILabel, text: String, completion: @escaping () -> Void) {
        label.text = ""
        label.alpha = 1
        
        var characterIndex = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if characterIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: characterIndex)
                label.text = String(text[..<index])
                characterIndex += 1
                
                // Add cursor blink effect
                if characterIndex % 2 == 0 {
                    label.text! += "_"
                }
            } else {
                timer.invalidate()
                label.text = text
                completion()
            }
        }
    }
    
    // MARK: - Stage 4: Final Celebration
    private func performFinalCelebration(gameView: UIView, gameVC: GameViewController) {
        // Show success message with new styling
        gameVC.showCompletionMessage()
        
        // Create particle burst effect
        createParticleBurst(in: gameView)
        
        // Final haptic sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    private func createParticleBurst(in view: UIView) {
        let centerPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        for _ in 0..<12 {
            let particle = createParticle()
            particle.center = centerPoint
            view.addSubview(particle)
            
            animateParticle(particle, from: centerPoint)
        }
    }
    
    private func createParticle() -> UIView {
        let particle = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
        particle.backgroundColor = TerminalTheme.Colors.primaryGreen
        particle.layer.cornerRadius = 2
        particle.alpha = 0.8
        
        // Add glow
        particle.layer.shadowColor = TerminalTheme.Colors.primaryGreen.cgColor
        particle.layer.shadowOffset = CGSize.zero
        particle.layer.shadowRadius = 3
        particle.layer.shadowOpacity = 1.0
        
        return particle
    }
    
    private func animateParticle(_ particle: UIView, from startPoint: CGPoint) {
        let angle = Double.random(in: 0...(2 * Double.pi))
        let distance = CGFloat.random(in: 100...200)
        
        let endX = startPoint.x + cos(angle) * distance
        let endY = startPoint.y + sin(angle) * distance
        
        UIView.animate(withDuration: 1.5, delay: 0, options: .curveEaseOut, animations: {
            particle.center = CGPoint(x: endX, y: endY)
            particle.alpha = 0
            particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { _ in
            particle.removeFromSuperview()
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

