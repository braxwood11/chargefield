//
//  DialogViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/29/25.
//

import UIKit

class DialogViewController: UIViewController {
    var levelTag: Int = 0
    var completion: (() -> Void)?
    
    private let containerView = UIView()
    private let characterNameLabel = UILabel()
    private let dialogTextLabel = UILabel()
    private let continueButton = UIButton()
    
    // Sample dialogs for prototype
    private let tutorialDialogs = [
        (speaker: "Dr. Morgan", text: "Welcome to NeutraTech! I'll be guiding you through your orientation."),
        (speaker: "Dr. Morgan", text: "Your job is to stabilize energy anomalies using our proprietary tools."),
        (speaker: "Dr. Morgan", text: "You'll place stabilizers and suppressors to achieve the target energy values."),
        (speaker: "Dr. Morgan", text: "Don't worry about what these anomalies are yet - just focus on the numbers for now.")
    ]
    
    private let level1Dialogs = [
        (speaker: "Supervisor Chen", text: "Good work on the training. Ready for your first real assignment?"),
        (speaker: "Supervisor Chen", text: "These anomalies are a bit more complex. Remember your training."),
        (speaker: "Supervisor Chen", text: "And don't ask too many questions about what we're processing. Company policy.")
    ]
    
    private var currentDialogs: [(speaker: String, text: String)] = []
    private var dialogIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dialogs based on level
        if levelTag == 0 {
            currentDialogs = tutorialDialogs
        } else if levelTag == 1 {
            currentDialogs = level1Dialogs
        }
        
        setupUI()
        showCurrentDialog()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Container
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Character name
        characterNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        characterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(characterNameLabel)
        
        // Dialog text
        dialogTextLabel.font = UIFont.systemFont(ofSize: 16)
        dialogTextLabel.numberOfLines = 0
        dialogTextLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dialogTextLabel)
        
        // Continue button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 8
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        containerView.addSubview(continueButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            characterNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            characterNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            dialogTextLabel.topAnchor.constraint(equalTo: characterNameLabel.bottomAnchor, constant: 10),
            dialogTextLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dialogTextLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: dialogTextLabel.bottomAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            continueButton.widthAnchor.constraint(equalToConstant: 100),
            continueButton.heightAnchor.constraint(equalToConstant: 40),
            continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func showCurrentDialog() {
        guard dialogIndex < currentDialogs.count else {
            // End of dialog
            dismiss(animated: true) {
                self.completion?()
            }
            return
        }
        
        let dialog = currentDialogs[dialogIndex]
        characterNameLabel.text = dialog.speaker
        dialogTextLabel.text = dialog.text
    }
    
    @objc private func continueButtonTapped() {
        dialogIndex += 1
        showCurrentDialog()
    }
}
