//
//  LoadingViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 4/5/25.
//

import UIKit

class LoadingViewController: UIViewController {
    
    // MARK: - UI Elements
    private let loadingLabel = TerminalLabel()
    private let progressBar = UIProgressView()
    private let statusLabel = TerminalLabel()
    private let companyLogo = UIImageView() // Changed from UILabel to UIImageView
    private let cursorView = UIView()
    
    // MARK: - Properties
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func startLoadingAnimation() {
        // Initialize with empty status text
        statusLabel.text = ""
        
        // Start typing the first message
        typeMessage(loadingMessages[0])
        
        // Set up timer to update progress
        timer = Timer.scheduledTimer(
            timeInterval: 1.5,
            target: self,
            selector: #selector(updateProgress),
            userInfo: nil,
            repeats: true
        )
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Apply terminal theme background
        TerminalTheme.applyBackground(to: self)
        
        // Company logo - Updated to use image
        setupCompanyLogo()
        
        // Loading label
        loadingLabel.text = "SYSTEM LOADING"
        loadingLabel.style = .heading
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.alpha = 0
        view.addSubview(loadingLabel)
        
        // Progress bar
        progressBar.progressTintColor = TerminalTheme.Colors.primaryGreen
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressBar.progress = 0.0
        progressBar.layer.cornerRadius = 5
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.alpha = 0
        view.addSubview(progressBar)
        
        // Status label
        statusLabel.text = ""
        statusLabel.style = .terminal
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alpha = 0
        view.addSubview(statusLabel)
        
        // Cursor view
        cursorView.backgroundColor = TerminalTheme.Colors.primaryGreen
        cursorView.translatesAutoresizingMaskIntoConstraints = false
        cursorView.alpha = 0
        view.addSubview(cursorView)
        
        cursorView.frame = CGRect(x: 0, y: 0, width: 2, height: 16)
        
        // Set constraints
        setupConstraints()
        
        // Add blinking animation to cursor
        animateCursor()
        
        // Fade in UI elements
        fadeInUIElements()
    }
    
    private func setupCompanyLogo() {
        // Load the logo image
        companyLogo.image = UIImage(named: "NT-Logo-2")
        companyLogo.contentMode = .scaleAspectFit
        companyLogo.translatesAutoresizingMaskIntoConstraints = false
        companyLogo.alpha = 0
        
        // Optional: Add a subtle tint if you want the logo to match the terminal theme
        // companyLogo.tintColor = .white
        
        view.addSubview(companyLogo)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Company logo - adjusted constraints for image
            companyLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            companyLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            companyLogo.widthAnchor.constraint(lessThanOrEqualToConstant: 250), // Max width
            companyLogo.heightAnchor.constraint(lessThanOrEqualToConstant: 175), // Max height
            
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
    }
    
    // MARK: - Animations
    private func animateCursor() {
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                self.cursorView.alpha = 0.3
            }
        )
    }
    
    private func fadeInUIElements() {
        UIView.animate(withDuration: 1.0) {
            self.companyLogo.alpha = 1
            self.loadingLabel.alpha = 1
            self.progressBar.alpha = 1
            self.statusLabel.alpha = 1
            self.cursorView.alpha = 1
        }
    }
    
    // MARK: - Typing Animation
    private func typeMessage(_ message: String) {
        // Cancel any previous typing
        typingTimers.forEach { $0.invalidate() }
        typingTimers.removeAll()
        
        // Reset the label
        statusLabel.text = ""
        
        // Position cursor at the beginning
        positionCursor()
        
        // Type each character with a delay
        for (index, character) in message.enumerated() {
            let timer = Timer.scheduledTimer(
                withTimeInterval: 0.05 * Double(index),
                repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }
                
                self.statusLabel.text = (self.statusLabel.text ?? "") + String(character)
                self.positionCursor()
            }
            typingTimers.append(timer)
        }
    }
    
    private func positionCursor() {
        let text = statusLabel.text ?? ""
        
        // Create temporary label to calculate text width
        let tempLabel = UILabel()
        tempLabel.font = statusLabel.font
        tempLabel.text = text
        tempLabel.sizeToFit()
        
        let textWidth = tempLabel.frame.width
        
        // Position cursor at the end of text
        let cursorX = statusLabel.frame.origin.x + (statusLabel.frame.width / 2) + (textWidth / 2) + 2
        let cursorY = statusLabel.frame.origin.y + (statusLabel.frame.height - cursorView.frame.height) / 2
        
        cursorView.frame.origin = CGPoint(x: cursorX, y: cursorY)
    }
    
    // MARK: - Progress Updates
    @objc private func updateProgress() {
        // Increase progress
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
            
            // Add a small delay before transitioning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showCompletedMessage()
            }
        }
    }
    
    private func showCompletedMessage() {
        // Clear typing timers
        typingTimers.forEach { $0.invalidate() }
        typingTimers.removeAll()
        
        // Reset status label
        statusLabel.text = ""
        statusLabel.textColor = TerminalTheme.Colors.primaryGreen
        
        // Type out the "ACCESS GRANTED" message
        let completionMessage = "ACCESS GRANTED"
        
        for (index, character) in completionMessage.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                self.statusLabel.text = (self.statusLabel.text ?? "") + String(character)
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
        // Flash the screen green briefly
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.3)
        view.addSubview(flashView)
        
        // Animate the flash and then transition
        UIView.animate(withDuration: 0.5, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
            self.navigateToDashboard()
        }
    }
    
    private func navigateToDashboard() {
        let dashboardVC = DashboardViewController()
        navigationController?.pushViewController(dashboardVC, animated: true)
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        
        typingTimers.forEach { $0.invalidate() }
        typingTimers.removeAll()
    }
}
