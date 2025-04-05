//
//  MessagesViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessagesViewController: UIViewController {
    private let tableView = UITableView()
    private let backgroundView = UIView()
    
    // Sample messages for prototype
    private let messages = [
        (sender: "HR Department", subject: "Welcome to NeutraTech", preview: "Please complete your orientation training...", isUnread: true),
        (sender: "IT Support", subject: "Employee Credentials", preview: "Your system access has been provisioned...", isUnread: false),
        (sender: "Dr. Morgan", subject: "Training Schedule", preview: "Looking forward to guiding you through...", isUnread: false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up navigation bar
        title = "COMPANY MESSAGES"
        setupNavigationBar()
        
        // Set up background
        view.backgroundColor = .black
        setupBackground()
        
        // Set up table view
        setupTableView()
    }
    
    private func setupNavigationBar() {
        // Style navigation bar to match terminal theme
        navigationController?.navigationBar.tintColor = .green
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        ]
        
        // Add terminal-style refresh button
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refreshMessages))
        refreshButton.tintColor = .green
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupBackground() {
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
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "messageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        // Add header
        let headerView = createHeaderView()
        tableView.tableHeaderView = headerView
        
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
        let statusContainer = UIView()
        statusContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusContainer.layer.borderColor = UIColor.green.withAlphaComponent(0.5).cgColor
        statusContainer.layer.borderWidth = 1
        statusContainer.layer.cornerRadius = 8
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(statusContainer)
        
        // Terminal prompt
        let promptLabel = UILabel()
        promptLabel.text = "system> communications_channel_initialized"
        promptLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        promptLabel.textColor = .green
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(promptLabel)
        
        // Status message
        let statusLabel = UILabel()
        statusLabel.text = "Displaying 3 messages (1 unread)"
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        
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
    
    @objc private func refreshMessages() {
        // Add refresh animation
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1
        navigationItem.rightBarButtonItem?.customView?.layer.add(rotation, forKey: "rotationAnimation")
        
        // Simulate refreshing messages
        tableView.alpha = 0.5
        
        // Add terminal-style "loading" text
        let loadingLabel = UILabel()
        loadingLabel.text = "Updating message queue..."
        loadingLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        loadingLabel.textColor = .green
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Reset table view
            self.tableView.alpha = 1.0
            loadingLabel.removeFromSuperview()
            
            // Reload data
            self.tableView.reloadData()
        }
    }
}

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
        
        // Simulate "selecting" animation
        if let cell = tableView.cellView(at: indexPath) as? MessageCell {
            // Flash the cell green briefly
            UIView.animate(withDuration: 0.1, animations: {
                cell.contentView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    cell.contentView.backgroundColor = .clear
                })
            }
        }
        
        // Show message content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let messageDetailVC = MessageDetailViewController()
            messageDetailVC.message = (self.messages[indexPath.row].sender,
                                      self.messages[indexPath.row].subject,
                                      self.messages[indexPath.row].preview)
            self.navigationController?.pushViewController(messageDetailVC, animated: true)
        }
    }
}

// Custom cell for message display
class MessageCell: UITableViewCell {
    private let containerView = UIView()
    private let senderLabel = UILabel()
    private let subjectLabel = UILabel()
    private let previewLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadIndicator = UIView()
    private let iconView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Cell background
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container view
        containerView.backgroundColor = UIColor.black
        containerView.layer.borderColor = UIColor.green.withAlphaComponent(0.3).cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Message icon
        iconView.image = UIImage(systemName: "envelope.fill")
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
        
        // Sender label
        senderLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        senderLabel.textColor = .white
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(senderLabel)
        
        // Subject label
        subjectLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        subjectLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subjectLabel)
        
        // Preview label
        previewLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        previewLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(previewLabel)
        
        // Date label (simulated date)
        dateLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        dateLabel.textColor = UIColor.green
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
    
    func configure(with message: (sender: String, subject: String, preview: String, isUnread: Bool)) {
        senderLabel.text = message.sender
        subjectLabel.text = message.subject
        previewLabel.text = message.preview
        dateLabel.text = "04.05.2025"
        
        // Show unread indicator if message is unread
        unreadIndicator.isHidden = !message.isUnread
        
        // Change icon based on sender
        switch message.sender {
        case "HR Department":
            iconView.image = UIImage(systemName: "person.text.rectangle.fill")
            iconView.tintColor = .systemPink
        case "IT Support":
            iconView.image = UIImage(systemName: "laptopcomputer")
            iconView.tintColor = .systemBlue
        case "Dr. Morgan":
            iconView.image = UIImage(systemName: "stethoscope")
            iconView.tintColor = .systemTeal
        default:
            iconView.image = UIImage(systemName: "envelope.fill")
            iconView.tintColor = .systemOrange
        }
        
        // Make unread messages stand out more
        if message.isUnread {
            containerView.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.5).cgColor
            containerView.layer.borderWidth = 1.5
            
            // Add pulsing animation to unread indicator
            UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.unreadIndicator.alpha = 0.6
            })
            
            senderLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .heavy)
            subjectLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        } else {
            containerView.layer.borderColor = UIColor.green.withAlphaComponent(0.3).cgColor
            containerView.layer.borderWidth = 1
            unreadIndicator.layer.removeAllAnimations()
            
            senderLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
            subjectLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        }
    }
}

// Helper extension for tableView
extension UITableView {
    func cellView(at indexPath: IndexPath) -> UITableViewCell? {
        return cellForRow(at: indexPath)
    }
}
