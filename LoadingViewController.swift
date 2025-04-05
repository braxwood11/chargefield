//
//  LoadingViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 4/5/25.
//

import UIKit

class LoadingViewController: UIViewController {
    
    // UI elements
    private let loadingLabel = UILabel()
    private let progressBar = UIProgressView()
    private let statusLabel = UILabel()
    private let companyLogo = UILabel()
    private let backgroundView = UIView()
    private let cursorView = UIView() // Added as property so we can access it from typing methods
    
    // Loading messages to display
    private let loadingMessages = [
        "Establishing secure connection...",
        "Verifying credentials...",
        "Loading employee data...",
        "Scanning containment protocols...",
        "Calibrating field stabilizers...",
        "Checking anomaly reports...",
        "Synchronizing with headquarters...",
        "Connecting to NeutraTech servers...",
        "Preparing dashboard..."
    ]
    
    private var currentMessageIndex = 0
    private var progress: Float = 0.0
    private var timer: Timer?
    private var typingTimers: [Timer] = []
    
    // Public method to start the animation
    func startLoadingAnimation() {
        // Initialize with empty status text
        statusLabel.text = ""
        
        // Start typing the first message
        typeMessage(loadingMessages[0])
        
        // Set up timer to update progress (slowed down to 1.5 seconds between updates)
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        // Note: We don't start loading animation here anymore
        // It will be called from TitleViewController after transition
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add grid background
        setupGridBackground()
        
        // Company logo
        companyLogo.text = "NeutraTech"
        companyLogo.font = UIFont.boldSystemFont(ofSize: 42)
        companyLogo.textColor = .white
        companyLogo.textAlignment = .center
        companyLogo.translatesAutoresizingMaskIntoConstraints = false
        companyLogo.alpha = 0 // Start hidden for fade-in effect
        view.addSubview(companyLogo)
        
        // Loading label
        loadingLabel.text = "SYSTEM LOADING"
        loadingLabel.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        loadingLabel.textColor = .green
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.alpha = 0 // Start hidden for fade-in effect
        view.addSubview(loadingLabel)
        
        // Progress bar
        progressBar.progressTintColor = .green
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressBar.progress = 0.0
        progressBar.layer.cornerRadius = 5
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.alpha = 0 // Start hidden for fade-in effect
        view.addSubview(progressBar)
        
        // Status label
        statusLabel.text = ""
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = .green
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alpha = 0 // Start hidden for fade-in effect
        view.addSubview(statusLabel)
        
        // Create cursor view
        cursorView.backgroundColor = .green
        cursorView.translatesAutoresizingMaskIntoConstraints = false
        cursorView.alpha = 0 // Start hidden for fade-in effect
        view.addSubview(cursorView)
        
        // Set initial cursor size and position
        cursorView.frame = CGRect(x: 0, y: 0, width: 2, height: 16)
        
        // We'll initially position it relative to the status label
        // but we won't use Auto Layout constraints since we'll be manually positioning it
        
        NSLayoutConstraint.activate([
            companyLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            companyLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBar.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 20),
            progressBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressBar.heightAnchor.constraint(equalToConstant: 10),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 20),
            statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
        
        // Add blinking animation to cursor
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.cursorView.alpha = 0.3 // Blink between full visibility and partial visibility
        })
        
        // Fade in UI elements
        UIView.animate(withDuration: 1.0) {
            self.companyLogo.alpha = 1
            self.loadingLabel.alpha = 1
            self.progressBar.alpha = 1
            self.statusLabel.alpha = 1
            self.cursorView.alpha = 1
        }
        
        // Position cursor initially
        positionCursor()
    }
    
    // New method to position the cursor at the end of the text
    private func positionCursor() {
        // Get the current text
        let text = statusLabel.text ?? ""
        
        // Create temporary label to calculate text width
        let tempLabel = UILabel()
        tempLabel.font = statusLabel.font
        tempLabel.text = text
        tempLabel.sizeToFit()
        
        // Get width of the current text
        let textWidth = tempLabel.frame.width
        
        // Position cursor at the end of text
        let cursorX = statusLabel.frame.origin.x + (statusLabel.frame.width / 2) + (textWidth / 2) + 2
        let cursorY = statusLabel.frame.origin.y + (statusLabel.frame.height - cursorView.frame.height) / 2
        
        // Update cursor position
        cursorView.frame.origin = CGPoint(x: cursorX, y: cursorY)
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
        let intersections = min(20, Int((view.bounds.width / gridSize) * (view.bounds.height / gridSize) / 10))
        
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
                animateDotPulse(dotView)
            }
        }
    }
    
    private func animateDotPulse(_ dotView: UIView) {
        UIView.animate(withDuration: Double.random(in: 1.5...3.0), delay: 0, options: [.repeat, .autoreverse], animations: {
            dotView.alpha = CGFloat.random(in: 0.1...0.3)
        })
    }
    
    // Simple but reliable typing animation
    private func typeMessage(_ message: String) {
        // Cancel any previous typing
        for timer in typingTimers {
            timer.invalidate()
        }
        typingTimers.removeAll()
        
        // Reset the label
        statusLabel.text = ""
        
        // Position cursor at the beginning
        positionCursor()
        
        // Type each character with a delay - faster typing (0.05s per character)
        for (index, character) in message.enumerated() {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.05 * Double(index), repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                // Add character
                self.statusLabel.text = (self.statusLabel.text ?? "") + String(character)
                
                // Reposition cursor at the end of text
                self.positionCursor()
            }
            typingTimers.append(timer)
        }
    }
    
    @objc private func updateProgress() {
        // Increase progress at a moderate pace
        progress += 0.08
        
        // Update progress bar with animation
        UIView.animate(withDuration: 0.3) {
            self.progressBar.setProgress(min(self.progress, 1.0), animated: true)
        }
        
        // Update loading message periodically
        let targetMessageIndex = min(Int(progress * Float(loadingMessages.count)), loadingMessages.count - 1)
        if targetMessageIndex > currentMessageIndex {
            currentMessageIndex = targetMessageIndex
            typeMessage(loadingMessages[currentMessageIndex])
        }
        
        // When loading is complete
        if progress >= 1.0 {
            timer?.invalidate()
            
            // Add a small delay before transitioning to dashboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showCompletedMessage()
            }
        }
    }
    
    private func showCompletedMessage() {
        // Reset status label
        statusLabel.text = ""
        statusLabel.textColor = UIColor.green
        
        // Position cursor at the beginning
        positionCursor()
        
        // Type out the "ACCESS GRANTED" message with a typing effect
        let completionMessage = "ACCESS GRANTED"
        
        // Type each character with a delay - slightly faster typing (0.1s per character)
        for (index, character) in completionMessage.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                self.statusLabel.text = (self.statusLabel.text ?? "") + String(character)
                
                // Reposition cursor after each character
                self.positionCursor()
                
                // When typing is complete, show the flash and transition
                if self.statusLabel.text == completionMessage {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showFlashAndTransition()
                    }
                }
            }
        }
    }
    
    private func showFlashAndTransition() {
        // Flash the screen green briefly for a computer effect
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        view.addSubview(flashView)
        
        // Animate the flash and then transition to dashboard
        UIView.animate(withDuration: 0.5, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
            
            // Navigate to dashboard
            let dashboardVC = DashboardViewController()
            self.navigationController?.pushViewController(dashboardVC, animated: true)
        }
    }
}
