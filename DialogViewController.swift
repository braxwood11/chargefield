//
//  DialogViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DialogViewController: UIViewController {
    
    // MARK: - Properties
    var assignmentId: String = ""
    var completion: (() -> Void)?
    
    private var currentDialogs: [DialogMessage] = []
    private var dialogIndex = 0
    private var textTypingIndex = 0
    private var typingTimer: Timer?
    
    // MARK: - UI Elements
    private let containerView = TerminalContainerView()
    private let characterNameLabel = TerminalLabel()
    private let dialogTextLabel = TerminalLabel()
    private let continueButton = TerminalButton()
    private let promptLabel = TerminalLabel()
    private let securityBadge = UIView()
    
    // MARK: - Dialog Data
    private let dialogData = DialogDataProvider()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDialogs()
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    private func loadDialogs() {
        currentDialogs = dialogData.getDialogs(for: assignmentId)
    }
    
    private func setupUI() {
        // Semi-transparent black background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        // Apply grid background
        let gridBackground = TerminalTheme.createGridBackground(for: view.bounds)
        gridBackground.alpha = 0.3
        view.addSubview(gridBackground)
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Invisible button overlay for anywhere tapping
        let buttonOverlay = UIButton(type: .system)
        buttonOverlay.backgroundColor = .clear
        buttonOverlay.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        buttonOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonOverlay)
        
        // Terminal prompt
        promptLabel.style = .terminal
        promptLabel.text = "dialog> communication_initialized"
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(promptLabel)
        
        // Character name
        characterNameLabel.style = .heading
        characterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(characterNameLabel)
        
        // Dialog text
        dialogTextLabel.style = .body
        dialogTextLabel.numberOfLines = 0
        dialogTextLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dialogTextLabel)
        
        // Security badge
        setupSecurityBadge()
        containerView.addSubview(securityBadge)
        
        // Continue button
        continueButton.style = .primary
        continueButton.setTitle("CONTINUE", for: .normal)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        containerView.addSubview(continueButton)
        
        // Calculate max height for dialog text
        let maxTextHeight = calculateMaxDialogHeight()
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            
            promptLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            promptLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            promptLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            characterNameLabel.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 15),
            characterNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            securityBadge.centerYAnchor.constraint(equalTo: characterNameLabel.centerYAnchor),
            securityBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            securityBadge.heightAnchor.constraint(equalToConstant: 20),
            securityBadge.widthAnchor.constraint(equalToConstant: 80),
            
            dialogTextLabel.topAnchor.constraint(equalTo: characterNameLabel.bottomAnchor, constant: 15),
            dialogTextLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dialogTextLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            dialogTextLabel.heightAnchor.constraint(equalToConstant: maxTextHeight),
            
            continueButton.topAnchor.constraint(equalTo: dialogTextLabel.bottomAnchor, constant: 25),
            continueButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            continueButton.widthAnchor.constraint(equalToConstant: 120),
            continueButton.heightAnchor.constraint(equalToConstant: 44),
            continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            buttonOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            buttonOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Start showing dialog
        startShowingDialog()
    }
    
    private func setupSecurityBadge() {
        securityBadge.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.2)
        securityBadge.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        securityBadge.layer.borderWidth = 1
        securityBadge.layer.cornerRadius = 4
        securityBadge.translatesAutoresizingMaskIntoConstraints = false
        
        let securityLabel = TerminalLabel()
        securityLabel.style = .caption
        securityLabel.text = "INTERNAL"
        securityLabel.font = TerminalTheme.Fonts.monospaced(size: 10, weight: .bold)
        securityLabel.textAlignment = .center
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityBadge.addSubview(securityLabel)
        
        NSLayoutConstraint.activate([
            securityLabel.centerXAnchor.constraint(equalTo: securityBadge.centerXAnchor),
            securityLabel.centerYAnchor.constraint(equalTo: securityBadge.centerYAnchor)
        ])
    }
    
    // MARK: - Dialog Display
    private func calculateMaxDialogHeight() -> CGFloat {
        let maxMessage = currentDialogs.map { $0.text }.max(by: { $0.count < $1.count }) ?? ""
        
        let tempLabel = UILabel()
        tempLabel.font = TerminalTheme.Fonts.monospaced(size: 16)
        tempLabel.numberOfLines = 0
        
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 25 * 2 - 20 * 2
        
        tempLabel.text = maxMessage
        tempLabel.preferredMaxLayoutWidth = availableWidth
        tempLabel.sizeToFit()
        
        return max(tempLabel.frame.height, 80)
    }
    
    private func startShowingDialog() {
        guard dialogIndex < currentDialogs.count else {
            dismiss(animated: true) {
                self.completion?()
            }
            return
        }
        
        let dialog = currentDialogs[dialogIndex]
        characterNameLabel.text = dialog.speaker
        dialogTextLabel.text = ""
        textTypingIndex = 0
        
        // Start typing animation
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(
            timeInterval: 0.03,
            target: self,
            selector: #selector(typeText),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func typeText() {
        guard dialogIndex < currentDialogs.count else { return }
        
        let fullText = currentDialogs[dialogIndex].text
        if textTypingIndex < fullText.count {
            let index = fullText.index(fullText.startIndex, offsetBy: textTypingIndex)
            dialogTextLabel.text = String(fullText[..<index])
            textTypingIndex += 1
        } else {
            // Typing complete
            dialogTextLabel.text = fullText
            typingTimer?.invalidate()
            animateContinueButton()
        }
    }
    
    private func animateContinueButton() {
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse]) {
            self.continueButton.alpha = 0.6
        } completion: { _ in
            self.continueButton.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func continueButtonTapped() {
        // If typing isn't finished, complete it immediately
        if textTypingIndex < currentDialogs[safe: dialogIndex]?.text.count ?? 0 {
            typingTimer?.invalidate()
            dialogTextLabel.text = currentDialogs[dialogIndex].text
            textTypingIndex = currentDialogs[dialogIndex].text.count
            animateContinueButton()
            return
        }
        
        // Button press animation
        UIView.animate(withDuration: 0.1, animations: {
            self.continueButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.continueButton.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.continueButton.transform = .identity
                self.continueButton.alpha = 1.0
            }) { _ in
                // Move to next dialog
                self.dialogIndex += 1
                self.startShowingDialog()
                self.continueButton.layer.removeAllAnimations()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        continueButtonTapped()
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        typingTimer?.invalidate()
        typingTimer = nil
    }
}

// MARK: - Dialog Message Model
struct DialogMessage {
    let speaker: String
    let text: String
}

// MARK: - Dialog Data Provider
class DialogDataProvider {
    
    func getDialogs(for assignmentId: String) -> [DialogMessage] {
        switch assignmentId {
        case "tutorial_basics":
            return tutorialDialogs
        case "tutorial_advanced":
            return advancedTutorialDialogs
        case "tutorial_correction":
            return correctionTutorialDialogs
        case "tutorial_efficiency":
            return efficiencyTutorialDialogs
        case "random_puzzle":
            return randomPuzzleDialogs
        default:
            return defaultDialogs
        }
    }
    
    private let tutorialDialogs = [
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "Welcome to NeutraTech! I'll be guiding you through your orientation."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "Your job is to stabilize energy anomalies using our proprietary harmonization tools."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "You'll place stabilizers and suppressors to achieve the target energy values."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "The work you are doing is crucial to our facility. It's important to stay focused and take your time."
        )
    ]
    
    private let advancedTutorialDialogs = [
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "Excellent work on your basic training. Now we'll explore more sophisticated techniques."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "You'll learn how multiple harmonization tools can work together to solve complex field problems."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "Understanding field overlap is critical for efficient energy management."
        ),
        DialogMessage(
            speaker: "Dr. Morgan",
            text: "Pay attention to how placement affects multiple targets simultaneously."
        )
    ]
    
    private let correctionTutorialDialogs = [
        DialogMessage(
            speaker: "Senior Technician Walsh",
            text: "Dr. Morgan asked me to teach you about precision protocols."
        ),
        DialogMessage(
            speaker: "Senior Technician Walsh",
            text: "Sometimes field correction can go too far. We call this 'overshoot.'"
        ),
        DialogMessage(
            speaker: "Senior Technician Walsh",
            text: "Learning to recognize and correct overshoot is essential for safety."
        ),
        DialogMessage(
            speaker: "Senior Technician Walsh",
            text: "Remember: precision is more important than speed in our line of work."
        )
    ]
    
    private let efficiencyTutorialDialogs = [
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "Your progress has been noted. Time for advanced resource management training."
        ),
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "In the field, you won't always have unlimited harmonization tools."
        ),
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "Efficiency isn't just about speed - it's about using minimal resources for maximum effect."
        ),
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "Master this, and you'll be ready for the most challenging assignments."
        )
    ]
    
    private let randomPuzzleDialogs = [
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "Good work on your first training. Ready to step it up to the next level?"
        ),
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "These anomalies are a bit more complex. Remember your training."
        ),
        DialogMessage(
            speaker: "Supervisor Chen",
            text: "No matter what happens in there, don't panic. I'll be watching."
        )
    ]
    
    private let defaultDialogs = [
        DialogMessage(
            speaker: "System",
            text: "Assignment loading..."
        )
    ]
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
