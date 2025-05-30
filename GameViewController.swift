//
//  GameViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import UIKit

class GameViewController: UIViewController, GameStateDelegate {
    
    // MARK: - Properties
        
        private var viewModel: GameViewModel!
        var tutorialCompleted = false
        private var tutorialManager: TutorialManager?
        private var tutorialOverlay: TutorialOverlayView?
        private var completionBanner: UIView?
        
        // Default initializer
        init() {
            super.init(nibName: nil, bundle: nil)
        }
        
        // Custom initializer with viewModel
        init(viewModel: GameViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
            self.viewModel.delegate = self
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        private var cellViews: [[CellView]] = []
        private var gridView: UIView!
        
        private var positiveButton: MagnetButton!
        private var negativeButton: MagnetButton!
        
        private var resetButton: UIButton!
        private var solutionButton: UIButton!
        private var hintsButton: UIButton!
        
        private var messageView: MessageView!
        private var instructionLabel: UILabel!
        
        private var progressBar: UIProgressView!
        private var progressLabel: UILabel!
        private var backgroundView: UIView! // New background view for grid pattern
        
        var isLaunchedFromDashboard = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Force a UI update after view appears
            updateCellViews()
            updateUI()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            // Update cell views after layout is complete
            updateCellViews()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Setup the UI elements first, without updating their state
            setupUI()
            
            // If viewModel is already set, configure it
            if viewModel != nil {
                viewModel.delegate = self
                updateUI() // This calls updateMagnetButtons()
                
                // Add tutorial setup at the end if launched from dashboard
                if isLaunchedFromDashboard {
                    setupTutorial()
                }
            }
            // If launched from dashboard, we'll handle this differently
            else if isLaunchedFromDashboard {
                // Don't try to update UI yet - wait for viewModel to be set
            }
            // Original flow - initialize with default puzzle
            else {
                viewModel = GameViewModel(puzzle: .zPatternPuzzle())
                viewModel.delegate = self
                updateUI()
            }
            
            // Add tap gesture to the main view to detect taps outside the grid
            let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
            backgroundTapGesture.cancelsTouchesInView = false  // Allow taps to pass through to subviews
            view.addGestureRecognizer(backgroundTapGesture)
            
            // Add back button
            setupBackButton()
        }
        
        private func setupBackButton() {
            // Add custom back button
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(returnToDashboard)
            )
            backButton.tintColor = .green
            navigationItem.leftBarButtonItem = backButton
            
