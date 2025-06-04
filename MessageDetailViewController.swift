//
//  MessageDetailViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessageDetailViewController: UIViewController {
    
    // MARK: - Properties
    var message: Message?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let headerView = TerminalContainerView()
    private let messageBodyView = TerminalContainerView()
    
    private let senderLabel = TerminalLabel()
    private let subjectLabel = TerminalLabel()
    private let dateLabel = TerminalLabel()
    private let bodyTextView = UITextView()
    private let securityBadge = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupUI()
        populateMessage()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "MESSAGE DETAILS"
        TerminalTheme.styleNavigationBar(navigationController?.navigationBar)
        
        // Add action buttons
        let replyButton = UIBarButtonItem(
            image: UIImage(systemName: "arrowshape.turn.up.left.fill"),
            style: .plain,
            target: self,
            action: #selector(replyToMessage)
        )
        replyButton.tintColor = TerminalTheme.Colors.primaryGreen
        
        let archiveButton = UIBarButtonItem(
            image: UIImage(systemName: "archivebox.fill"),
            style: .plain,
            target: self,
            action: #selector(archiveMessage)
        )
        archiveButton.tintColor = TerminalTheme.Colors.primaryGreen
        
        navigationItem.rightBarButtonItems = [replyButton, archiveButton]
    }
    
    private func setupUI() {
        // Apply terminal theme
        TerminalTheme.applyBackground(to: self)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        
        // Header and body views
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(headerView)
        
        messageBodyView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(messageBodyView)
        
        // Setup header content
        setupHeaderContent()
        
        // Setup body content
        setupBodyContent()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 15),
            headerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 15),
            headerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -15),
            
            messageBodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 15),
            messageBodyView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 15),
            messageBodyView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -15),
            messageBodyView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -15)
        ])
    }
    
    private func setupHeaderContent() {
        // Sender icon
        let senderIcon = setupSenderIcon()
        headerView.addSubview(senderIcon)
        
        // Sender label
        senderLabel.style = .body
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(senderLabel)
        
        // Subject label
        subjectLabel.style = .heading
        subjectLabel.numberOfLines = 0
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subjectLabel)
        
        // Date label
        dateLabel.style = .terminal
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dateLabel)
        
        // Security badge
        setupSecurityBadge()
        headerView.addSubview(securityBadge)
        
        // Constraints
        NSLayoutConstraint.activate([
            senderIcon.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            senderIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            senderIcon.widthAnchor.constraint(equalToConstant: 32),
            senderIcon.heightAnchor.constraint(equalToConstant: 32),
            
            securityBadge.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            securityBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            securityBadge.heightAnchor.constraint(equalToConstant: 20),
            securityBadge.widthAnchor.constraint(equalToConstant: 80),
            
            senderLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            senderLabel.leadingAnchor.constraint(equalTo: senderIcon.trailingAnchor, constant: 12),
            senderLabel.trailingAnchor.constraint(equalTo: securityBadge.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: securityBadge.bottomAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            
            subjectLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 12),
            subjectLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            subjectLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            subjectLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -15)
        ])
    }
    
    private func setupBodyContent() {
        // Terminal prompt
        let promptView = createTerminalPromptView()
        messageBodyView.addSubview(promptView)
        
        // Message body text
        bodyTextView.font = TerminalTheme.Fonts.monospaced(size: 15)
        bodyTextView.textColor = TerminalTheme.Colors.textWhite
        bodyTextView.backgroundColor = .clear
        bodyTextView.isEditable = false
        bodyTextView.isSelectable = true
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        messageBodyView.addSubview(bodyTextView)
        
        // Attachment view (if present)
        let attachmentView = createAttachmentView()
        messageBodyView.addSubview(attachmentView)
        
        // Constraints
        NSLayoutConstraint.activate([
            promptView.topAnchor.constraint(equalTo: messageBodyView.topAnchor, constant: 15),
            promptView.leadingAnchor.constraint(equalTo: messageBodyView.leadingAnchor, constant: 15),
            promptView.trailingAnchor.constraint(equalTo: messageBodyView.trailingAnchor, constant: -15),
            promptView.heightAnchor.constraint(equalToConstant: 20),
            
            bodyTextView.topAnchor.constraint(equalTo: promptView.bottomAnchor, constant: 8),
            bodyTextView.leadingAnchor.constraint(equalTo: messageBodyView.leadingAnchor, constant: 15),
            bodyTextView.trailingAnchor.constraint(equalTo: messageBodyView.trailingAnchor, constant: -15),
            bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            attachmentView.topAnchor.constraint(equalTo: bodyTextView.bottomAnchor, constant: 15),
            attachmentView.leadingAnchor.constraint(equalTo: messageBodyView.leadingAnchor, constant: 15),
            attachmentView.trailingAnchor.constraint(equalTo: messageBodyView.trailingAnchor, constant: -15),
            attachmentView.bottomAnchor.constraint(equalTo: messageBodyView.bottomAnchor, constant: -15)
        ])
    }
    
    private func setupSenderIcon() -> UIImageView {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set icon based on sender
        if let sender = message?.sender {
            switch sender {
            case "HR Department":
                iconView.image = UIImage(systemName: "person.text.rectangle.fill")
                iconView.tintColor = .systemPink
            case "IT Support":
                iconView.image = UIImage(systemName: "laptopcomputer")
                iconView.tintColor = .systemBlue
            case "Dr. Morgan":
                iconView.image = UIImage(systemName: "stethoscope")
                iconView.tintColor = .systemTeal
            case "Supervisor Chen":
                iconView.image = UIImage(systemName: "person.badge.shield.checkmark.fill")
                iconView.tintColor = .systemPurple
            default:
                iconView.image = UIImage(systemName: "envelope.fill")
                iconView.tintColor = .systemOrange
            }
        }
        
        return iconView
    }
    
    private func setupSecurityBadge() {
        securityBadge.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.2)
        securityBadge.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        securityBadge.layer.borderWidth = 1
        securityBadge.layer.cornerRadius = 4
        securityBadge.translatesAutoresizingMaskIntoConstraints = false
        
        let securityLabel = TerminalLabel()
        securityLabel.text = getPriorityText()
        securityLabel.style = .caption
        securityLabel.font = TerminalTheme.Fonts.monospaced(size: 10, weight: .bold)
        securityLabel.textAlignment = .center
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityBadge.addSubview(securityLabel)
        
        NSLayoutConstraint.activate([
            securityLabel.centerXAnchor.constraint(equalTo: securityBadge.centerXAnchor),
            securityLabel.centerYAnchor.constraint(equalTo: securityBadge.centerYAnchor)
        ])
    }
    
    private func getPriorityText() -> String {
        switch message?.priority {
        case .urgent:
            return "URGENT"
        case .high:
            return "HIGH"
        case .normal:
            return "INTERNAL"
        case .low:
            return "FYI"
        default:
            return "INTERNAL"
        }
    }
    
    private func createTerminalPromptView() -> UIView {
        let promptView = UIView()
        promptView.translatesAutoresizingMaskIntoConstraints = false
        
        let promptLabel = TerminalLabel()
        promptLabel.style = .terminal
        promptLabel.text = "message-system> message_content follows:"
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        promptView.addSubview(promptLabel)
        
        NSLayoutConstraint.activate([
            promptLabel.topAnchor.constraint(equalTo: promptView.topAnchor),
            promptLabel.leadingAnchor.constraint(equalTo: promptView.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: promptView.trailingAnchor),
            promptLabel.bottomAnchor.constraint(equalTo: promptView.bottomAnchor)
        ])
        
        return promptView
    }
    
    private func createAttachmentView() -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Only show if there's an attachment
        guard let attachment = message?.attachment else {
            containerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            return containerView
        }
        
        let attachmentButton = TerminalButton()
        attachmentButton.style = .secondary
        attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.addTarget(self, action: #selector(viewAttachment), for: .touchUpInside)
        containerView.addSubview(attachmentButton)
        
        // Attachment icon
        let iconView = UIImageView()
        iconView.tintColor = TerminalTheme.Colors.primaryGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.addSubview(iconView)
        
        // Attachment label
        let label = TerminalLabel()
        label.style = .body
        label.text = attachment.title
        label.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.addSubview(label)
        
        // Set icon based on type
        switch attachment.type {
        case .document:
            iconView.image = UIImage(systemName: "doc.text.fill")
        case .hint:
            iconView.image = UIImage(systemName: "lightbulb.fill")
        case .schematic:
            iconView.image = UIImage(systemName: "square.grid.3x3.fill")
        case .image:
            iconView.image = UIImage(systemName: "photo.fill")
        }
        
        NSLayoutConstraint.activate([
            attachmentButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            attachmentButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            attachmentButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            attachmentButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            attachmentButton.heightAnchor.constraint(equalToConstant: 50),
            
            iconView.leadingAnchor.constraint(equalTo: attachmentButton.leadingAnchor, constant: 15),
            iconView.centerYAnchor.constraint(equalTo: attachmentButton.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: attachmentButton.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: -15)
        ])
        
        return containerView
    }
    
    // MARK: - Data Population
    private func populateMessage() {
        guard let message = message else { return }
        
        senderLabel.text = message.sender
        subjectLabel.text = message.subject
        bodyTextView.text = message.body
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy | HH:mm"
        dateLabel.text = formatter.string(from: message.timestamp)
    }
    
    // MARK: - Actions
    @objc private func viewAttachment() {
        guard let attachment = message?.attachment else { return }
        
        let alert = UIAlertController(
            title: attachment.title,
            message: attachment.content,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func replyToMessage() {
        showTypingAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showNotification(
                message: "REPLY FUNCTION RESTRICTED\nField specialists are not authorized to send messages.",
                type: .warning
            )
        }
    }
    
    @objc private func archiveMessage() {
        showTypingAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showNotification(message: "MESSAGE ARCHIVED", type: .success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - UI Feedback
    private func showTypingAnimation() {
        let loadingView = UIView()
        loadingView.tag = 8888
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView.layer.cornerRadius = 8
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        let loadingLabel = TerminalLabel()
        loadingLabel.style = .terminal
        loadingLabel.text = "Processing request..."
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        let cursorLabel = UILabel()
        cursorLabel.text = "_"
        cursorLabel.font = TerminalTheme.Fonts.monospaced(size: 14)
        cursorLabel.textColor = TerminalTheme.Colors.primaryGreen
        cursorLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(cursorLabel)
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse]) {
            cursorLabel.alpha = 0
        }
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 220),
            loadingView.heightAnchor.constraint(equalToConstant: 40),
            
            loadingLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 15),
            
            cursorLabel.leadingAnchor.constraint(equalTo: loadingLabel.trailingAnchor, constant: 2),
            cursorLabel.centerYAnchor.constraint(equalTo: loadingLabel.centerYAnchor)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingView.removeFromSuperview()
        }
    }
    
    private func showNotification(message: String, type: NotificationType) {
        let notificationView = TerminalContainerView()
        notificationView.tag = 7777
        notificationView.alpha = 0
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        
        // Style based on type
        switch type {
        case .success:
            notificationView.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        case .warning:
            notificationView.layer.borderColor = UIColor.systemOrange.cgColor
        case .error:
            notificationView.layer.borderColor = UIColor.systemRed.cgColor
        }
        
        view.addSubview(notificationView)
        
        let notificationLabel = TerminalLabel()
        notificationLabel.style = type == .success ? .terminal : .body
        notificationLabel.text = message
        notificationLabel.textAlignment = .center
        notificationLabel.numberOfLines = 0
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationView.addSubview(notificationLabel)
        
        NSLayoutConstraint.activate([
            notificationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notificationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            notificationView.widthAnchor.constraint(equalToConstant: 300),
            notificationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            notificationLabel.topAnchor.constraint(equalTo: notificationView.topAnchor, constant: 15),
            notificationLabel.leadingAnchor.constraint(equalTo: notificationView.leadingAnchor, constant: 15),
            notificationLabel.trailingAnchor.constraint(equalTo: notificationView.trailingAnchor, constant: -15),
            notificationLabel.bottomAnchor.constraint(equalTo: notificationView.bottomAnchor, constant: -15)
        ])
        
        UIView.animate(withDuration: 0.3) {
            notificationView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                notificationView.alpha = 0
            }) { _ in
                notificationView.removeFromSuperview()
            }
        }
    }
    
    private enum NotificationType {
        case success, warning, error
    }
}
