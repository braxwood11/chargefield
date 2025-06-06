//
//  Enhanced DashboardViewController.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import UIKit

// MARK: - Directory System
enum DirectoryPath: String, CaseIterable {
    case root = "~"
    case training = "~/training"
    case assignments = "~/assignments"
    case special = "~/special"
    case archived = "~/archived"
    
    // Hidden directories (discoverable through clues)
    case classified = "~/classified"
    case project_alpha = "~/project_alpha"
    case maintenance = "~/maintenance"
    case logs = "~/logs"
    
    var displayName: String {
        switch self {
        case .root: return "Home"
        case .training: return "Training Programs"
        case .assignments: return "Field Assignments"
        case .special: return "Special Operations"
        case .archived: return "Completed Missions"
        case .classified: return "Classified Files"
        case .project_alpha: return "Project Alpha"
        case .maintenance: return "System Maintenance"
        case .logs: return "System Logs"
        }
    }
    
    var isHidden: Bool {
        switch self {
        case .classified, .project_alpha, .maintenance, .logs:
            return true
        default:
            return false
        }
    }
    
    var subdirectories: [DirectoryPath] {
        switch self {
        case .root: return [.training, .assignments, .special, .archived]
        default: return []
        }
    }
}

// MARK: - Terminal Command System
enum TerminalCommand {
    case list(directory: DirectoryPath?)
    case changeDirectory(DirectoryPath)
    case help
    case clear
    case back
    case unknown(String)
    
    static func parse(_ input: String) -> TerminalCommand {
        let components = input.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        guard let command = components.first?.lowercased() else {
            return .unknown(input)
        }
        
        switch command {
        case "ls", "list":
            return .list(directory: nil)
        case "cd":
            if components.count > 1 {
                let path = components[1]
                if let directory = DirectoryPath(rawValue: path) {
                    return .changeDirectory(directory)
                }
                // Handle relative paths
                switch path {
                case "training": return .changeDirectory(.training)
                case "assignments": return .changeDirectory(.assignments)
                case "special": return .changeDirectory(.special)
                case "archived": return .changeDirectory(.archived)
                // Hidden directories
                case "classified": return .changeDirectory(.classified)
                case "project_alpha": return .changeDirectory(.project_alpha)
                case "maintenance": return .changeDirectory(.maintenance)
                case "logs": return .changeDirectory(.logs)
                case "..", "back": return .back
                case "~", "home": return .changeDirectory(.root)
                default: return .unknown(input)
                }
            }
            return .unknown(input)
        case "help", "?":
            return .help
        case "clear":
            return .clear
        case "back", "..":
            return .back
        default:
            return .unknown(input)
        }
    }
}

// MARK: - Enhanced Dashboard View Controller
class DashboardViewController: UIViewController {
    
    // MARK: - Properties
    private let progress = GameProgressManager.shared
    private var assignmentButtons: [UIButton] = []
    private var currentDirectory: DirectoryPath = .root
    private var terminalHistory: [String] = []
    
    // MARK: - UI Elements
    private let titleView = UIView()
    private let terminalPromptView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let commandInputView = UIView()
    private let commandTextField = UITextField()
    private let messagesButton = UIButton()
    private var messagesBadgeLabel: UILabel?
    
    // Terminal elements
    private let currentPathLabel = TerminalLabel()
    private let directoryContentsLabel = TerminalLabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Employee Dashboard"
        setupUI()
        updateCurrentDirectory()
        
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
        updateCurrentDirectory()
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
        
        // Setup main components
        setupHeader()
        setupTerminalInterface()
        setupCommandInput()
        setupFixedMessagesButton()
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
        
