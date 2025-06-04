//
//  DashboardViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DashboardViewController: UIViewController {
    
    // MARK: - Properties
    private let progress = GameProgressManager.shared
    private var assignmentButtons: [UIButton] = []
    private var messagesBadgeLabel: UILabel?
    
    // MARK: - UI Elements
    private let titleView = UIView()
    private let welcomeLabel = TerminalLabel()
    private let assignmentsLabel = TerminalLabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Employee Dashboard"
        setupUI()
        
        // Listen for message updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMessagesBadge),
            name: .newMessageReceived,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        updateAssignmentButtons()
        updateMessagesBadge()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Apply terminal theme
        TerminalTheme.applyBackground(to: self)
        
        // Create header
        setupHeader()
        
        // Create content
        setupContent()
    }
    
    private func setupHeader() {
        titleView.backgroundColor = .clear
        titleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleView)
        
        // Terminal prompt
        let promptLabel = TerminalLabel()
        promptLabel.style = .terminal
        promptLabel.text = ">"
        promptLabel.font = TerminalTheme.Fonts.monospaced(size: 18, weight: .bold)
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(promptLabel)
        
        // Dashboard title
        let titleLabel = TerminalLabel()
        titleLabel.style = .title
        titleLabel.text = "Employee Dashboard"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(titleLabel)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.3)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        
        // Connection status
        let statusView = createStatusIndicator()
        view.addSubview(statusView)
        
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleView.heightAnchor.constraint(equalToConstant: 44),
            
            promptLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 20),
            promptLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 5),
            titleLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            
            separatorLine.topAnchor.constraint(equalTo: titleView.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            statusView.widthAnchor.constraint(equalToConstant: 107),
            statusView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupContent() {
        // Welcome message
        welcomeLabel.style = .heading
        welcomeLabel.text = "Welcome, Field Specialist"
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)
        
        // Assignments section
        assignmentsLabel.style = .body
        assignmentsLabel.text = "AVAILABLE ASSIGNMENTS"
        assignmentsLabel.textColor = TerminalTheme.Colors.primaryGreen
        assignmentsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assignmentsLabel)
        
        // Create assignment buttons
        let tutorialButton = createAssignmentButton(
            assignment: Assignment(
                id: "tutorial_basics",
                title: "NeutraTech Orientation #1",
                subtitle: "Required for Field Operations",
                icon: "graduationcap.fill",
                type: .tutorial,
                isLocked: false
            )
        )
        view.addSubview(tutorialButton)
        assignmentButtons.append(tutorialButton)
        
        let randomButton = createAssignmentButton(
            assignment: Assignment(
                id: "random_puzzle",
                title: "Random Assignment",
                subtitle: "Field Neutralization Challenge",
                icon: "atom",
                type: .random,
                isLocked: !progress.hasCompletedTutorial
            )
        )
        view.addSubview(randomButton)
        assignmentButtons.append(randomButton)
        
        let advancedButton = createAssignmentButton(
            assignment: Assignment(
                id: "advanced_tutorial",
                title: "Assignment #2 (Locked)",
                subtitle: "Advanced Field Operations",
                icon: "lock.fill",
                type: .campaign,
                isLocked: true
            )
        )
        view.addSubview(advancedButton)
        assignmentButtons.append(advancedButton)
        
        // Messages button
        let messagesButton = createMessageButton()
        view.addSubview(messagesButton)
        
        // Layout
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 30),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            assignmentsLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            assignmentsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            tutorialButton.topAnchor.constraint(equalTo: assignmentsLabel.bottomAnchor, constant: 20),
            tutorialButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tutorialButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tutorialButton.heightAnchor.constraint(equalToConstant: 80),
            
            randomButton.topAnchor.constraint(equalTo: tutorialButton.bottomAnchor, constant: 15),
            randomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            randomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            randomButton.heightAnchor.constraint(equalToConstant: 80),
            
            advancedButton.topAnchor.constraint(equalTo: randomButton.bottomAnchor, constant: 15),
            advancedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            advancedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            advancedButton.heightAnchor.constraint(equalToConstant: 80),
            
            messagesButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            messagesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messagesButton.widthAnchor.constraint(equalToConstant: 280),
            messagesButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - UI Components
    private func createStatusIndicator() -> UIView {
        let containerView = TerminalContainerView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status dot
        let statusDot = UIView()
        statusDot.backgroundColor = TerminalTheme.Colors.primaryGreen
        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusDot)
        
        // Add pulsing animation
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse]) {
            statusDot.alpha = 0.4
        }
        
        // Status text
        let statusLabel = TerminalLabel()
        statusLabel.style = .terminal
        statusLabel.text = "CONNECTED"
        statusLabel.font = TerminalTheme.Fonts.monospaced(size: 12, weight: .bold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            statusDot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5)
        ])
        
        return containerView
    }
    
    private func createAssignmentButton(assignment: Assignment) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = assignment.hashValue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(assignmentButtonTapped(_:)), for: .touchUpInside)
        
        // Store assignment data
        button.accessibilityIdentifier = assignment.id
        
        // Style
        TerminalTheme.styleContainer(button)
        
        // Container for content
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(containerView)
        
        // Icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconImage = UIImageView(image: UIImage(systemName: assignment.icon, withConfiguration: configuration))
        iconImage.tintColor = assignment.iconColor
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImage)
        
        // Title
        let titleLabel = TerminalLabel()
        titleLabel.style = .body
        titleLabel.text = assignment.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = TerminalLabel()
        subtitleLabel.style = .caption
        subtitleLabel.text = assignment.subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Status indicator (checkmark for completed)
        if progress.isLevelCompleted(assignment.id) {
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            checkmark.tintColor = TerminalTheme.Colors.primaryGreen
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(checkmark)
            
            NSLayoutConstraint.activate([
                checkmark.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
                checkmark.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                checkmark.widthAnchor.constraint(equalToConstant: 24),
                checkmark.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        
        // Apply locked state
        button.isEnabled = !assignment.isLocked
        if assignment.isLocked {
            button.alpha = 0.5
            iconImage.tintColor = .systemGray
        }
        
        // Layout
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
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50)
        ])
        
        return button
    }
    
    private func createMessageButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        
        // Style
        TerminalTheme.styleContainer(button)
        button.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.8).cgColor
        
        // Container
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(containerView)
        
        // Icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconImage = UIImageView(image: UIImage(systemName: "envelope.badge.fill", withConfiguration: configuration))
        iconImage.tintColor = UIColor.systemOrange
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImage)
        
        // Label
        let messageLabel = TerminalLabel()
        messageLabel.style = .body
        messageLabel.text = "Company Messages"
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Badge
        let badgeView = UIView()
        badgeView.backgroundColor = .red
        badgeView.layer.cornerRadius = 8
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(badgeView)
        
        let badgeLabel = TerminalLabel()
        badgeLabel.text = "0"
        badgeLabel.style = .caption
        badgeLabel.textColor = .white
        badgeLabel.font = TerminalTheme.Fonts.monospaced(size: 12, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)
        
        // Store reference for updates
        messagesBadgeLabel = badgeLabel
        
        // Layout
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
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badgeView.heightAnchor.constraint(equalToConstant: 16),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4)
        ])
        
        updateMessagesBadge()
        
        return button
    }
    
    // MARK: - Updates
    private func updateAssignmentButtons() {
        // Refresh button states based on progress
        for button in assignmentButtons {
            guard let assignmentId = button.accessibilityIdentifier else { continue }
            
            switch assignmentId {
            case "random_puzzle":
                button.isEnabled = progress.hasCompletedTutorial
                button.alpha = progress.hasCompletedTutorial ? 1.0 : 0.5
                
                // Update icon color
                if let iconView = button.subviews.first?.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                    iconView.tintColor = progress.hasCompletedTutorial ? .systemBlue : .systemGray
                }
                
                // Update title
                if let titleLabel = button.subviews.first?.subviews.first(where: {
                    ($0 is UILabel) && ($0 as? UILabel)?.font.pointSize == 16
                }) as? UILabel {
                    titleLabel.text = progress.hasCompletedTutorial ? "Assignment #1" : "Assignment #1 (Complete Tutorial First)"
                }
                
            default:
                break
            }
        }
    }
    
    @objc private func updateMessagesBadge() {
        let unreadCount = MessageManager.shared.getUnreadCount()
        messagesBadgeLabel?.text = "\(unreadCount)"
        
        // Hide badge if no unread messages
        messagesBadgeLabel?.superview?.isHidden = unreadCount == 0
        
        // Add pulsing animation for new messages
        if unreadCount > 0 {
            UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse]) {
                self.messagesBadgeLabel?.superview?.alpha = 0.6
            }
        } else {
            messagesBadgeLabel?.superview?.layer.removeAllAnimations()
            messagesBadgeLabel?.superview?.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func assignmentButtonTapped(_ sender: UIButton) {
        guard let assignmentId = sender.accessibilityIdentifier else { return }
        
        let dialogVC = DialogViewController()
        dialogVC.assignmentId = assignmentId
        dialogVC.completion = { [weak self] in
            self?.startAssignment(assignmentId)
        }
        present(dialogVC, animated: true)
    }
    
    @objc private func messagesButtonTapped() {
        let messagesVC = MessagesViewController()
        navigationController?.pushViewController(messagesVC, animated: true)
    }
    
    private func startAssignment(_ assignmentId: String) {
        let gameVC = GameViewController()
        
        switch assignmentId {
        case "tutorial_basics":
            gameVC.setViewModel(GameViewModel(puzzle: .tutorialPuzzle()))
            gameVC.tutorialId = assignmentId
            
        case "random_puzzle":
            let difficulties = ["easy", "medium", "hard"]
            let randomDifficulty = difficulties.randomElement() ?? "medium"
            let gridSize = Bool.random() ? 4 : 5
            
            let randomPuzzle = PuzzleDefinition.generateRandomPuzzle(
                gridSize: gridSize,
                difficulty: randomDifficulty,
                positiveMagnets: randomDifficulty == "easy" ? 2 : 3,
                negativeMagnets: randomDifficulty == "easy" ? 2 : 3
            )
            gameVC.setViewModel(GameViewModel(puzzle: randomPuzzle))
            
        default:
            return
        }
        
        gameVC.isLaunchedFromDashboard = true
        navigationController?.pushViewController(gameVC, animated: true)
    }
}

// MARK: - Assignment Model
private struct Assignment: Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let type: AssignmentType
    let isLocked: Bool
    
    enum AssignmentType {
        case tutorial, random, campaign
    }
    
    var iconColor: UIColor {
        switch type {
        case .tutorial:
            return .systemGreen
        case .random:
            return isLocked ? .systemGray : .systemBlue
        case .campaign:
            return isLocked ? .systemGray : .systemPurple
        }
    }
}
