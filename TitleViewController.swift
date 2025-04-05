//
//  TitleViewController.swift
//  ChargeField
//

import UIKit

class TitleViewController: UIViewController {
    
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let backgroundView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        // Add dark background
        view.backgroundColor = .black
        
        // Add grid background effect
        setupGridBackground()
        
        // Company logo
        logoLabel.text = "NeutraTech"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 42)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        
        // Tagline
        taglineLabel.text = "Harmonizing the Future"
        taglineLabel.font = UIFont.italicSystemFont(ofSize: 18)
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        taglineLabel.textAlignment = .center
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(taglineLabel)
        
        // Start button
        startButton.setTitle("Access Account", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 8
        startButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        view.addSubview(startButton)
        
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
    }
    
    private func setupGridBackground() {
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
        let intersections = min(20, Int((view.bounds.width / gridSize) * (view.bounds.height / gridSize) / 10))
        
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
                animateDotPulse(dotView)
            }
        }
    }
    
    private func animateDotPulse(_ dotView: UIView) {
        UIView.animate(withDuration: Double.random(in: 1.5...3.0), delay: 0, options: [.repeat, .autoreverse], animations: {
            dotView.alpha = CGFloat.random(in: 0.1...0.3)
        })
    }
    
    @objc private func startButtonTapped() {
        // Create a snapshot of the current view for smooth transition
        guard let snapshot = view.snapshotView(afterScreenUpdates: false) else {
            // Navigate to loading screen if snapshot fails
            let loadingVC = LoadingViewController()
            navigationController?.pushViewController(loadingVC, animated: true)
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
            // Fade out the logo and tag line, but keep the grid
            if let logo = snapshot.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "NeutraTech" }) {
                logo.alpha = 0
            }
            
            if let tagline = snapshot.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "Harmonizing the Future" }) {
                tagline.alpha = 0
            }
            
            if let button = snapshot.subviews.first(where: { $0 is UIButton }) {
                button.alpha = 0
            }
        }) { _ in
            // Once animation completes, remove the snapshot and start the loading animation
            snapshot.removeFromSuperview()
            loadingVC.startLoadingAnimation()
        }
    }
}