            // Set title with terminal style
            title = "CONTAINMENT CHAMBER"
            navigationController?.navigationBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
            ]
            navigationController?.navigationBar.barTintColor = .black
            navigationController?.navigationBar.isTranslucent = false
        }

        func setViewModel(_ newViewModel: GameViewModel) {
            self.viewModel = newViewModel
            
            // Set the delegate
            self.viewModel.delegate = self
            
            // Only update UI if the view is loaded and buttons are initialized
            if isViewLoaded && positiveButton != nil && negativeButton != nil {
                updateUI()
                
                // Setup tutorial if this is the tutorial level and launched from dashboard
                if isLaunchedFromDashboard && newViewModel.gameState.grid.count == 3 {
                    setupTutorial()
                }
            }
        }
    
    // MARK: - UI Setup
    
    private func setupUI() {
           // Set black background
           view.backgroundColor = .black
           
           // Setup background grid
           setupGridBackground()
           
           // Create status container
           let statusContainer = createStatusContainer()
           view.addSubview(statusContainer)
           
           // Create message view (initially hidden)
            messageView = MessageView(frame: .zero)
            messageView.setMessage("⚡ ALL FIELDS NEUTRALIZED ⚡")
            messageView.translatesAutoresizingMaskIntoConstraints = false
            messageView.isHidden = true
            messageView.updateStyleForTerminalTheme()  // Apply terminal styling
            view.addSubview(messageView)
           
           // Create grid - moved up
           setupGrid()
           
           // Create buttons
           setupMagnetButtons()
           setupControlButtons()
           
           // Create progress bar
           setupProgressBar()
           
           // Set constraints with proper centering
           NSLayoutConstraint.activate([
               // Status container
               statusContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
               statusContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
               statusContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
               
               // Message view
               messageView.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 10),
               messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
               messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
               messageView.heightAnchor.constraint(equalToConstant: 44),
               
               // Grid - centered and moved up
               gridView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 20),
               gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               gridView.widthAnchor.constraint(equalToConstant: 300),
               gridView.heightAnchor.constraint(equalToConstant: 300),
               
               // Center the magnet buttons container horizontally
               positiveButton.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 40),
               positiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60), // Left of center
               positiveButton.widthAnchor.constraint(equalToConstant: 100),
               positiveButton.heightAnchor.constraint(equalToConstant: 100),
               
               negativeButton.topAnchor.constraint(equalTo: positiveButton.topAnchor),
               negativeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60), // Right of center
               negativeButton.widthAnchor.constraint(equalToConstant: 100),
               negativeButton.heightAnchor.constraint(equalToConstant: 100),
               
               // Solution button to left of all buttons
               solutionButton.centerYAnchor.constraint(equalTo: positiveButton.centerYAnchor),
               solutionButton.trailingAnchor.constraint(equalTo: positiveButton.leadingAnchor, constant: -25),
               solutionButton.widthAnchor.constraint(equalToConstant: 60),
               solutionButton.heightAnchor.constraint(equalToConstant: 60),
               
               // Reset button to right of all buttons
               resetButton.centerYAnchor.constraint(equalTo: positiveButton.centerYAnchor),
               resetButton.leadingAnchor.constraint(equalTo: negativeButton.trailingAnchor, constant: 25),
               resetButton.widthAnchor.constraint(equalToConstant: 60),
               resetButton.heightAnchor.constraint(equalToConstant: 60),
               
               // Progress bar (below magnet buttons with more space)
               progressBar.topAnchor.constraint(equalTo: positiveButton.bottomAnchor, constant: 30),
               progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
               progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
               progressBar.heightAnchor.constraint(equalToConstant: 12),
               
               // Progress label
               progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 4),
               progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
           ])
       }
       
       private func setupGridBackground() {
           // Create a grid pattern background
           backgroundView = UIView(frame: view.bounds)
           backgroundView.backgroundColor = .clear
           backgroundView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(backgroundView)
           view.sendSubviewToBack(backgroundView)
           
           // Create grid lines
           let gridSize: CGFloat = 30
           let lineWidth: CGFloat = 0.5
           let lineColor = UIColor.black.withAlphaComponent(0.2)
           
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
                   animateDotPulse(dotView)
               }
           }
       }
       
       private func animateDotPulse(_ dotView: UIView) {
           UIView.animate(withDuration: Double.random(in: 1.5...3.0), delay: 0, options: [.repeat, .autoreverse], animations: {
               dotView.alpha = CGFloat.random(in: 0.1...0.3)
           })
       }
       
       private func createStatusContainer() -> UIView {
           let containerView = UIView()
           containerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
           containerView.layer.borderColor = UIColor.green.withAlphaComponent(0.5).cgColor
           containerView.layer.borderWidth = 1
           containerView.layer.cornerRadius = 8
           containerView.translatesAutoresizingMaskIntoConstraints = false
           
           // Terminal prompt
           let promptLabel = UILabel()
           promptLabel.text = "chamber> anomaly_stabilization_active"
           promptLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
           promptLabel.textColor = .green
           promptLabel.translatesAutoresizingMaskIntoConstraints = false
           containerView.addSubview(promptLabel)
           
           // Status message
           let statusLabel = UILabel()
           statusLabel.text = "Neutralize all field anomalies"
           statusLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
           statusLabel.textColor = .white
           statusLabel.translatesAutoresizingMaskIntoConstraints = false
           containerView.addSubview(statusLabel)
           
           // Set constraints
           NSLayoutConstraint.activate([
               promptLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
               promptLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
               promptLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
               
               statusLabel.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 8),
               statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
               statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
               statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
           ])
           
           // Height constraint to ensure proper size
           let heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 70)
           heightConstraint.priority = .defaultHigh
           heightConstraint.isActive = true
           
           return containerView
       }
       
       private func setupProgressBar() {
           // Create progress bar to show neutralization progress
           progressBar = UIProgressView(progressViewStyle: .default)
           progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
           progressBar.progressTintColor = UIColor.green
           progressBar.layer.cornerRadius = 5
           progressBar.clipsToBounds = true
           progressBar.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(progressBar)
           
           // Create progress label
           progressLabel = UILabel()
           progressLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
           progressLabel.textColor = .green
           progressLabel.textAlignment = .center
           progressLabel.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(progressLabel)
           
           // Set initial progress
           updateProgressDisplay()
       }
       
       private func setupMagnetButtons() {
           // Positive magnet button (stabilizer)
               positiveButton = MagnetButton(frame: .zero)
               positiveButton.translatesAutoresizingMaskIntoConstraints = false
               view.addSubview(positiveButton)
               
               // Negative magnet button (suppressor)
               negativeButton = MagnetButton(frame: .zero)
               negativeButton.translatesAutoresizingMaskIntoConstraints = false
               view.addSubview(negativeButton)
               
               // Terminal theme styling
               positiveButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
               negativeButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
               
               // Update the MagnetButton class to configure green terminal theme
               updateMagnetButtonsStyle()
       }
    
    private func updateMagnetButtonsStyle() {
        // Configure with terminal theme
        positiveButton.configure(type: 1, count: viewModel.gameState.availableMagnets.positive, isSelected: viewModel.gameState.selectedMagnetType == 1)
        negativeButton.configure(type: -1, count: viewModel.gameState.availableMagnets.negative, isSelected: viewModel.gameState.selectedMagnetType == -1)
        
        // Apply terminal styling
        [positiveButton, negativeButton].forEach { button in
            button.backgroundColor = .black
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
        }
    }
       
       private func setupGrid() {
           // Create container for the grid
               gridView = UIView(frame: .zero)
           gridView.backgroundColor = UIColor.white
               gridView.layer.cornerRadius = 8
               gridView.layer.borderWidth = 2
               gridView.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
               gridView.translatesAutoresizingMaskIntoConstraints = false
               view.addSubview(gridView)
               
               // Create the cells
               recreateGridCells()
               
               // Add glow effect
               gridView.layer.shadowColor = UIColor.green.cgColor
               gridView.layer.shadowOffset = CGSize.zero
               gridView.layer.shadowRadius = 10
               gridView.layer.shadowOpacity = 0.3
       }
       
       private func setupControlButtons() {
           // Solution button - now terminal-themed
               solutionButton = UIButton(type: .system)
               solutionButton.backgroundColor = .black
               solutionButton.layer.borderWidth = 2
               solutionButton.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
               solutionButton.setTitleColor(.green, for: .normal)
               solutionButton.layer.cornerRadius = 30 // Keep it circular
           
           // Use a hint/solution icon (puzzle piece)
           let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
           let solutionImage = UIImage(systemName: "puzzlepiece.fill", withConfiguration: configuration)
           solutionButton.setImage(solutionImage, for: .normal)
           solutionButton.tintColor = .green
           
           solutionButton.addTarget(self, action: #selector(solutionButtonTapped), for: .touchUpInside)
           solutionButton.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(solutionButton)
           
           // Reset button - circular with a symbol
           resetButton = UIButton(type: .system)
           resetButton.backgroundColor = .black
           resetButton.setTitleColor(.white, for: .normal)
           resetButton.layer.cornerRadius = 30 // Make it circular
           resetButton.layer.borderWidth = 2
           resetButton.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
           
           // Use a reset/refresh symbol
           let resetImage = UIImage(systemName: "arrow.counterclockwise", withConfiguration: configuration)
           resetButton.setImage(resetImage, for: .normal)
           resetButton.tintColor = .green
           
           resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
           resetButton.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(resetButton)
           
           // Add button press effects
           addButtonPressEffects(solutionButton)
           addButtonPressEffects(resetButton)
       }
       
       private func addButtonPressEffects(_ button: UIButton) {
           button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
           button.addTarget(self, action: #selector(buttonTouchUpOutside(_:)), for: .touchUpOutside)
           button.addTarget(self, action: #selector(buttonTouchUpOutside(_:)), for: .touchCancel)
       }
       
       @objc private func buttonTouchDown(_ sender: UIButton) {
           UIView.animate(withDuration: 0.1) {
               sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
               sender.alpha = 0.8
           }
       }
       
       @objc private func buttonTouchUpOutside(_ sender: UIButton) {
           UIView.animate(withDuration: 0.1) {
               sender.transform = CGAffineTransform.identity
               sender.alpha = 1.0
           }
       }
    
    // MARK: - Tutorial Handlers
    
    private func setupTutorial() {
        // Only setup tutorial for the tutorial level
        guard isLaunchedFromDashboard,
              viewModel.gameState.grid.count == 3 else { // Assuming 3x3 for tutorial
            return
        }
        
        tutorialManager = TutorialManager()
        tutorialManager?.accessProvider = self
        tutorialManager?.gameViewController = self
        
        tutorialOverlay = TutorialOverlayView(frame: view.bounds)
        if let tutorialOverlay = tutorialOverlay {
            tutorialOverlay.setNextButtonAction(self, action: #selector(advanceTutorial))
            
            view.addSubview(tutorialOverlay)
            updateTutorialState()
        }
    }

    @objc private func advanceTutorial() {
        print("Advance Tutorial called")
            print("Tutorial Manager: \(String(describing: tutorialManager))")
            tutorialManager?.advanceToNextStep()
            print("Current Step: \(String(describing: tutorialManager?.currentStep))")
            updateTutorialState()
    }

    private func updateTutorialState() {
        guard let tutorialManager = tutorialManager,
              let tutorialOverlay = tutorialOverlay else { return }
        
        view.gestureRecognizers?.forEach { gesture in
                gesture.cancelsTouchesInView = false
                gesture.delaysTouchesBegan = false
                gesture.delaysTouchesEnded = false
            }
        
        
        // Update instruction text
        tutorialOverlay.setInstructionText(tutorialManager.getInstructionText())
        
        // Show next button only for steps that don't require action
        let showNextButton = !tutorialManager.requiresAction()
        tutorialOverlay.showNextButton(showNextButton)
        
        // Make the button more visible when shown
        if showNextButton {
            // Make the button more visible for debugging
            tutorialOverlay.nextButton.backgroundColor = UIColor.green.withAlphaComponent(0.3)
            
            // Explicitly bring button to front
            tutorialOverlay.bringSubviewToFront(tutorialOverlay.nextButton)
            
            // Print button details
            print("Next button frame: \(tutorialOverlay.nextButton.frame)")
            print("Button in view hierarchy: \(tutorialOverlay.nextButton.superview != nil)")
            print("Button enabled: \(tutorialOverlay.nextButton.isEnabled)")
            print("Button user interaction enabled: \(tutorialOverlay.nextButton.isUserInteractionEnabled)")
            
            // Try adding a direct tap recognizer as backup
            let directTap = UITapGestureRecognizer(target: self, action: #selector(advanceTutorial))
            tutorialOverlay.nextButton.addGestureRecognizer(directTap)
        }
        
        // Handle overlay visibility based on step
        if tutorialManager.currentStep == .completeTask {
            // Show the custom completion banner
                showCompletionBanner()
                
                // Remove the overlay to allow full interaction
                tutorialOverlay.isHidden = true
        } else {
            // For other steps, show normal overlay with highlighting
            tutorialOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            tutorialOverlay.clearHighlight()
            tutorialOverlay.resetInstructionPosition()
            tutorialOverlay.allowFullInteraction = false
            
            // Highlight the current element of interest
            let highlightedElement = tutorialManager.getHighlightedElement()
            
            if let elements = highlightedElement as? [UIView?] {
                // If we got an array of views, use the multiple highlight method
                tutorialOverlay.highlightMultipleElements(elements)
            } else if let singleElement = highlightedElement as? UIView {
                // If we got a single view, use the original method
                tutorialOverlay.highlightElement(singleElement)
            }
        }
        
        // Handle tutorial completion
        if tutorialManager.currentStep == .finished {
            tutorialCompleted = true
            
            UIView.animate(withDuration: 0.5, animations: {
                tutorialOverlay.alpha = 0
            }) { _ in
                tutorialOverlay.removeFromSuperview()
                self.tutorialManager = nil
                self.tutorialOverlay = nil
                
                self.completionBanner?.removeFromSuperview()
                
                self.showTutorialCompletionMessage()
            }
        }
    }
    
    private func showCompletionBanner() {
        // First, remove the existing tutorial overlay
        tutorialOverlay?.removeFromSuperview()
        
        // Create a custom completion banner
        let banner = UIView()
        banner.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        banner.layer.cornerRadius = 8
        banner.layer.borderWidth = 1
        banner.layer.borderColor = UIColor.green.cgColor
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        
        // Create the instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Complete the puzzle by matching all target values."
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(instructionLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            // Position banner below navigation bar
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            // Position label inside banner
            instructionLabel.topAnchor.constraint(equalTo: banner.topAnchor, constant: 10),
            instructionLabel.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -10),
            instructionLabel.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 10),
            instructionLabel.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -10)
        ])
        
        // Store a reference to this banner
        self.completionBanner = banner
    }


    private func showTutorialCompletionMessage() {
        let alert = UIAlertController(
            title: "Training Complete!",
            message: "Great job! You've neutralized those pesky energy anomalies. Check your dashboard for your next assignment.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Return to dashboard", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Action Handlers
    
    @objc private func returnToDashboard() {
            // Show completion dialog if puzzle is solved
            if viewModel.gameState.puzzleSolved {
                showCompletionDialog()
            } else {
                // Just go back without showing dialog
                navigationController?.popViewController(animated: true)
            }
        }
    
    private func showCompletionDialog() {
            // Create a simple completion dialog
            let alert = UIAlertController(
                title: "Assignment Complete",
                message: "You've successfully processed this assignment. Return to headquarters?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Return", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            
            present(alert, animated: true)
        }
        
    
    @objc private func cellTapped(_ gesture: UITapGestureRecognizer) {
        guard let cellView = gesture.view as? CellView else { return }
        
        // Extract row and column from tag
        let row = cellView.tag / 100
        let col = cellView.tag % 100
        
        // Only restrict interaction during specific tutorial steps
        if let tutorialManager = tutorialManager,
           tutorialManager.currentStep != .completeTask {
            if tutorialManager.currentStep == .tapCellToPreview {
                if row == 0 && col == 0 {
                    viewModel.selectCell(at: row, col: col)
                    showInfluencePreview(row: row, col: col)
                    advanceTutorial()
                }
                return
            } else if tutorialManager.currentStep == .tapAgainToPlace {
                if row == 0 && col == 0 && viewModel.gameState.grid[row][col].isSelected {
                    viewModel.placeOrRemoveMagnet(at: row, col: col)
                    clearAllInfluencePreviews()
                    advanceTutorial()
                }
                return
            } else {
                // Block interaction for other tutorial steps
                return
            }
        }
        
        // Direct removal approach - if the cell has a magnet and we're tapping directly on it
        if viewModel.gameState.grid[row][col].toolEffect != 0 {
            // Direct tap on a magnet - remove it
            if viewModel.gameState.grid[row][col].toolEffect == 1 {
                viewModel.gameState.availableMagnets.positive += 1
            } else if viewModel.gameState.grid[row][col].toolEffect == -1 {
                viewModel.gameState.availableMagnets.negative += 1
            }
            
            // Clear the magnet value
            viewModel.gameState.grid[row][col].toolEffect = 0
            
            // Update the field
            viewModel.updateFieldValues()
            
            // Clear any selections and previews
            clearAllInfluencePreviews()
            viewModel.clearAllSelections()
            
            return
        }
        
        // Regular placement flow - first select, then place
        if viewModel.gameState.grid[row][col].isSelected {
            viewModel.placeOrRemoveMagnet(at: row, col: col)
            clearAllInfluencePreviews()
        } else {
            viewModel.selectCell(at: row, col: col)
            showInfluencePreview(row: row, col: col)
        }
        
        // Check if puzzle is solved during tutorial
        if let tutorialManager = tutorialManager,
           tutorialManager.currentStep == .completeTask &&
           viewModel.gameState.puzzleSolved {
            advanceTutorial()
        }
    }
    
    private func removeMagnet(at row: Int, col: Int) {
        let currentValue = viewModel.gameState.grid[row][col].toolEffect
        
        // Return the magnet to available magnets
        if currentValue == 1 {
            viewModel.gameState.availableMagnets.positive += 1
        } else if currentValue == -1 {
            viewModel.gameState.availableMagnets.negative += 1
        }
        
        // Remove the magnet
        viewModel.gameState.grid[row][col].toolEffect = 0
        
        // Clear any selection
        viewModel.gameState.grid[row][col].isSelected = false
        
        // Update field values
        viewModel.updateFieldValues()
    }
    
    // Handle tap outside of grid (clear selection)
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        // If tap is outside the grid, clear selection
        if !gridView.frame.contains(location) {
            // Clear any selected cells
            clearAllSelections()
            
            // Clear influence previews
            clearAllInfluencePreviews()
        }
    }
    
    @objc private func newPuzzleButtonTapped() {
        
        // Create an alert controller for difficulty selection
        let alertController = UIAlertController(title: "New Puzzle", message: "Select difficulty level", preferredStyle: .actionSheet)
        
        // Add difficulty options
        let easyAction = UIAlertAction(title: "Easy", style: .default) { [weak self] _ in
            self?.loadNewPuzzle(difficulty: "easy")
        }
        
        let mediumAction = UIAlertAction(title: "Medium", style: .default) { [weak self] _ in
            self?.loadNewPuzzle(difficulty: "medium")
        }
        
        let hardAction = UIAlertAction(title: "Hard", style: .default) { [weak self] _ in
            self?.loadNewPuzzle(difficulty: "hard")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(easyAction)
        alertController.addAction(mediumAction)
        alertController.addAction(hardAction)
        alertController.addAction(cancelAction)
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    private func loadNewPuzzle(difficulty: String) {
        // Determine grid size based on difficulty
        let gridSize = difficulty.lowercased() == "easy" ? 4 : 5
        
        // Determine magnet counts based on difficulty
        let positiveMagnets = difficulty.lowercased() == "easy" ? 2 : 3
        let negativeMagnets = difficulty.lowercased() == "easy" ? 2 : 3
        
        // Generate a new random puzzle with the selected difficulty and grid size
        let puzzle = PuzzleDefinition.generateRandomPuzzle(
            gridSize: gridSize,
            difficulty: difficulty,
            positiveMagnets: positiveMagnets,
            negativeMagnets: negativeMagnets
        )
        
        // Create a new view model with the puzzle
        viewModel = GameViewModel(puzzle: puzzle)
        viewModel.delegate = self
        
        // Remove existing cell views
        for subview in gridView.subviews {
            subview.removeFromSuperview()
        }
        
        // Clear cell views array
        cellViews.removeAll()
        
        // Create new grid cells (the grid container itself remains in the same position)
        recreateGridCells()
        
        // Update UI
        updateUI()
        updateCellViews()
        updateUI()
    }
    
    // Create or recreate just the cells within the grid
    private func recreateGridCells() {
        let gridSize = viewModel.gameState.grid.count
        let cellSize = 300 / CGFloat(gridSize) - 4 // 300px grid width with 4px spacing
        
        // Create cell views
        for row in 0..<gridSize {
            var rowViews: [CellView] = []
            
            for col in 0..<gridSize {
                let cellView = CellView(frame: .zero)
                cellView.cell = viewModel.gameState.grid[row][col]
                cellView.showHints = viewModel.gameState.showHints
                cellView.selectedMagnetType = viewModel.gameState.selectedMagnetType
                
                cellView.backgroundColor = .white
                
                // Position the cell
                let x = CGFloat(col) * (cellSize + 4) + 2
                let y = CGFloat(row) * (cellSize + 4) + 2
                cellView.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                
                // Add tap gesture
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
                cellView.addGestureRecognizer(tapGesture)
                cellView.isUserInteractionEnabled = true
                
                // Store row and column as tag (row * 100 + col)
                cellView.tag = row * 100 + col
                
                gridView.addSubview(cellView)
                rowViews.append(cellView)
            }
            
            cellViews.append(rowViews)
        }
    }
    
    // Clear all cell selections
    private func clearAllSelections() {
        // Use the ViewModel's method to clear selections
        viewModel.clearAllSelections()
    }
    
    private func showInfluencePreview(row: Int, col: Int) {
        // Clear previous previews
        clearAllInfluencePreviews()
        
        // Get influence area
        let influenceArea = viewModel.getInfluenceArea(for: row, col: col)
        let magnetType = viewModel.gameState.selectedMagnetType
        
        // First, specially handle the central cell to show ±3
        if row < cellViews.count && col < cellViews[row].count {
            cellViews[row][col].showCentralMagnetInfluence(magnetType: magnetType)
        }
        
        // Then handle all other cells in the influence area
        for r in 0..<influenceArea.count {
            for c in 0..<influenceArea[r].count {
                // Skip the central cell as we've already handled it
                if r == row && c == col {
                    continue
                }
                
                if influenceArea[r][c] {
                    // Calculate influence intensity based on distance
                    let intensity = viewModel.getInfluenceIntensity(from: row, sourceCol: col, to: r, targetCol: c)
                    
                    // Show influence preview if cell exists in our UI grid
                    if r < cellViews.count && c < cellViews[r].count {
                        cellViews[r][c].showInfluence(intensity: intensity, magnetType: magnetType)
                    }
                }
            }
        }
    }
    
    // Clear all influence previews
    private func clearAllInfluencePreviews() {
        for rowViews in cellViews {
            for cellView in rowViews {
                cellView.clearInfluence()
            }
        }
    }
    
    @objc private func magnetButtonTapped(_ sender: MagnetButton) {
        // Check tutorial state first
        if let tutorialManager = tutorialManager {
            switch tutorialManager.currentStep {
            case .selectStabilizer:
                if sender.toolType == 1 {
                    // Only allow selecting the stabilizer during this step
                    viewModel.gameState.selectedMagnetType = sender.toolType
                    updateMagnetButtons()
                    updateCellViews()
                    advanceTutorial()
                }
                return
                
            case .explainSuppressor:
                if sender.toolType == -1 {
                    // Only allow selecting the suppressor during this step
                    viewModel.gameState.selectedMagnetType = sender.toolType
                    updateMagnetButtons()
                    updateCellViews()
                    advanceTutorial()
                }
                return
                
            case .completeTask:
                // Allow normal interaction during the "complete task" step
                // Fall through to the normal logic
                break
                
            default:
                // For other steps, block interaction with magnet buttons
                return
            }
        }
        
        // Normal magnet button interaction logic
        viewModel.gameState.selectedMagnetType = sender.toolType
        updateMagnetButtons()
        updateCellViews()
        
    }
    
    @objc private func resetButtonTapped() {
        viewModel.resetPuzzle()
        updateUI()
    }
    
    @objc private func solutionButtonTapped() {
        viewModel.toggleSolution()
        updateSolutionButton()
        updateUI()
    }
    
    @objc private func hintsButtonTapped() {
        viewModel.toggleHints()
        updateCellViews()
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
            updateMagnetButtons()
            updateCellViews()
            updateSolutionButton()
            updateMessageView()
            updateProgressDisplay()
        }

        private func updateMagnetButtons() {
            positiveButton.configure(type: 1, count: viewModel.gameState.availableMagnets.positive, isSelected: viewModel.gameState.selectedMagnetType == 1)
            negativeButton.configure(type: -1, count: viewModel.gameState.availableMagnets.negative, isSelected: viewModel.gameState.selectedMagnetType == -1)
        }
        
        private func updateCellViews() {
            for row in 0..<cellViews.count {
                for col in 0..<cellViews[row].count {
                    cellViews[row][col].cell = viewModel.gameState.grid[row][col]
                    cellViews[row][col].showHints = viewModel.gameState.showHints
                    cellViews[row][col].selectedMagnetType = viewModel.gameState.selectedMagnetType
                }
            }
        }
    
    private func updateSolutionButton() {
        // Use a different icon when showing solution
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconName = viewModel.gameState.showSolution ? "eye.slash.fill" : "puzzlepiece.fill"
        let icon = UIImage(systemName: iconName, withConfiguration: configuration)
        solutionButton.setImage(icon, for: .normal)
        
        // Change appearance when showing solution
        if viewModel.gameState.showSolution {
            solutionButton.backgroundColor = UIColor.green.withAlphaComponent(0.2)
            solutionButton.layer.borderWidth = 2
            solutionButton.layer.borderColor = UIColor.green.cgColor
            solutionButton.tintColor = .green
        } else {
            solutionButton.backgroundColor = .black
            solutionButton.layer.borderWidth = 2
            solutionButton.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
            solutionButton.tintColor = .green
        }
    }
        
        private func updateMessageView() {
            messageView.isHidden = !(viewModel.gameState.puzzleSolved && !viewModel.gameState.showSolution)
        }
        
        // Update progress bar and status label
        private func updateProgressDisplay() {
            // Count the total number of target cells (cells with initial charge)
            var totalTargetCells = 0
            var neutralizedCells = 0
            
            for row in 0..<viewModel.gameState.grid.count {
                for col in 0..<viewModel.gameState.grid[row].count {
                    let cell = viewModel.gameState.grid[row][col]
                    if cell.initialCharge != 0 {
                        totalTargetCells += 1
                        if cell.isNeutralized {
                            neutralizedCells += 1
                        }
                    }
                }
            }
            
            // Calculate progress
            let progress = totalTargetCells > 0 ? Float(neutralizedCells) / Float(totalTargetCells) : 0.0
            
            // Update progress bar with animation
            UIView.animate(withDuration: 0.3) {
                self.progressBar.setProgress(progress, animated: true)
            }
            
            // Update progress label with monospaced font
            progressLabel.text = "\(neutralizedCells)/\(totalTargetCells) FIELDS NEUTRALIZED"
        }
    
    // MARK: - GameStateDelegate Methods
    
    func gameStateDidChange() {
        updateUI()
        
        // Check if puzzle is complete during tutorial
        if let tutorialManager = tutorialManager,
           tutorialManager.currentStep == .completeTask &&
           viewModel.gameState.puzzleSolved {
            advanceTutorial()
        }
    }
    
    func puzzleSolved() {
        // Show celebration animation or feedback
        updateMessageView()
        
        // Optional: Play sound or haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Animate progress bar fill
        UIView.animate(withDuration: 0.5) {
            self.progressBar.setProgress(1.0, animated: true)
        }
    }
}


// MARK: - Extension for any additional functionality

// Add this protocol
protocol TutorialAccessible: AnyObject {
    func getStabilizerButton() -> UIView?
    func getSuppressorButton() -> UIView?
    func getGridView() -> UIView?
    func getCellView(at row: Int, col: Int) -> UIView?
}

// Make GameViewController implement the protocol
extension GameViewController: TutorialAccessible {
    func getStabilizerButton() -> UIView? {
        return positiveButton
    }
    
    func getGridView() -> UIView? {
        return gridView
    }
    
    func getSuppressorButton() -> UIView? {
        return negativeButton
    }
    
    func getCellView(at row: Int, col: Int) -> UIView? {
        if row < cellViews.count && col < cellViews[row].count {
            return cellViews[row][col]
        }
        return nil
    }
}
