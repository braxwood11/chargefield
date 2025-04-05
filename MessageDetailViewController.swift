//
//  MessageDetailViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessageDetailViewController: UIViewController {
    var message: (sender: String, subject: String, preview: String)?
    
    private let senderLabel = UILabel()
    private let subjectLabel = UILabel()
    private let contentTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Message"
        view.backgroundColor = .systemBackground
        
        setupUI()
        populateMessage()
    }
    
    private func setupUI() {
        // Sender label
        senderLabel.font = UIFont.boldSystemFont(ofSize: 16)
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(senderLabel)
        
        // Subject label
        subjectLabel.font = UIFont.boldSystemFont(ofSize: 20)
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subjectLabel)
        
        // Content text view
        contentTextView.font = UIFont.systemFont(ofSize: 16)
        contentTextView.isEditable = false
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentTextView)
        
        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            senderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            senderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subjectLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 10),
            subjectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            contentTextView.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 20),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func populateMessage() {
        guard let message = message else { return }
        
        senderLabel.text = "From: \(message.sender)"
        subjectLabel.text = message.subject
        
        // Generate a longer message content based on the preview
        contentTextView.text = """
        Dear New Employee,
        
        \(getAdditionalContent(for: message.subject))
        
        Regards,
        \(message.sender)
        NeutraTech Corporation
        "Harmonizing the Future"
        """
    }
    
    private func getAdditionalContent(for subject: String) -> String {
        switch subject {
        case "Welcome to NeutraTech":
            return """
            We're pleased to have you join our team of Field Harmonization Specialists. Your role is vital to our mission of managing energy anomalies.
            
            During your orientation, you'll learn to use our proprietary stabilization and suppression tools to achieve target energy values. These tools are the result of decades of research and are critical to our operations.
            
            Please report to Dr. Morgan for your orientation training as soon as possible.
            """
            
        case "Employee Credentials":
            return """
            Your system access has been provisioned with Level 1 clearance. This grants you access to basic field harmonization tools and standard anomaly data.
            
            Your employee ID is NT-7842. Please memorize this number as it will be required for all facility access.
            
            Note that certain areas of our facility require higher clearance levels, which you may obtain after successful completion of your initial assignments.
            """
            
        case "Training Schedule":
            return """
            I've scheduled your orientation for today. Please be prompt as we have much to cover.
            
            You'll be introduced to our stabilization and suppression technology, as well as the basics of field harmonization. Don't worry if it seems complex at first - most new employees take some time to adjust to our unique procedures.
            
            I'm looking forward to working with you and answering any questions you might have about your role here at NeutraTech.
            """
            
        default:
            return "We'll provide more information soon. Thank you for your attention to this matter."
        }
    }
}
