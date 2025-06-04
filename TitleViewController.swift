//
//  TitleViewController.swift
//  ChargeField
//

import UIKit

class TitleViewController: UIViewController {
    
    // MARK: - UI Elements
    private let logoImageView = UIImageView() // Changed from logoLabel to logoImageView
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
        setupLogo()
        
        
        
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
        setupConstraints()
        
        // Add fade-in animation
        animateUIElements()
    }
    
    private func setupLogo() {
        // Load the logo image
        logoImageView.image = UIImage(named: "NT-Logo-1")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Optional: Add a subtle tint if you want the logo to match the terminal theme
        // logoImageView.tintColor = .white
        
        view.addSubview(logoImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Logo - updated constraints for image
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 280), // Max width
            logoImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 175), // Max height
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Animations
    private func animateUIElements() {
        // Set initial alpha
        logoImageView.alpha = 0
        startButton.alpha = 0
        
        // Animate fade-in
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
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
