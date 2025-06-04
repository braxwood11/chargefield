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

// MARK: - Game Animation Controller
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
        guard let view = viewController?.view else { return }
        
        // Create success flash
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.2)
        flashView.alpha = 0
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.2, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
    
    func showCompletionMessage() {
        messageView?.isHidden = false
        
        // Animate message appearance
        messageView?.alpha = 0
        messageView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.messageView?.alpha = 1
            self.messageView?.transform = .identity
        }
    }
    
    func hideCompletionMessage() {
        UIView.animate(withDuration: 0.3) {
            self.messageView?.alpha = 0
        } completion: { _ in
            self.messageView?.isHidden = true
        }
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
