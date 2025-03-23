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
        
        // Force a UI update after a slight delay to ensure everything is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCellViews()
            }
        
        // Initialize with the Z pattern puzzle
        viewModel = GameViewModel(puzzle: .zPatternPuzzle())
        viewModel.delegate = self
        
        setupUI()
        
        // Add tap gesture to the main view to detect taps outside the grid
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundTapGesture.cancelsTouchesInView = false  // Allow taps to pass through to subviews
        view.addGestureRecognizer(backgroundTapGesture)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Create title
        let titleLabel = UILabel()
        titleLabel.text = "ChargeField"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Create message view (initially hidden)
        messageView = MessageView(frame: .zero)
        messageView.setMessage("🎉 All Fields Neutralized! 🎉")
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.isHidden = true
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
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Message view
            messageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
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
        progressLabel.font = UIFont.systemFont(ofSize: 12)
        progressLabel.textColor = .darkGray
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressLabel)
        
        // Set initial progress
        updateProgressDisplay()
    }
    
    private func setupMagnetButtons() {
        // Positive magnet button
        positiveButton = MagnetButton(frame: .zero)
        positiveButton.configure(type: 1, count: viewModel.gameState.availableMagnets.positive, isSelected: viewModel.gameState.selectedMagnetType == 1)
        positiveButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
        positiveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(positiveButton)
        
        // Negative magnet button
        negativeButton = MagnetButton(frame: .zero)
        negativeButton.configure(type: -1, count: viewModel.gameState.availableMagnets.negative, isSelected: viewModel.gameState.selectedMagnetType == -1)
        negativeButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
        negativeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(negativeButton)
    }
    
    private func setupGrid() {
        // Create container for the grid
        gridView = UIView(frame: .zero)
        gridView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        gridView.layer.cornerRadius = 8
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        // Create the cells
        recreateGridCells()
    }
    
    private func setupControlButtons() {
        // Solution button - now a circular button with a different symbol and color
        solutionButton = UIButton(type: .system)
        solutionButton.backgroundColor = UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 1.0) // Purple color
        solutionButton.setTitleColor(.white, for: .normal)
        solutionButton.layer.cornerRadius = 30 // Make it circular
        
        // Use a hint/solution icon (puzzle piece)
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let solutionImage = UIImage(systemName: "puzzlepiece.fill", withConfiguration: configuration)
        solutionButton.setImage(solutionImage, for: .normal)
        solutionButton.tintColor = .white
        
        solutionButton.addTarget(self, action: #selector(solutionButtonTapped), for: .touchUpInside)
        solutionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(solutionButton)
        
        // Reset button - circular with a symbol
        resetButton = UIButton(type: .system)
        resetButton.backgroundColor = .lightGray
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 30 // Make it circular
        
        // Use a reset/refresh symbol
        let resetImage = UIImage(systemName: "arrow.counterclockwise", withConfiguration: configuration)
        resetButton.setImage(resetImage, for: .normal)
        resetButton.tintColor = .white
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)
        
        // New Puzzle button
        let newPuzzleButton = UIButton(type: .system)
        newPuzzleButton.setTitle("New Puzzle", for: .normal)
        newPuzzleButton.backgroundColor = .orange
        newPuzzleButton.setTitleColor(.white, for: .normal)
        newPuzzleButton.layer.cornerRadius = 8
        newPuzzleButton.addTarget(self, action: #selector(newPuzzleButtonTapped), for: .touchUpInside)
        newPuzzleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPuzzleButton)
        
        // Set constraints for new puzzle button
        NSLayoutConstraint.activate([
            newPuzzleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            newPuzzleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newPuzzleButton.widthAnchor.constraint(equalToConstant: 160),
            newPuzzleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    /*
    private func setupInstructions() {
        // Create instructions label with updated game concept
        instructionLabel = UILabel()
        instructionLabel.text = """
        How To Play:
        • Neutralize fields by bringing their charge to zero
        • Place + and - magnets on the grid to influence charges
        • Each magnet has influence: 3 in its cell, 2 adjacent, 1 two spaces away
        • Tap once to preview influence, tap again to place
        """
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .left
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.backgroundColor = .white
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 60),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    */
    // MARK: - Action Handlers
    
    @objc private func cellTapped(_ gesture: UITapGestureRecognizer) {
        guard let cellView = gesture.view as? CellView else { return }
        
        // Extract row and column from tag
        let row = cellView.tag / 100
        let col = cellView.tag % 100
        
        // If the cell already has a magnet, remove it (double-tap behavior)
        if viewModel.gameState.grid[row][col].magnetValue != 0 {
            // Call a method to just remove the magnet
            removeMagnet(at: row, col: col)
            return
        }
        
        // Check if cell is already selected
        if viewModel.gameState.grid[row][col].isSelected {
            // Second tap - place the magnet
            viewModel.placeOrRemoveMagnet(at: row, col: col)
            
            // Clear all influence previews
            clearAllInfluencePreviews()
        } else {
            // First tap - select the cell
            viewModel.selectCell(at: row, col: col)
            
            // Show influence preview
            showInfluencePreview(row: row, col: col)
        }
    }
    
    private func removeMagnet(at row: Int, col: Int) {
        let currentValue = viewModel.gameState.grid[row][col].magnetValue
        
        // Return the magnet to available magnets
        if currentValue == 1 {
            viewModel.gameState.availableMagnets.positive += 1
        } else if currentValue == -1 {
            viewModel.gameState.availableMagnets.negative += 1
        }
        
        // Remove the magnet
        viewModel.gameState.grid[row][col].magnetValue = 0
        
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
    
    // Show influence preview for the selected cell
    private func showInfluencePreview(row: Int, col: Int) {
        // Clear previous previews
        clearAllInfluencePreviews()
        
        // Get influence area
        let influenceArea = viewModel.getInfluenceArea(for: row, col: col)
        let magnetType = viewModel.gameState.selectedMagnetType
        
        // Skip if eraser is selected
        if magnetType == 0 {
            return
        }
        
        for r in 0..<influenceArea.count {
            for c in 0..<influenceArea[r].count {
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
        // Set the selected magnet type
        viewModel.gameState.selectedMagnetType = sender.magnetType
        
        // Update button appearance
        positiveButton.configure(type: 1, count: viewModel.gameState.availableMagnets.positive, isSelected: viewModel.gameState.selectedMagnetType == 1)
        negativeButton.configure(type: -1, count: viewModel.gameState.availableMagnets.negative, isSelected: viewModel.gameState.selectedMagnetType == -1)
        
        // Update cell views
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
        updateHintsButton()
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
        
        // Change background color when showing solution
        solutionButton.backgroundColor = viewModel.gameState.showSolution
            ? UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1.0) // Darker purple
            : UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 1.0) // Regular purple
    }
    
    private func updateHintsButton() {
        hintsButton.setTitle(viewModel.gameState.showHints ? "Hide Hints" : "Show Hints", for: .normal)
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
        
        // Update progress label
        progressLabel.text = "\(neutralizedCells) / \(totalTargetCells) fields neutralized"
    }
    
    // MARK: - GameStateDelegate Methods
    
    func gameStateDidChange() {
        updateUI()
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

extension GameViewController {
    // Any additional helper methods can go here
}
