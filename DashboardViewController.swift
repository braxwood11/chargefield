//
//  DashboardViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DashboardViewController: UIViewController {
    
    private var tutorialCompleted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Employee Dashboard"
        view.backgroundColor = .systemBackground
        
        // Welcome message
        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome, New Field Specialist"
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 20)
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)
        
        // Available assignments section
        let assignmentsLabel = UILabel()
        assignmentsLabel.text = "Available Assignments"
        assignmentsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        assignmentsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assignmentsLabel)
        
        // Tutorial button
        let tutorialButton = createLevelButton(title: "Orientation Training", tag: 0)
        tutorialButton.backgroundColor = .systemGreen
        view.addSubview(tutorialButton)
        
        // Level 1 button
        let level1Button = createLevelButton(title: "Assignment #1", tag: 1)
        level1Button.backgroundColor = .systemBlue
        view.addSubview(level1Button)
        
        // Level 2 button (locked initially)
        let level2Button = createLevelButton(title: "Assignment #2 (Locked)", tag: 2)
        level2Button.backgroundColor = .systemGray
        level2Button.isEnabled = false
        view.addSubview(level2Button)
        
        // Messages button
        let messagesButton = UIButton(type: .system)
        messagesButton.setTitle("Company Messages (1)", for: .normal)
        messagesButton.backgroundColor = .systemOrange
        messagesButton.setTitleColor(.white, for: .normal)
        messagesButton.layer.cornerRadius = 8
        messagesButton.translatesAutoresizingMaskIntoConstraints = false
        messagesButton.addTarget(self, action: #selector(messagesButtonTapped), for: .touchUpInside)
        view.addSubview(messagesButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            assignmentsLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            assignmentsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            tutorialButton.topAnchor.constraint(equalTo: assignmentsLabel.bottomAnchor, constant: 20),
            tutorialButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tutorialButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tutorialButton.heightAnchor.constraint(equalToConstant: 60),
            
            level1Button.topAnchor.constraint(equalTo: tutorialButton.bottomAnchor, constant: 15),
            level1Button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            level1Button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            level1Button.heightAnchor.constraint(equalToConstant: 60),
            
            level2Button.topAnchor.constraint(equalTo: level1Button.bottomAnchor, constant: 15),
            level2Button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            level2Button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            level2Button.heightAnchor.constraint(equalToConstant: 60),
            
            messagesButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            messagesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messagesButton.widthAnchor.constraint(equalToConstant: 250),
            messagesButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
    
    private func createLevelButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(levelButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func updateLevelButtons() {
        // Enable level 1 button only if tutorial is completed
        if let level1Button = view.viewWithTag(1) as? UIButton {
            level1Button.isEnabled = tutorialCompleted
            level1Button.backgroundColor = tutorialCompleted ? .systemBlue : .systemGray
            level1Button.setTitle(tutorialCompleted ? "Assignment #1" : "Assignment #1 (Complete Tutorial First)", for: .normal)
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
    
    // In DashboardViewController.swift - modify the startLevel method:

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
        // You'll need to add this property to GameViewController
        gameVC.isLaunchedFromDashboard = true
        
        navigationController?.pushViewController(gameVC, animated: true)
    }
}