        // Connection status
        let statusView = createStatusIndicator()
        view.addSubview(statusView)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.3)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleView.heightAnchor.constraint(equalToConstant: 44),
            
            promptLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 20),
            promptLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 5),
            titleLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            statusView.widthAnchor.constraint(equalToConstant: 107),
            statusView.heightAnchor.constraint(equalToConstant: 24),
            
            separatorLine.topAnchor.constraint(equalTo: titleView.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupTerminalInterface() {
        // Terminal prompt view (shows current directory)
        terminalPromptView.translatesAutoresizingMaskIntoConstraints = false
        TerminalTheme.styleContainer(terminalPromptView, borderOpacity: 0.5)
        view.addSubview(terminalPromptView)
        
        // Current path label
        currentPathLabel.style = .terminal
        currentPathLabel.translatesAutoresizingMaskIntoConstraints = false
        terminalPromptView.addSubview(currentPathLabel)
        
        // Scroll view for content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Directory contents
        directoryContentsLabel.style = .body
        directoryContentsLabel.numberOfLines = 0
        directoryContentsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(directoryContentsLabel)
        
        NSLayoutConstraint.activate([
            terminalPromptView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 20),
            terminalPromptView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            terminalPromptView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            terminalPromptView.heightAnchor.constraint(equalToConstant: 40),
            
            currentPathLabel.centerYAnchor.constraint(equalTo: terminalPromptView.centerYAnchor),
            currentPathLabel.leadingAnchor.constraint(equalTo: terminalPromptView.leadingAnchor, constant: 15),
            currentPathLabel.trailingAnchor.constraint(equalTo: terminalPromptView.trailingAnchor, constant: -15),
            
            scrollView.topAnchor.constraint(equalTo: terminalPromptView.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            directoryContentsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            directoryContentsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            directoryContentsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            directoryContentsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupCommandInput() {
        commandInputView.translatesAutoresizingMaskIntoConstraints = false
        TerminalTheme.styleContainer(commandInputView)
        view.addSubview(commandInputView)
        
        // Add tap gesture to entire input view to focus text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusCommandInput))
        commandInputView.addGestureRecognizer(tapGesture)
        
        // Command prompt
        let promptLabel = TerminalLabel()
        promptLabel.style = .terminal
        promptLabel.text = "$"
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        commandInputView.addSubview(promptLabel)
        
        // Text field
        commandTextField.backgroundColor = .clear
        commandTextField.textColor = TerminalTheme.Colors.primaryGreen
        commandTextField.font = TerminalTheme.Fonts.monospaced(size: 14)
        commandTextField.textAlignment = .left
        commandTextField.contentVerticalAlignment = .center
        commandTextField.borderStyle = .none
        commandTextField.autocorrectionType = .no
        commandTextField.autocapitalizationType = .none
        
        // Make placeholder more visible
        let placeholderText = "Type 'help' for commands"
        commandTextField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                NSAttributedString.Key.foregroundColor: TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.6),
                NSAttributedString.Key.font: TerminalTheme.Fonts.monospaced(size: 14)
            ]
        )
        
        commandTextField.delegate = self
        commandTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure no internal padding
        commandTextField.leftView = nil
        commandTextField.rightView = nil
        commandTextField.clearButtonMode = .never
        
        commandInputView.addSubview(commandTextField)
        
        NSLayoutConstraint.activate([
            commandInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commandInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commandInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            commandInputView.heightAnchor.constraint(equalToConstant: 50),
            
            promptLabel.leadingAnchor.constraint(equalTo: commandInputView.leadingAnchor, constant: 15),
            promptLabel.centerYAnchor.constraint(equalTo: commandInputView.centerYAnchor),
            
            commandTextField.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 5),
            commandTextField.trailingAnchor.constraint(equalTo: commandInputView.trailingAnchor, constant: -15),
            commandTextField.topAnchor.constraint(equalTo: commandInputView.topAnchor, constant: 5),
            commandTextField.bottomAnchor.constraint(equalTo: commandInputView.bottomAnchor, constant: -5)
        ])
    }
    
    @objc private func focusCommandInput() {
        commandTextField.becomeFirstResponder()
    }
    
    private func setupFixedMessagesButton() {
        messagesButton.translatesAutoresizingMaskIntoConstraints = false
        messagesButton.backgroundColor = TerminalTheme.Colors.backgroundBlack
        messagesButton.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.8).cgColor
        messagesButton.layer.borderWidth = 2
        messagesButton.layer.cornerRadius = 25
        messagesButton.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        
        // Icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iconImage = UIImage(systemName: "envelope.badge.fill", withConfiguration: configuration)
        messagesButton.setImage(iconImage, for: .normal)
        messagesButton.tintColor = UIColor.systemOrange
        
        // Badge
        let badgeView = UIView()
        badgeView.backgroundColor = .red
        badgeView.layer.cornerRadius = 8
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        messagesButton.addSubview(badgeView)
        
        let badgeLabel = TerminalLabel()
        badgeLabel.text = "0"
        badgeLabel.style = .caption
        badgeLabel.textColor = .white
        badgeLabel.font = TerminalTheme.Fonts.monospaced(size: 10, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)
        
        messagesBadgeLabel = badgeLabel
        
        view.addSubview(messagesButton)
        
        NSLayoutConstraint.activate([
            messagesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messagesButton.bottomAnchor.constraint(equalTo: commandInputView.topAnchor, constant: -15),
            messagesButton.widthAnchor.constraint(equalToConstant: 50),
            messagesButton.heightAnchor.constraint(equalToConstant: 50),
            
            badgeView.topAnchor.constraint(equalTo: messagesButton.topAnchor, constant: -5),
            badgeView.trailingAnchor.constraint(equalTo: messagesButton.trailingAnchor, constant: 5),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badgeView.heightAnchor.constraint(equalToConstant: 16),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4)
        ])
        
        updateMessagesBadge()
    }
    
    // MARK: - Directory Management
    private func updateCurrentDirectory() {
        // Update path display
        currentPathLabel.text = "employee@neutratech:\(currentDirectory.rawValue)$ "
        
        // Update directory contents
        updateDirectoryContents()
    }
    
    private func updateDirectoryContents() {
        switch currentDirectory {
        case .root:
            showRootDirectory()
        case .training:
            showTrainingDirectory()
        case .assignments:
            showAssignmentsDirectory()
        case .special:
            showSpecialDirectory()
        case .archived:
            showArchivedDirectory()
        case .classified:
            showClassifiedDirectory()
        case .project_alpha:
            showProjectAlphaDirectory()
        case .maintenance:
            showMaintenanceDirectory()
        case .logs:
            showLogsDirectory()
        }
    }
    
    private func showRootDirectory() {
        var content = "Available directories:\n\n"
        
        let directories = [
            ("training/", "Training programs"),
            ("assignments/", "Active field work"),
            ("special/", "Special operations"),
            ("archived/", "Completed missions")
        ]
        
        for (name, description) in directories {
            content += "📁 \(name)\n"
            content += "   \(description)\n\n"
        }
        
        content += "Type 'cd [directory]' to navigate or 'help' for commands"
        directoryContentsLabel.text = content
        
        // Clear assignment buttons
        clearAssignmentButtons()
    }
    
    private func showTrainingDirectory() {
        directoryContentsLabel.text = "Loading training programs..."
        
        let trainingAssignments = getTrainingAssignments()
        displayAssignments(trainingAssignments, emptyMessage: "No training programs available")
    }
    
    private func showAssignmentsDirectory() {
        directoryContentsLabel.text = "Loading field assignments..."
        
        let fieldAssignments = getFieldAssignments()
        displayAssignments(fieldAssignments, emptyMessage: "No field assignments available")
    }
    
    private func showSpecialDirectory() {
        directoryContentsLabel.text = "⚠️  RESTRICTED ACCESS\n\nSpecial operations require Level 3 clearance or higher.\n\nContact your supervisor for authorization."
        clearAssignmentButtons()
    }
    
    private func showArchivedDirectory() {
        directoryContentsLabel.text = "📋 Mission Archive\n\nCompleted missions and performance reports.\n\n(Archive system under maintenance)"
        clearAssignmentButtons()
    }
    
    // MARK: - Hidden Directories (discoverable through gameplay)
    
    private func showClassifiedDirectory() {
        // First time accessing gives a hint about the true nature of work
        let content = """
        ⚠️  CLASSIFIED MATERIAL - LEVEL 4+ ONLY
        
        ACCESS GRANTED: Field Specialist NT-7842
        
        [REDACTED] Field Operations Summary:
        - Energy "anomalies" are [REDACTED]
        - Neutralization prevents [REDACTED]
        - Project codename: [REDACTED]
        
        For full documentation, access project_alpha directory.
        
        WARNING: Information contained herein is classified.
        Unauthorized disclosure is a federal offense.
        """
        
        directoryContentsLabel.text = content
        clearAssignmentButtons()
        
        // Mark that player found this directory
        UserDefaults.standard.set(true, forKey: "found_classified")
    }
    
    private func showProjectAlphaDirectory() {
        let content = """
        📂 PROJECT ALPHA - EYES ONLY
        
        Status: ACTIVE
        Classification: TOP SECRET
        
        Summary: Large-scale energy manipulation experiment.
        Cover Story: "Field harmonization" for employee morale.
        
        Reality: [DATA CORRUPTED]
        
        Recent anomalies suggest containment breach.
        Recommend immediate protocol revision.
        
        See maintenance logs for system errors.
        """
        
        directoryContentsLabel.text = content
        clearAssignmentButtons()
        
        UserDefaults.standard.set(true, forKey: "found_project_alpha")
    }
    
    private func showMaintenanceDirectory() {
        let content = """
        🔧 System Maintenance Logs
        
        [ERROR] Containment grid stability: 67%
        [WARN] Energy readings exceed normal parameters
        [ERROR] Employee monitoring system offline
        
        Recent Issues:
        - Field harmonization tools showing unexpected results
        - Employee #NT-7842 performance anomalous
        - Supervisor reports equipment "learning"
        
        Recommended Action: Full system diagnostic
        Status: PENDING APPROVAL
        """
        
        directoryContentsLabel.text = content
        clearAssignmentButtons()
        
        UserDefaults.standard.set(true, forKey: "found_maintenance")
    }
    
    private func showLogsDirectory() {
        let content = """
        📝 System Event Logs
        
        [23:47] Field stabilizer placed by NT-7842
        [23:47] WARNING: Unexpected energy cascade
        [23:48] Field suppressor placed by NT-7842  
        [23:48] ERROR: Reality distortion detected
        [23:49] Auto-correction engaged
        [23:49] Employee memory adjustment: SUCCESS
        
        Pattern Analysis:
        Employee NT-7842 consistently generates anomalous results.
        Recommend immediate evaluation.
        
        Note: Subject shows signs of resistance to standard protocols.
        """
        
        directoryContentsLabel.text = content
        clearAssignmentButtons()
        
        UserDefaults.standard.set(true, forKey: "found_logs")
    }
    
    // MARK: - Assignment Management
    private func getTrainingAssignments() -> [Assignment] {
        return [
            Assignment(
                id: "tutorial_basics",
                title: "NeutraTech Orientation #1",
                subtitle: "Required for Field Operations",
                icon: "graduationcap.fill",
                type: .tutorial,
                isLocked: false
            ),
            Assignment(
                id: "tutorial_advanced",
                title: "NeutraTech Orientation #2",
                subtitle: "Advanced Field Harmonization",
                icon: "atom",
                type: .tutorial,
                isLocked: !progress.isTutorialCompleted("tutorial_basics")
            ),
            Assignment(
                id: "tutorial_correction",
                title: "NeutraTech Orientation #3",
                subtitle: "Precision Correction Protocols",
                icon: "target",
                type: .tutorial,
                isLocked: !progress.isTutorialCompleted("tutorial_advanced")
            ),
            Assignment(
                id: "tutorial_efficiency",
                title: "NeutraTech Orientation #4",
                subtitle: "Resource Management Training",
                icon: "gearshape.fill",
                type: .tutorial,
                isLocked: !progress.isTutorialCompleted("tutorial_correction")
            )
        ]
    }
    
    private func getFieldAssignments() -> [Assignment] {
        return [
            Assignment(
                id: "random_puzzle",
                title: "Assignment #1",
                subtitle: "Field Neutralization Challenge",
                icon: "bolt.fill",
                type: .random,
                isLocked: !progress.isTutorialCompleted("tutorial_basics")
            ),
            Assignment(
                id: "advanced_assignment",
                title: "Assignment #2",
                subtitle: "Advanced Field Operations",
                icon: "lock.fill",
                type: .campaign,
                isLocked: !progress.isTutorialCompleted("tutorial_efficiency")
            )
        ]
    }
    
    private func displayAssignments(_ assignments: [Assignment], emptyMessage: String) {
        clearAssignmentButtons()
        
        guard !assignments.isEmpty else {
            directoryContentsLabel.text = emptyMessage
            return
        }
        
        // Hide the text label since we're showing buttons
        directoryContentsLabel.text = ""
        
        var previousButton: UIButton?
        let buttonHeight: CGFloat = 80
        let buttonSpacing: CGFloat = 15
        
        for assignment in assignments {
            let button = createAssignmentButton(assignment: assignment)
            contentView.addSubview(button)
            assignmentButtons.append(button)
            
            // Set constraints
            if let previous = previousButton {
                button.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: buttonSpacing).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
            }
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
            
            previousButton = button
        }
        
        // Update content size
        if let lastButton = assignmentButtons.last {
            lastButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        }
    }
    
    private func clearAssignmentButtons() {
        assignmentButtons.forEach { $0.removeFromSuperview() }
        assignmentButtons.removeAll()
    }
    
    // MARK: - UI Components (reuse existing methods)
    private func createStatusIndicator() -> UIView {
        let containerView = TerminalContainerView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let statusDot = UIView()
        statusDot.backgroundColor = TerminalTheme.Colors.primaryGreen
        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusDot)
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse]) {
            statusDot.alpha = 0.4
        }
        
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
        button.accessibilityIdentifier = assignment.id
        
        TerminalTheme.styleContainer(button)
        
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(containerView)
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconImage = UIImageView(image: UIImage(systemName: assignment.icon, withConfiguration: configuration))
        iconImage.tintColor = assignment.iconColor
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImage)
        
        let titleLabel = TerminalLabel()
        titleLabel.style = .body
        titleLabel.text = assignment.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        let subtitleLabel = TerminalLabel()
        subtitleLabel.style = .caption
        subtitleLabel.text = assignment.subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
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
        
        button.isEnabled = !assignment.isLocked
        if assignment.isLocked {
            button.alpha = 0.5
            iconImage.tintColor = .systemGray
        }
        
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
    
    // MARK: - Command Processing
    private func processCommand(_ command: String) {
        let parsedCommand = TerminalCommand.parse(command)
        terminalHistory.append("$ \(command)")
        
        switch parsedCommand {
        case .list:
            // Already handled by directory display
            break
            
        case .changeDirectory(let newDirectory):
            // Check if this is a hidden directory being accessed for the first time
            if newDirectory.isHidden {
                let foundKey = "found_\(newDirectory.rawValue.replacingOccurrences(of: "~/", with: ""))"
                let isFirstTime = !UserDefaults.standard.bool(forKey: foundKey)
                
                if isFirstTime {
                    appendToHistory("⚠️  ACCESS GRANTED: Classified directory discovered")
                }
            }
            
            currentDirectory = newDirectory
            updateCurrentDirectory()
            appendToHistory("Changed to \(newDirectory.displayName)")
            
        case .help:
            showHelpDialog()
            
        case .clear:
            terminalHistory.removeAll()
            
        case .back:
            navigateBack()
            
        case .unknown(let input):
            appendToHistory("Unknown command: '\(input)'. Type 'help' for available commands.")
        }
        
        commandTextField.text = ""
    }
    
    private func navigateBack() {
        switch currentDirectory {
        case .root:
            appendToHistory("Already at root directory")
        default:
            currentDirectory = .root
            updateCurrentDirectory()
            appendToHistory("Returned to Home")
        }
    }
    
    private func appendToHistory(_ message: String) {
        terminalHistory.append(message)
        // Could implement a terminal history view if needed
    }
    
    private func showHelpDialog() {
        // Check how many hidden directories the player has found
        let hiddenFound = [
            UserDefaults.standard.bool(forKey: "found_classified"),
            UserDefaults.standard.bool(forKey: "found_project_alpha"),
            UserDefaults.standard.bool(forKey: "found_maintenance"),
            UserDefaults.standard.bool(forKey: "found_logs")
        ].filter { $0 }.count
        
        var tipText = "Tip: Some directories may not be listed but can be accessed directly if you know their names..."
        
        if hiddenFound > 0 {
            tipText = "Hidden directories discovered: \(hiddenFound)/4\nKeep exploring to uncover the truth..."
        }
        
        let helpText = """
        Available Commands:
        
        cd [directory]  - Change directory
        ls / list       - List contents
        help / ?        - Show this help
        clear           - Clear terminal
        back / ..       - Go back to home
        
        Standard Directories:
        • training      - Training programs
        • assignments   - Field assignments
        • special       - Special operations
        • archived      - Completed missions
        
        Examples:
        cd training
        cd ~
        ls
        
        \(tipText)
        """
        
        let alert = UIAlertController(title: "Terminal Commands", message: helpText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Updates
    @objc private func updateMessagesBadge() {
        let unreadCount = MessageManager.shared.getUnreadCount()
        messagesBadgeLabel?.text = "\(unreadCount)"
        messagesBadgeLabel?.superview?.isHidden = unreadCount == 0
        
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
        case "tutorial_advanced":
            gameVC.setViewModel(GameViewModel(puzzle: .overlappingFieldsPuzzle()))
            gameVC.tutorialId = assignmentId
        case "tutorial_correction":
            gameVC.setViewModel(GameViewModel(puzzle: .correctionProtocolsPuzzle()))
            gameVC.tutorialId = assignmentId
        case "tutorial_efficiency":
            gameVC.setViewModel(GameViewModel(puzzle: .resourceManagementPuzzle()))
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

// MARK: - UITextFieldDelegate
extension DashboardViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let command = textField.text, !command.isEmpty else { return true }
        processCommand(command)
        return true
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
            return isLocked ? .systemGray : .systemGreen
        case .random:
            return isLocked ? .systemGray : .systemBlue
        case .campaign:
            return isLocked ? .systemGray : .systemPurple
        }
    }
}
