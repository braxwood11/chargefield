//
//  DashboardViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DashboardViewController: UIViewController {
    
    private var tutorialCompleted = false
    private let backgroundView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Employee Dashboard"
        setupBackground()
        setupUI()
    }
    
    private func setupBackground() {
        // Set the main background to black
        view.backgroundColor = .black
        
        // Add grid background
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
    
    private func setupUI() {
        // Welcome message
        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome, Field Specialist"
        welcomeLabel.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        welcomeLabel.textColor = .white
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)
        
        // Connection status indicator
        let statusView = createStatusIndicator()
        view.addSubview(statusView)
        
        // Available assignments section
        let assignmentsLabel = UILabel()
        assignmentsLabel.text = "AVAILABLE ASSIGNMENTS"
        assignmentsLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        assignmentsLabel.textColor = .green
        assignmentsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assignmentsLabel)
        
        // Tutorial button
        let tutorialButton = createAssignmentButton(
            title: "NeutraTech Orientation Training",
            subtitle: "Required for Field Operations",
            icon: "graduationcap.fill",
            tag: 0,
            color: UIColor.systemGreen.withAlphaComponent(0.8)
        )
        view.addSubview(tutorialButton)
        
        // Level 1 button
        let level1Button = createAssignmentButton(
            title: "Assignment #1",
            subtitle: "Field Neutralization Protocol",
            icon: "atom",
            tag: 1,
            color: tutorialCompleted ? UIColor.systemBlue.withAlphaComponent(0.8) : UIColor.systemGray.withAlphaComponent(0.8)
        )
        level1Button.isEnabled = tutorialCompleted
        view.addSubview(level1Button)
        
        // Level 2 button (locked initially)
        let level2Button = createAssignmentButton(
            title: "Assignment #2 (Locked)",
            subtitle: "Advanced Field Operations",
            icon: "lock.fill",
            tag: 2,
            color: UIColor.systemGray.withAlphaComponent(0.8)
        )
        level2Button.isEnabled = false
        view.addSubview(level2Button)
        
        // Messages button
        let messagesButton = createMessageButton()
        view.addSubview(messagesButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            statusView.centerYAnchor.constraint(equalTo: welcomeLabel.centerYAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusView.widthAnchor.constraint(equalToConstant: 120),
            statusView.heightAnchor.constraint(equalToConstant: 24),
            
            assignmentsLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            assignmentsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            tutorialButton.topAnchor.constraint(equalTo: assignmentsLabel.bottomAnchor, constant: 20),
            tutorialButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tutorialButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tutorialButton.heightAnchor.constraint(equalToConstant: 80),
            
            level1Button.topAnchor.constraint(equalTo: tutorialButton.bottomAnchor, constant: 15),
            level1Button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            level1Button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            level1Button.heightAnchor.constraint(equalToConstant: 80),
            
            level2Button.topAnchor.constraint(equalTo: level1Button.bottomAnchor, constant: 15),
            level2Button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            level2Button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            level2Button.heightAnchor.constraint(equalToConstant: 80),
            
            messagesButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            messagesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messagesButton.widthAnchor.constraint(equalToConstant: 280),
            messagesButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func createStatusIndicator() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        containerView.layer.borderColor = UIColor.green.withAlphaComponent(0.5).cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status dot
        let statusDot = UIView()
        statusDot.backgroundColor = .green
        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusDot)
        
        // Add pulsing animation to dot
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            statusDot.alpha = 0.4
        })
        
        // Status text
        let statusLabel = UILabel()
        statusLabel.text = "CONNECTED"
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        statusLabel.textColor = .green
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            statusDot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10)
        ])
        
        return containerView
    }
    
    private func createAssignmentButton(title: String, subtitle: String, icon: String, tag: Int, color: UIColor) -> UIButton {
        // Create custom button with background
        let button = UIButton(type: .custom)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(levelButtonTapped(_:)), for: .touchUpInside)
        
        // Button style
        button.backgroundColor = UIColor.black
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = color.cgColor
        
        // Create container view for layout
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(containerView)
        
        // Create icon image
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconImage = UIImageView(image: UIImage(systemName: icon, withConfiguration: configuration))
        iconImage.tintColor = color
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImage)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: button.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            
            iconImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 40),
            iconImage.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImage.trailingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15)
        ])
        
        return button
    }
    
    private func createMessageButton() -> UIButton {
        // Create custom button with background
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        
        // Button style
        button.backgroundColor = UIColor.black
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.8).cgColor
        
        // Create container view for layout
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(containerView)
        
        // Create envelope icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconImage = UIImageView(image: UIImage(systemName: "envelope.badge.fill", withConfiguration: configuration))
        iconImage.tintColor = UIColor.systemOrange
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImage)
        
        // Message label
        let messageLabel = UILabel()
        messageLabel.text = "Company Messages (1)"
        messageLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        messageLabel.textColor = UIColor.white
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Notification badge
        let badgeView = UIView()
        badgeView.backgroundColor = .red
        badgeView.layer.cornerRadius = 8
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(badgeView)
        
        let badgeLabel = UILabel()
        badgeLabel.text = "1"
        badgeLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)
        
        // Add pulsing animation to notification
        UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse], animations: {
            badgeView.alpha = 0.6
        })
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: button.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            
            iconImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 30),
            iconImage.heightAnchor.constraint(equalToConstant: 30),
            
            messageLabel.leadingAnchor.constraint(equalTo: iconImage.trailingAnchor, constant: 15),
            messageLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            badgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            badgeView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 16),
            badgeView.heightAnchor.constraint(equalToConstant: 16),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor)
        ])
        
        return button
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if we should update tutorial status
        if let navigationController = navigationController {
            for controller in navigationController.viewControllers {
                if let gameVC = controller as? GameViewController,
                   gameVC.tutorialCompleted {
                    tutorialCompleted = true
                    updateLevelButtons()
                    break
                }
            }
        }
    }
    
    private func updateLevelButtons() {
        // Enable level 1 button only if tutorial is completed
        if let level1Button = view.viewWithTag(1) as? UIButton {
            level1Button.isEnabled = tutorialCompleted
            level1Button.backgroundColor = UIColor.black
            level1Button.layer.borderColor = tutorialCompleted ?
                UIColor.systemBlue.withAlphaComponent(0.8).cgColor :
                UIColor.systemGray.withAlphaComponent(0.8).cgColor
            
            // Update icon color
            if let containerView = level1Button.subviews.first,
               let iconImage = containerView.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                iconImage.tintColor = tutorialCompleted ? .systemBlue : .systemGray
            }
            
            // Update title if needed
            if let containerView = level1Button.subviews.first,
               let titleLabel = containerView.subviews.first(where: {
                   ($0 is UILabel) && ($0 as? UILabel)?.font.pointSize == 16
               }) as? UILabel {
                titleLabel.text = tutorialCompleted ? "Assignment #1" : "Assignment #1 (Complete Tutorial First)"
            }
        }
    }
    
    @objc private func levelButtonTapped(_ sender: UIButton) {
        // Show dialog before starting level
        showDialog(for: sender.tag)
    }
    
    @objc private func messagesButtonTapped() {
        let messagesVC = MessagesViewController()
        navigationController?.pushViewController(messagesVC, animated: true)
    }
    
    private func showDialog(for levelTag: Int) {
        let dialogVC = DialogViewController()
        dialogVC.levelTag = levelTag
        dialogVC.completion = { [weak self] in
            // Start the level after dialog completes
            self?.startLevel(levelTag)
        }
        present(dialogVC, animated: true)
    }
    
    private func startLevel(_ levelTag: Int) {
        let gameVC = GameViewController()
        
        // Configure game for specific level
        if levelTag == 0 {
            // Tutorial level setup
            gameVC.setViewModel(GameViewModel(puzzle: .tutorialPuzzle()))
        } else if levelTag == 1 {
            // Level 1 setup
            gameVC.setViewModel(GameViewModel(puzzle: .zPatternPuzzle()))
        }
        
        // Set a flag to indicate this is being launched from the new flow
        gameVC.isLaunchedFromDashboard = true
        
        navigationController?.pushViewController(gameVC, animated: true)
    }
}
