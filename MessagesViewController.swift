//
//  MessagesViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class MessagesViewController: UIViewController {
    private let tableView = UITableView()
    
    // Sample messages for prototype
    private let messages = [
        (sender: "HR Department", subject: "Welcome to NeutraTech", preview: "Please complete your orientation training..."),
        (sender: "IT Support", subject: "Employee Credentials", preview: "Your system access has been provisioned..."),
        (sender: "Dr. Morgan", subject: "Training Schedule", preview: "Looking forward to guiding you through...")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Company Messages"
        view.backgroundColor = .systemBackground
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        let message = messages[indexPath.row]
        
        cell.textLabel?.text = message.subject
        cell.detailTextLabel?.text = message.preview
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show message content
        let messageDetailVC = MessageDetailViewController()
        messageDetailVC.message = messages[indexPath.row]
        navigationController?.pushViewController(messageDetailVC, animated: true)
    }
}
