//
//  MessageDetailViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessageDetailViewController: UIViewController {
    var message: (sender: String, subject: String, preview: String)?
    
    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let headerView = UIView()
    private let messageBodyView = UIView()
    private let backgroundView = UIView()
    
    // UI elements
    private let senderLabel = UILabel()
    private let subjectLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyTextView = UITextView()
    private let securityBadge = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupBackground()
        setupUI()
        populateMessage()
    }
    
    private func setupNavigationBar() {
        title = "MESSAGE DETAILS"
        navigationController?.navigationBar.tintColor = .green
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        ]
        
        // Add reply button
        let replyButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left.fill"), style: .plain, target: self, action: #selector(replyToMessage))
        replyButton.tintColor = .green
        
        // Add archive button
        let archiveButton = UIBarButtonItem(image: UIImage(systemName: "archivebox.fill"), style: .plain, target: self, action: #selector(archiveMessage))
        archiveButton.tintColor = .green
        
        navigationItem.rightBarButtonItems = [replyButton, archiveButton]
    }
    
    private func setupBackground() {
        view.backgroundColor = .black
        
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
    
    private func setupUI() {
        // Scroll view for content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        
        // Header view
        headerView.backgroundColor = UIColor.black
        headerView.layer.borderColor = UIColor.green.withAlphaComponent(0.3).cgColor
        headerView.layer.borderWidth = 1
        headerView.layer.cornerRadius = 8
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(headerView)
        
        // Message body view
        messageBodyView.backgroundColor = UIColor.black
        messageBodyView.layer.borderColor = UIColor.green.withAlphaComponent(0.3).cgColor
        messageBodyView.layer.borderWidth = 1
        messageBodyView.layer.cornerRadius = 8
        messageBodyView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(messageBodyView)
        
        // Sender icon
        let senderIcon = setupSenderIcon()
        headerView.addSubview(senderIcon)
        
        // Sender label
        senderLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        senderLabel.textColor = .white
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(senderLabel)
        
        // Subject label
        subjectLabel.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        subjectLabel.textColor = .white
        subjectLabel.numberOfLines = 0
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subjectLabel)
        
        // Date label
        dateLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = UIColor.green
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dateLabel)
        
        // Security badge
        securityBadge.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        securityBadge.layer.borderColor = UIColor.green.cgColor
        securityBadge.layer.borderWidth = 1
        securityBadge.layer.cornerRadius = 4
        securityBadge.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(securityBadge)
        
        let securityLabel = UILabel()
        securityLabel.text = "INTERNAL"
        securityLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        securityLabel.textColor = .green
        securityLabel.textAlignment = .center
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityBadge.addSubview(securityLabel)
        
        // Message body
        bodyTextView.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        bodyTextView.textColor = .white
        bodyTextView.backgroundColor = .clear
        bodyTextView.isEditable = false
        bodyTextView.isSelectable = true
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        messageBodyView.addSubview(bodyTextView)
        
        // Add terminal prompt to message body
        let promptView = createTerminalPromptView()
        messageBodyView.addSubview(promptView)
        
        // Set constraints
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
            
            senderIcon.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            senderIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            senderIcon.widthAnchor.constraint(equalToConstant: 32),
            senderIcon.heightAnchor.constraint(equalToConstant: 32),
            
            securityBadge.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            securityBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            securityBadge.heightAnchor.constraint(equalToConstant: 20),
            securityBadge.widthAnchor.constraint(equalToConstant: 80),
            
            securityLabel.centerXAnchor.constraint(equalTo: securityBadge.centerXAnchor),
            securityLabel.centerYAnchor.constraint(equalTo: securityBadge.centerYAnchor),
            
            senderLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            senderLabel.leadingAnchor.constraint(equalTo: senderIcon.trailingAnchor, constant: 12),
            senderLabel.trailingAnchor.constraint(equalTo: securityBadge.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: securityBadge.bottomAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            
            subjectLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 12),
            subjectLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            subjectLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            subjectLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -15),
            
            messageBodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 15),
            messageBodyView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 15),
            messageBodyView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -15),
            messageBodyView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -15),
            
            promptView.topAnchor.constraint(equalTo: messageBodyView.topAnchor, constant: 15),
            promptView.leadingAnchor.constraint(equalTo: messageBodyView.leadingAnchor, constant: 15),
            promptView.trailingAnchor.constraint(equalTo: messageBodyView.trailingAnchor, constant: -15),
            promptView.heightAnchor.constraint(equalToConstant: 20),
            
            bodyTextView.topAnchor.constraint(equalTo: promptView.bottomAnchor, constant: 8),
            bodyTextView.leadingAnchor.constraint(equalTo: messageBodyView.leadingAnchor, constant: 15),
            bodyTextView.trailingAnchor.constraint(equalTo: messageBodyView.trailingAnchor, constant: -15),
            bodyTextView.bottomAnchor.constraint(equalTo: messageBodyView.bottomAnchor, constant: -15),
            bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant:500)
        ])
    }
    
    private func setupSenderIcon() -> UIImageView {
        let iconView = UIImageView()
        
        // Default icon
        var iconImage = UIImage(systemName: "envelope.fill")
        var iconColor: UIColor = .systemOrange
        
        // Customize based on sender
        if let sender = message?.sender {
            switch sender {
            case "HR Department":
                iconImage = UIImage(systemName: "person.text.rectangle.fill")
                iconColor = .systemPink
            case "IT Support":
                iconImage = UIImage(systemName: "laptopcomputer")
                iconColor = .systemBlue
            case "Dr. Morgan":
                iconImage = UIImage(systemName: "stethoscope")
                iconColor = .systemTeal
            default:
                break
            }
        }
        
        iconView.image = iconImage
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        return iconView
    }
    
    private func createTerminalPromptView() -> UIView {
        let promptView = UIView()
        promptView.translatesAutoresizingMaskIntoConstraints = false
        
        let promptLabel = UILabel()
        promptLabel.text = "message-system> message_content follows:"
        promptLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        promptLabel.textColor = .green
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
    
    private func populateMessage() {
        guard let message = message else { return }
        
        senderLabel.text = message.sender
        subjectLabel.text = message.subject
        dateLabel.text = "04.05.2025 | 08:42"
        
        // Generate a longer message content based on the preview
        bodyTextView.text = generateMessageContent(for: message.subject)
    }
    
    private func generateMessageContent(for subject: String) -> String {
        switch subject {
        case "Welcome to NeutraTech":
            return """
            Dear New Employee,
            
            We're pleased to have you join our team of Field Harmonization Specialists. Your role is vital to our mission of managing energy anomalies.
            
            During your orientation, you'll learn to use our proprietary stabilization and suppression tools to achieve target energy values. These tools are the result of decades of research and are critical to our operations.
            
            Please report to Dr. Morgan for your orientation training as soon as possible. Your access badge has been activated and will grant you entry to Level 1 facilities.
            
            IMPORTANT: All field activities are strictly classified. Do not discuss your work with anyone outside the company, including family members. This is per corporate security protocol NT-7842.
            
            Should you have any questions, please direct them to your supervisor.
            
            Regards,
            HR Department
            NeutraTech Corporation
            "Harmonizing the Future"
            """
            
        case "Employee Credentials":
            return """
            NOTIFICATION: SYSTEM ACCESS GRANTED
            
            Your system access has been provisioned with Level 1 clearance. This grants you access to basic field harmonization tools and standard anomaly data.
            
            Your employee ID is NT-7842. Please memorize this number as it will be required for all facility access.
            
            LOGIN CREDENTIALS:
            Username: fieldspecialist
            Password: [REDACTED - retrieve from secure terminal]
            
            Equipment allocation has been approved. Report to Supply (Sub-level 2) to receive your standard-issue field kit.
            
            Note that certain areas of our facility require higher clearance levels, which you may obtain after successful completion of your initial assignments.
            
            REMINDER: Always wear your badge while on premises.
            
            -- IT Support
            """
            
        case "Training Schedule":
            return """
            Field Specialist,
            
            I've scheduled your orientation for today. Please be prompt as we have much to cover.
            
            You'll be introduced to our stabilization and suppression technology, as well as the basics of field harmonization. Don't worry if it seems complex at first - most new employees take some time to adjust to our unique procedures.
            
            Our training lab has been prepared with a simplified containment chamber where you can practice without any risk. We'll start with basic field manipulation exercises before moving on to more complex anomaly management.
            
            The focus will be on practical applications rather than theoretical background. Corporate policy restricts certain information to need-to-know basis for Level 1 personnel.
            
            I'm looking forward to working with you and answering any questions you might have about your role here at NeutraTech.
            
            Best regards,
            Dr. Morgan
            Field Training Division
            
            P.S. Please refrain from bringing any electronic devices to the training area.
            """
            
        default:
            return "We'll provide more information soon. Thank you for your attention to this matter."
        }
    }
    
    @objc private func replyToMessage() {
        // Show typing animation
        showTypingAnimation()
        
        // Show reply notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showNotification(message: "REPLY FUNCTION RESTRICTED\nField specialists are not authorized to send messages.")
        }
    }
    
    @objc private func archiveMessage() {
        // Show typing animation
        showTypingAnimation()
        
        // Show archive notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNotification(message: "MESSAGE ARCHIVED")
            
            // Go back to messages list after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showTypingAnimation() {
        // Create and add loading label
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView.layer.cornerRadius = 8
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        let loadingLabel = UILabel()
        loadingLabel.text = "Processing request..."
        loadingLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        loadingLabel.textColor = .green
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        // Add blinking cursor
        let cursorLabel = UILabel()
        cursorLabel.text = "_"
        cursorLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        cursorLabel.textColor = .green
        cursorLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(cursorLabel)
        
        // Animate cursor
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse], animations: {
            cursorLabel.alpha = 0
        })
        
        // Set constraints
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
        
        // Remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingView.removeFromSuperview()
        }
    }
    
    private func showNotification(message: String) {
        // Create notification view
        let notificationView = UIView()
        notificationView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        notificationView.layer.borderColor = UIColor.green.cgColor
        notificationView.layer.borderWidth = 1
        notificationView.layer.cornerRadius = 8
        notificationView.alpha = 0
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notificationView)
        
        // Notification label
        let notificationLabel = UILabel()
        notificationLabel.text = message
        notificationLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        notificationLabel.textColor = .green
        notificationLabel.textAlignment = .center
        notificationLabel.numberOfLines = 0
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationView.addSubview(notificationLabel)
        
        // Set constraints
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
        
        // Animate appearance
        UIView.animate(withDuration: 0.3) {
            notificationView.alpha = 1
        }
        
        // Remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                notificationView.alpha = 0
            }) { _ in
                notificationView.removeFromSuperview()
            }
        }
    }
}
