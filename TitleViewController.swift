//
//  TitleViewController.swift
//  ChargeField
//

import UIKit

class TitleViewController: UIViewController {
    
    // MARK: - UI Elements
    private let logoLabel = TerminalLabel()
    private let taglineLabel = TerminalLabel()
    private let startButton = TerminalButton()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        checkFirstLaunch()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Apply terminal theme background
        TerminalTheme.applyBackground(to: self)
        
        // Configure logo
        logoLabel.text = "NeutraTech"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 42)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        
        // Configure tagline
        taglineLabel.text = "Harmonizing the Future"
        taglineLabel.style = .caption
        taglineLabel.font = UIFont.italicSystemFont(ofSize: 18)
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        taglineLabel.textAlignment = .center
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(taglineLabel)
        
        // Configure start button
        startButton.setTitle("Access Account", for: .normal)
        startButton.style = .primary
        startButton.backgroundColor = .systemGreen
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 8
        startButton.titleLabel?.font = TerminalTheme.Fonts.monospaced(size: 16, weight: .bold)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        view.addSubview(startButton)
        
        // Add button press effect
        addButtonPressEffect(to: startButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 20),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 40),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add fade-in animation
        animateUIElements()
    }
    
    // MARK: - Animations
    private func animateUIElements() {
        // Set initial alpha
        logoLabel.alpha = 0
        taglineLabel.alpha = 0
        startButton.alpha = 0
        
        // Animate fade-in
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.4, options: .curveEaseOut) {
            self.taglineLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.6, options: .curveEaseOut) {
            self.startButton.alpha = 1
        }
    }
    
    private func addButtonPressEffect(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func startButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Create smooth transition
        createTransitionToLoading()
    }
    
    private func createTransitionToLoading() {
        // Create a snapshot of the current view for smooth transition
        guard let snapshot = view.snapshotView(afterScreenUpdates: false) else {
            navigateToLoading()
            return
        }
        
        // Create the loading view controller
        let loadingVC = LoadingViewController()
        
        // Add the snapshot to the loading controller's view
        loadingVC.view.addSubview(snapshot)
        
        // Push the loading controller without animation
        navigationController?.pushViewController(loadingVC, animated: false)
        
        // Animate the transition
        UIView.animate(withDuration: 0.5, animations: {
            // Fade out UI elements but keep the grid
            snapshot.subviews.forEach { subview in
                if subview is UILabel || subview is UIButton {
                    subview.alpha = 0
                }
            }
        }) { _ in
            // Remove snapshot and start loading animation
            snapshot.removeFromSuperview()
            loadingVC.startLoadingAnimation()
        }
    }
    
    private func navigateToLoading() {
        let loadingVC = LoadingViewController()
        navigationController?.pushViewController(loadingVC, animated: true)
        
        // Start loading animation after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadingVC.startLoadingAnimation()
        }
    }
    
    // MARK: - First Launch Check
    private func checkFirstLaunch() {
        // Check messages for first launch
        MessageManager.shared.checkTriggeredMessages()
    }
}
