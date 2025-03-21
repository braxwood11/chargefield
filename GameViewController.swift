//
//  GameViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, GameStateDelegate {
    
    // MARK: - Properties
    
    private var viewModel: GameViewModel!
    private var cellViews: [[CellView]] = []
    private var gridView: UIView!
    
    private var positiveButton: MagnetButton!
    private var negativeButton: MagnetButton!
    private var eraserButton: MagnetButton!
    
    private var resetButton: UIButton!
    private var solutionButton: UIButton!
    private var hintsButton: UIButton!
    
    private var messageView: MessageView!
    private var instructionLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Create message view (initially hidden)
        messageView = MessageView(frame: .zero)
        messageView.setMessage("🎉 Puzzle Solved! Well done! 🎉")
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.isHidden = true
        view.addSubview(messageView)
        
        // Create magnet selection buttons
        setupMagnetButtons()
        
        // Create grid
        setupGrid()
        
        // Create control buttons
        setupControlButtons()
        
        // Create instructions
        setupInstructions()
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Message view
            messageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Magnet selection container
            positiveButton.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 20),
            positiveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            positiveButton.widthAnchor.constraint(equalToConstant: 80),
            positiveButton.heightAnchor.constraint(equalToConstant: 80),
            
            negativeButton.topAnchor.constraint(equalTo: positiveButton.topAnchor),
            negativeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            negativeButton.widthAnchor.constraint(equalToConstant: 80),
            negativeButton.heightAnchor.constraint(equalToConstant: 80),
            
            eraserButton.topAnchor.constraint(equalTo: positiveButton.topAnchor),
            eraserButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            eraserButton.widthAnchor.constraint(equalToConstant: 80),
            eraserButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Grid
            gridView.topAnchor.constraint(equalTo: positiveButton.bottomAnchor, constant: 20),
            gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridView.widthAnchor.constraint(equalToConstant: 300),
            gridView.heightAnchor.constraint(equalToConstant: 300),
            
            // Control buttons
            resetButton.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 20),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 40),
            
            solutionButton.topAnchor.constraint(equalTo: resetButton.topAnchor),
            solutionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            solutionButton.widthAnchor.constraint(equalToConstant: 120),
            solutionButton.heightAnchor.constraint(equalToConstant: 40),
            
            hintsButton.topAnchor.constraint(equalTo: resetButton.topAnchor),
            hintsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            hintsButton.widthAnchor.constraint(equalToConstant: 80),
            hintsButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Instructions
            instructionLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
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
        
        // Eraser button
        eraserButton = MagnetButton(frame: .zero)
        eraserButton.configure(type: 0, isSelected: viewModel.gameState.selectedMagnetType == 0)
        eraserButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
        eraserButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eraserButton)
    }
    
    private func setupGrid() {
        // Create container for the grid
        gridView = UIView(frame: .zero)
        gridView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        gridView.layer.cornerRadius = 8
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        // Calculate cell size based on grid size
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
    
    private func setupControlButtons() {
            // Reset button
            resetButton = UIButton(type: .system)
            resetButton.setTitle("Reset", for: .normal)
            resetButton.backgroundColor = .gray
            resetButton.setTitleColor(.white, for: .normal)
            resetButton.layer.cornerRadius = 8
            resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
            resetButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(resetButton)
            
            // Solution button
            solutionButton = UIButton(type: .system)
            solutionButton.setTitle("Show Solution", for: .normal)
            solutionButton.backgroundColor = .blue
            solutionButton.setTitleColor(.white, for: .normal)
            solutionButton.layer.cornerRadius = 8
            solutionButton.addTarget(self, action: #selector(solutionButtonTapped), for: .touchUpInside)
            solutionButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(solutionButton)
            
            // Hints button
            hintsButton = UIButton(type: .system)
            hintsButton.setTitle("Show Hints", for: .normal)
            hintsButton.backgroundColor = .purple
            hintsButton.setTitleColor(.white, for: .normal)
            hintsButton.layer.cornerRadius = 8
            hintsButton.addTarget(self, action: #selector(hintsButtonTapped), for: .touchUpInside)
            hintsButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hintsButton)
            
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
                newPuzzleButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 8),
                newPuzzleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                newPuzzleButton.widthAnchor.constraint(equalToConstant: 120),
                newPuzzleButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
    
    private func setupInstructions() {
        instructionLabel = UILabel()
        instructionLabel.text = """
        How To Play:
        • Place positive (+) and negative (-) magnets on the grid
        • Each magnet has influence: 3 in its cell, 2 adjacent, 1 two spaces away
        • Match each target cell's exact value
        • Tap once to preview, tap again to place
        • You have 3 positive and 3 negative magnets
        """
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .left
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.backgroundColor = .white
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
    }
    
    // MARK: - Action Handlers
    
    @objc private func cellTapped(_ gesture: UITapGestureRecognizer) {
            guard let cellView = gesture.view as? CellView else { return }
            
            // Extract row and column from tag
            let row = cellView.tag / 100
            let col = cellView.tag % 100
            
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
            // Generate a new random puzzle with the selected difficulty
            let puzzle = PuzzleDefinition.generateRandomPuzzle(difficulty: difficulty)
            
            // Create a new view model with the puzzle
            viewModel = GameViewModel(puzzle: puzzle)
            viewModel.delegate = self
            
            // Remove existing cell views
            for subview in gridView.subviews {
                subview.removeFromSuperview()
            }
            
            // Clear cell views array
            cellViews.removeAll()
            
            // Create new grid
            setupGrid()
            
            // Update UI
            updateUI()
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
            
            for r in 0..<influenceArea.count {
                for c in 0..<influenceArea[r].count {
                    if influenceArea[r][c] {
                        // Calculate influence intensity based on distance
                        let distance = max(abs(r - row), abs(c - col))
                        
                        let intensity: Int
                        if distance == 0 {
                            intensity = 3 // Own cell
                        } else if distance == 1 {
                            intensity = 2 // Adjacent cell
                        } else {
                            intensity = 1 // Two spaces away
                        }
                        
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
        viewModel.gameState.selectedMagnetType = sender.magnetType
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
        updateHintsButton()
        updateCellViews()
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        updateMagnetButtons()
        updateCellViews()
        updateSolutionButton()
        updateHintsButton()
        updateMessageView()
    }
    
    private func updateMagnetButtons() {
        positiveButton.configure(type: 1, count: viewModel.gameState.availableMagnets.positive, isSelected: viewModel.gameState.selectedMagnetType == 1)
        negativeButton.configure(type: -1, count: viewModel.gameState.availableMagnets.negative, isSelected: viewModel.gameState.selectedMagnetType == -1)
        eraserButton.configure(type: 0, isSelected: viewModel.gameState.selectedMagnetType == 0)
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
        solutionButton.setTitle(viewModel.gameState.showSolution ? "Hide Solution" : "Show Solution", for: .normal)
    }
    
    private func updateHintsButton() {
        hintsButton.setTitle(viewModel.gameState.showHints ? "Hide Hints" : "Show Hints", for: .normal)
    }
    
    private func updateMessageView() {
        messageView.isHidden = !(viewModel.gameState.puzzleSolved && !viewModel.gameState.showSolution)
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
    }
}

// MARK: - Extension for any additional functionality

extension GameViewController {
    // Any additional helper methods can go here
}
