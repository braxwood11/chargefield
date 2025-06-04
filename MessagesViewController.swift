//
//  MessagesViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessagesViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private var messages: [Message] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupUI()
        loadMessages()
        
        // Listen for new messages
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewMessage),
            name: .newMessageReceived,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMessages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "COMPANY MESSAGES"
        TerminalTheme.styleNavigationBar(navigationController?.navigationBar)
        
        // Add refresh button
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshMessages)
        )
        refreshButton.tintColor = TerminalTheme.Colors.primaryGreen
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupUI() {
        // Apply terminal theme
        TerminalTheme.applyBackground(to: self)
        
        // Create header
        let headerView = createHeaderView()
        tableView.tableHeaderView = headerView
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "messageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func createHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 90))
        headerView.backgroundColor = .clear
        
        // Status container
        let statusContainer = TerminalContainerView()
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(statusContainer)
        
        // Terminal prompt
        let promptLabel = TerminalLabel()
        promptLabel.style = .terminal
        promptLabel.text = "system> communications_channel_initialized"
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(promptLabel)
        
        // Status message
        let statusLabel = TerminalLabel()
        statusLabel.style = .body
        statusLabel.text = "Loading messages..."
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        
        // Store reference to update later
        statusLabel.tag = 1001
        
        // Set constraints
        NSLayoutConstraint.activate([
            statusContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            statusContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            statusContainer.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15),
            statusContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -15),
            
            promptLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 12),
            promptLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 15),
            promptLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -15),
            
            statusLabel.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 15),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -15),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: statusContainer.bottomAnchor, constant: -12)
        ])
        
        return headerView
    }
    
    // MARK: - Data Loading
    private func loadMessages() {
        messages = MessageManager.shared.getAllMessages()
        tableView.reloadData()
        updateHeaderStatus()
    }
    
    private func updateHeaderStatus() {
        if let statusLabel = tableView.tableHeaderView?.viewWithTag(1001) as? UILabel {
            let unreadCount = messages.filter { !$0.isRead }.count
            statusLabel.text = "Displaying \(messages.count) messages (\(unreadCount) unread)"
        }
    }
    
    // MARK: - Actions
    @objc private func refreshMessages() {
        // Animate refresh button
        if let button = navigationItem.rightBarButtonItem?.customView {
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.fromValue = 0
            rotation.toValue = 2 * Double.pi
            rotation.duration = 1
            button.layer.add(rotation, forKey: "rotationAnimation")
        }
        
        // Show loading state
        showLoadingOverlay()
        
        // Simulate refresh delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.hideLoadingOverlay()
            self?.loadMessages()
            
            // Check for new messages
            MessageManager.shared.checkTriggeredMessages()
        }
    }
    
    @objc private func handleNewMessage(_ notification: Notification) {
        loadMessages()
        
        // Optionally scroll to top to show new message
        if !messages.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - Loading Overlay
    private func showLoadingOverlay() {
        let loadingView = UIView()
        loadingView.tag = 9999
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        let loadingLabel = TerminalLabel()
        loadingLabel.style = .terminal
        loadingLabel.text = "Updating message queue..."
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
        
        loadingView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            loadingView.alpha = 1
        }
    }
    
    private func hideLoadingOverlay() {
        if let loadingView = view.viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                loadingView.alpha = 0
            }) { _ in
                loadingView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableView DataSource & Delegate
extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        cell.configure(with: message)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let message = messages[indexPath.row]
        
        // Mark as read
        MessageManager.shared.markAsRead(message.id)
        
        // Animate cell selection
        if let cell = tableView.cellForRow(at: indexPath) as? MessageCell {
            UIView.animate(withDuration: 0.1, animations: {
                cell.contentView.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.2)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.contentView.backgroundColor = .clear
                }
            }
        }
        
        // Navigate to detail view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let detailVC = MessageDetailViewController()
            detailVC.message = message
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - Message Cell
class MessageCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let containerView = TerminalContainerView()
    private let senderLabel = TerminalLabel()
    private let subjectLabel = TerminalLabel()
    private let previewLabel = TerminalLabel()
    private let dateLabel = TerminalLabel()
    private let unreadIndicator = UIView()
    private let iconView = UIImageView()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Message icon
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
        
        // Sender label
        senderLabel.style = .body
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(senderLabel)
        
        // Subject label
        subjectLabel.style = .body
        subjectLabel.font = TerminalTheme.Fonts.monospaced(size: 13, weight: .semibold)
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subjectLabel)
        
        // Preview label
        previewLabel.style = .caption
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(previewLabel)
        
        // Date label
        dateLabel.style = .terminal
        dateLabel.font = TerminalTheme.Fonts.monospaced(size: 10, weight: .regular)
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        // Unread indicator
        unreadIndicator.backgroundColor = .systemOrange
        unreadIndicator.layer.cornerRadius = 4
        unreadIndicator.translatesAutoresizingMaskIntoConstraints = false
        unreadIndicator.isHidden = true
        containerView.addSubview(unreadIndicator)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            senderLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            senderLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            senderLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            dateLabel.widthAnchor.constraint(equalToConstant: 80),
            
            subjectLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            subjectLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            subjectLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            previewLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 4),
            previewLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            unreadIndicator.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            unreadIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 8),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    // MARK: - Configuration
    func configure(with message: Message) {
        senderLabel.text = message.sender
        subjectLabel.text = message.subject
        previewLabel.text = String(message.body.prefix(50)) + "..."
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        dateLabel.text = formatter.string(from: message.timestamp)
        
        // Show unread indicator
        unreadIndicator.isHidden = message.isRead
        
        // Configure icon based on sender
        configureIcon(for: message.sender)
        
        // Style based on read status and priority
        if !message.isRead {
            containerView.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
            containerView.layer.borderWidth = 1.5
            
            // Add pulsing animation to unread indicator
            UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse]) {
                self.unreadIndicator.alpha = 0.6
            }
            
            senderLabel.font = TerminalTheme.Fonts.monospaced(size: 14, weight: .heavy)
            subjectLabel.font = TerminalTheme.Fonts.monospaced(size: 13, weight: .bold)
        } else {
            containerView.layer.borderColor = TerminalTheme.Colors.borderGreen.withAlphaComponent(0.3).cgColor
            containerView.layer.borderWidth = 1
            unreadIndicator.layer.removeAllAnimations()
            
            senderLabel.font = TerminalTheme.Fonts.monospaced(size: 14, weight: .bold)
            subjectLabel.font = TerminalTheme.Fonts.monospaced(size: 13, weight: .semibold)
        }
    }
    
    private func configureIcon(for sender: String) {
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
}
