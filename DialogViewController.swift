//
//  DialogViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DialogViewController: UIViewController {
    var levelTag: Int = 0
    var completion: (() -> Void)?
    
    private let containerView = UIView()
    private let characterNameLabel = UILabel()
    private let dialogTextLabel = UILabel()
    private let continueButton = UIButton()
    private let backgroundView = UIView()
    private let cursorView = UIView()
    private let promptLabel = UILabel()
    
    // Sample dialogs for prototype
    private let tutorialDialogs = [
        (speaker: "Dr. Morgan", text: "Welcome to NeutraTech! I'll be guiding you through your orientation."),
        (speaker: "Dr. Morgan", text: "Your job is to stabilize energy anomalies using our proprietary tools."),
        (speaker: "Dr. Morgan", text: "You'll place stabilizers and suppressors to achieve the target energy values."),
        (speaker: "Dr. Morgan", text: "Don't worry about what these anomalies are yet - just focus on the numbers for now.")
    ]
    
    private let level1Dialogs = [
        (speaker: "Supervisor Chen", text: "Good work on the training. Ready for your first real assignment?"),
        (speaker: "Supervisor Chen", text: "These anomalies are a bit more complex. Remember your training."),
        (speaker: "Supervisor Chen", text: "And don't ask too many questions about what we're processing. Company policy.")
    ]
    
    private var currentDialogs: [(speaker: String, text: String)] = []
    private var dialogIndex = 0
    private var textTypingIndex = 0
    private var typingTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dialogs based on level
        if levelTag == 0 {
            currentDialogs = tutorialDialogs
        } else if levelTag == 1 {
            currentDialogs = level1Dialogs
        }
        
        setupUI()
    }
    
    private func setupUI() {
        // Set black background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        // Setup background grid
        setupGridBackground()
        
        // Container
        containerView.backgroundColor = .black
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Terminal prompt
        promptLabel.text = "dialog> communication_initialized"
        promptLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        promptLabel.textColor = .green
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(promptLabel)
        
        // Character name with terminal styling
        characterNameLabel.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        characterNameLabel.textColor = .green
        characterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(characterNameLabel)
        
        // Dialog text with terminal styling
        dialogTextLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        dialogTextLabel.textColor = .white
        dialogTextLabel.numberOfLines = 0
        dialogTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Pre-calculate max height for dialog text based on longest possible text
        // This prevents container resizing during typing
        let maxTextHeight = calculateMaxDialogHeight()
        containerView.addSubview(dialogTextLabel)
        
        // Add a security badge
        let securityBadge = createSecurityBadge()
        containerView.addSubview(securityBadge)
        
        // Continue button with terminal styling
        continueButton.setTitle("CONTINUE", for: .normal)
        continueButton.backgroundColor = .black
        continueButton.setTitleColor(.green, for: .normal)
        continueButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        continueButton.layer.cornerRadius = 8
        continueButton.layer.borderWidth = 2
        continueButton.layer.borderColor = UIColor.green.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        containerView.addSubview(continueButton)
        
        // Set constraints with fixed dialog height and button position
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
            continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Start showing the current dialog with typing effect
        startShowingDialog()
    }
    
    private func calculateMaxDialogHeight() -> CGFloat {
        // Find the longest dialog message
        let maxMessage = currentDialogs.map { $0.text }.max(by: { $0.count < $1.count }) ?? ""
        
        // Create a temporary label to calculate the required height
        let tempLabel = UILabel()
        tempLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        tempLabel.numberOfLines = 0
        
        // Calculate available width (screen width minus margins)
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 25 * 2 - 20 * 2 // Account for container margins and label padding
        
        // Set the text and preferred width
        tempLabel.text = maxMessage
        tempLabel.preferredMaxLayoutWidth = availableWidth
        
        // Calculate the size
        tempLabel.sizeToFit()
        
        // Return the height plus some extra padding for safety
        return max(tempLabel.frame.height, 80) // Minimum height of 80
    }
    
    private func setupGridBackground() {
        // Create a grid pattern background
        backgroundView.frame = view.bounds
        backgroundView.backgroundColor = .clear
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        // Create grid lines
        let gridSize: CGFloat = 30
        let lineWidth: CGFloat = 0.5
        let lineColor = UIColor.green.withAlphaComponent(0.2)
        
        // Horizontal lines
        for y in stride(from: 0, to: view.bounds.height, by: gridSize) {
            let lineView = UIView(frame: CGRect(x: 0, y: y, width: view.bounds.width, height: lineWidth))
            lineView.backgroundColor = lineColor
            backgroundView.addSubview(lineView)
        }
        
        // Vertical lines
        for x in stride(from: 0, to: view.bounds.width, by: gridSize) {
            let lineView = UIView(frame: CGRect(x: x, y: 0, width: lineWidth, height: view.bounds.height))
            lineView.backgroundColor = lineColor
            backgroundView.addSubview(lineView)
        }
        
        // Add glow dots at random intersections
        let intersections = min(15, Int((view.bounds.width / gridSize) * (view.bounds.height / gridSize) / 12))
        
        for _ in 0..<intersections {
            let randomX = Int.random(in: 1..<Int(view.bounds.width / gridSize)) * Int(gridSize)
            let randomY = Int.random(in: 1..<Int(view.bounds.height / gridSize)) * Int(gridSize)
            
            let dotSize: CGFloat = 4
            let dotView = UIView(frame: CGRect(x: CGFloat(randomX) - dotSize/2, y: CGFloat(randomY) - dotSize/2, width: dotSize, height: dotSize))
            dotView.backgroundColor = .green
            dotView.layer.cornerRadius = dotSize/2
            dotView.alpha = CGFloat.random(in: 0.2...0.6)
            backgroundView.addSubview(dotView)
            
            // Add pulse animation to some dots
            if Bool.random() {
                UIView.animate(withDuration: Double.random(in: 1.5...3.0), delay: 0, options: [.repeat, .autoreverse], animations: {
                    dotView.alpha = CGFloat.random(in: 0.1...0.3)
                })
            }
        }
    }
    
    private func createSecurityBadge() -> UIView {
        let securityBadge = UIView()
        securityBadge.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        securityBadge.layer.borderColor = UIColor.green.cgColor
        securityBadge.layer.borderWidth = 1
        securityBadge.layer.cornerRadius = 4
        securityBadge.translatesAutoresizingMaskIntoConstraints = false
        
        let securityLabel = UILabel()
        securityLabel.text = "INTERNAL"
        securityLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        securityLabel.textColor = .green
        securityLabel.textAlignment = .center
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityBadge.addSubview(securityLabel)
        
        NSLayoutConstraint.activate([
            securityLabel.centerXAnchor.constraint(equalTo: securityBadge.centerXAnchor),
            securityLabel.centerYAnchor.constraint(equalTo: securityBadge.centerYAnchor)
        ])
        
        return securityBadge
    }
    
    private func startShowingDialog() {
        guard dialogIndex < currentDialogs.count else {
            // End of dialog
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
        typingTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(typeText), userInfo: nil, repeats: true)
    }
    
    @objc private func typeText() {
        guard dialogIndex < currentDialogs.count else { return }
        
        let fullText = currentDialogs[dialogIndex].text
        if textTypingIndex < fullText.count {
            // Get up to current character index
            let index = fullText.index(fullText.startIndex, offsetBy: textTypingIndex)
            dialogTextLabel.text = String(fullText[..<index])
            textTypingIndex += 1
        } else {
            // Typing complete
            dialogTextLabel.text = fullText
            typingTimer?.invalidate()
            
            // Add subtle flash animation to the continue button
            animateContinueButton()
        }
    }
    
    private func positionCursorAtEndOfText() {
        guard let text = dialogTextLabel.text else {
            // Default position if no text
            cursorView.frame = CGRect(
                x: dialogTextLabel.frame.origin.x,
                y: dialogTextLabel.frame.origin.y,
                width: 2,
                height: dialogTextLabel.font.lineHeight
            )
            return
        }
        
        // Use text-based measurement instead of layout calculation
        // This avoids the need to calculate multi-line positions which was causing issues
        
        // Create a textStorage with our current text
        let textStorage = NSTextStorage(string: text, attributes: [
            .font: dialogTextLabel.font ?? UIFont.systemFont(ofSize: 16)
        ])
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: dialogTextLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        // Get the position of the last character
        let range = NSRange(location: text.count - 1, length: 1)
        var rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
        
        // If text is empty, use the origin
        if text.isEmpty {
            rect = CGRect(x: 0, y: 0, width: 0, height: dialogTextLabel.font.lineHeight)
        }
        
        // Position cursor just after the last character
        let cursorX = dialogTextLabel.frame.origin.x + rect.maxX + 2
        let cursorY = dialogTextLabel.frame.origin.y + rect.origin.y
        
        // Update cursor position without resizing the container
        cursorView.frame = CGRect(
            x: cursorX,
            y: cursorY,
            width: 2,
            height: dialogTextLabel.font.lineHeight
        )
    }
    
    private func animateContinueButton() {
        // Add pulsing animation to the continue button
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.continueButton.alpha = 0.6
        }) { _ in
            self.continueButton.alpha = 1.0
        }
    }
    
    @objc private func continueButtonTapped() {
        // Add button press effect
        UIView.animate(withDuration: 0.1, animations: {
            self.continueButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.continueButton.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.continueButton.transform = CGAffineTransform.identity
                self.continueButton.alpha = 1.0
            }) { _ in
                // Move to next dialog
                self.dialogIndex += 1
                self.cursorView.isHidden = false
                self.startShowingDialog()
                
                // Stop continue button animation
                self.continueButton.layer.removeAllAnimations()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Optional: Allow tapping anywhere to continue
        // If typing hasn't finished, complete it immediately
        if textTypingIndex < currentDialogs[dialogIndex].text.count {
            typingTimer?.invalidate()
            dialogTextLabel.text = currentDialogs[dialogIndex].text
            textTypingIndex = currentDialogs[dialogIndex].text.count
            cursorView.isHidden = true
            animateContinueButton()
        } else {
            // If typing is done, advance to next dialog
            continueButtonTapped()
        }
    }
}
