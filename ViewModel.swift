//
//  ViewModel.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - ViewModel

protocol GameStateDelegate: AnyObject {
    func gameStateDidChange()
    func puzzleSolved()
}

class GameViewModel {
    var gameState: PuzzleState
    private let gridSize: Int
    weak var delegate: GameStateDelegate?
    
    // Store the total magnets available for this puzzle
    private let totalPositiveMagnets: Int
    private let totalNegativeMagnets: Int
    
    init(puzzle: PuzzleDefinition) {
        self.gridSize = puzzle.gridSize
        self.gameState = PuzzleState(
            gridSize: puzzle.gridSize,
            initialCharges: puzzle.initialCharges,
            solution: puzzle.solution,
            placeableGrid: puzzle.placeableGrid,
            positiveMagnets: puzzle.positiveMagnets,
            negativeMagnets: puzzle.negativeMagnets
        )
        
        // Store the total magnets for this puzzle
        self.totalPositiveMagnets = puzzle.positiveMagnets
        self.totalNegativeMagnets = puzzle.negativeMagnets
        
        // Calculate initial field values
        updateFieldValues()
    }
    
    // Calculate field values based on magnet placements
    func updateFieldValues() {
        // Start with initial charges
        var fieldValues = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        
        // Copy the initial charges to the field values
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                fieldValues[row][col] = gameState.grid[row][col].initialCharge
            }
        }
        
        // For each magnet, calculate its influence on all cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let magnetValue = gameState.grid[row][col].toolEffect
                if magnetValue != 0 {
                    // Add the magnet's own value to its cell
                    fieldValues[row][col] += magnetValue * 3  // Strength at its own position
                    
                    // Affect the row
                    for c in 0..<gridSize {
                        if c != col {
                            // Calculate distance
                            let distance = abs(c - col)
                            // Influence is 2 at distance 1, 1 at distance 2, 0 beyond
                            var influence = 0
                            if distance == 1 {
                                influence = 2 * magnetValue
                            } else if distance == 2 {
                                influence = 1 * magnetValue
                            }
                            
                            fieldValues[row][c] += influence
                        }
                    }
                    
                    // Affect the column
                    for r in 0..<gridSize {
                        if r != row {
                            // Calculate distance
                            let distance = abs(r - row)
                            // Influence is 2 at distance 1, 1 at distance 2, 0 beyond
                            var influence = 0
                            if distance == 1 {
                                influence = 2 * magnetValue
                            } else if distance == 2 {
                                influence = 1 * magnetValue
                            }
                            
                            fieldValues[r][col] += influence
                        }
                    }
                }
            }
        }
        
        // Update the current field values in the grid
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].currentFieldValue = fieldValues[row][col]
            }
        }
        
        // Check if puzzle is solved
        checkSolution()
        
        // Notify delegate
        delegate?.gameStateDidChange()
    }
    
    // Check if the puzzle is solved
    func checkSolution() {
        let wasSolved = gameState.puzzleSolved
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let initialCharge = gameState.grid[row][col].initialCharge
                let currentValue = gameState.grid[row][col].currentFieldValue
                
                // Only cells with initial charge (non-zero) need to be neutralized
                if initialCharge != 0 && currentValue != 0 {
                    gameState.puzzleSolved = false
                    return
                }
            }
        }
        
        gameState.puzzleSolved = true
        
        // Notify delegate if puzzle was just solved
        if !wasSolved && gameState.puzzleSolved {
            delegate?.puzzleSolved()
        }
    }
    
    // Handle cell selection (first tap)
    func selectCell(at row: Int, col: Int) {
        // Clear any previously selected cells
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                gameState.grid[r][c].isSelected = false
            }
        }
        
        // Select this cell if it's placeable
        if gameState.grid[row][col].placeable {
            gameState.grid[row][col].isSelected = true
        }
        
        // Notify delegate
        delegate?.gameStateDidChange()
    }
    
    // Handle cell placement (second tap)
    func placeOrRemoveMagnet(at row: Int, col: Int) {
        guard gameState.grid[row][col].placeable else { return }
        guard !gameState.puzzleSolved || gameState.showSolution else { return }
        
        let currentValue = gameState.grid[row][col].toolEffect
        
        // If eraser is selected, remove any magnet
        if gameState.selectedMagnetType == 0 && currentValue != 0 {
            if currentValue == 1 {
                gameState.availableMagnets.positive += 1
            } else if currentValue == -1 {
                gameState.availableMagnets.negative += 1
            }
            gameState.grid[row][col].toolEffect = 0
        }
        // If positive magnet is selected
        else if gameState.selectedMagnetType == 1 && currentValue != 1 {
            // Check if we have available positive magnets
            if gameState.availableMagnets.positive <= 0 { return }
            
            // If there was a negative magnet, give it back
            if currentValue == -1 {
                gameState.availableMagnets.negative += 1
            }
            
            gameState.availableMagnets.positive -= 1
            gameState.grid[row][col].toolEffect = 1
        }
        // If negative magnet is selected
        else if gameState.selectedMagnetType == -1 && currentValue != -1 {
            // Check if we have available negative magnets
            if gameState.availableMagnets.negative <= 0 { return }
            
            // If there was a positive magnet, give it back
            if currentValue == 1 {
                gameState.availableMagnets.positive += 1
            }
            
            gameState.availableMagnets.negative -= 1
            gameState.grid[row][col].toolEffect = -1
        }
        
        // Clear selection after placement (important!)
        gameState.grid[row][col].isSelected = false
        
        // Update field values
        updateFieldValues()
    }
    
    // Reset the puzzle
    func resetPuzzle() {
        // Reset magnets
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].toolEffect = 0
                gameState.grid[row][col].isSelected = false
                // Reset current field value to initial charge
                gameState.grid[row][col].currentFieldValue = gameState.grid[row][col].initialCharge
            }
        }
        
        // Reset available magnets to their original values
        gameState.availableMagnets = (positive: totalPositiveMagnets, negative: totalNegativeMagnets)
        gameState.puzzleSolved = false
        gameState.showSolution = false
        
        // Update field values
        updateFieldValues()
    }
    
    // Show solution
    func toggleSolution() {
        if gameState.showSolution {
            resetPuzzle()
        } else {
            // Simply apply the INVERTED solution magnets to neutralize the initial charges
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if row < gameState.solution.count && col < gameState.solution[row].count {
                        // Invert the magnet value from the solution
                        let invertedMagnetValue = -gameState.solution[row][col]
                        gameState.grid[row][col].toolEffect = invertedMagnetValue
                    }
                }
            }
            
            // Update available magnets (count the inverted values)
            let positiveCount = gameState.solution.flatMap { $0 }.filter { $0 == -1 }.count // Count original negatives as new positives
            let negativeCount = gameState.solution.flatMap { $0 }.filter { $0 == 1 }.count  // Count original positives as new negatives
            gameState.availableMagnets = (positive: totalPositiveMagnets - positiveCount, negative: totalNegativeMagnets - negativeCount)
            
            gameState.showSolution = true
            updateFieldValues()
        }
    }
    
    // Toggle hints
    func toggleHints() {
        gameState.showHints.toggle()
        delegate?.gameStateDidChange()
    }
    
    // Calculate influence preview for selected cells
    func getInfluenceArea(for row: Int, col: Int) -> [[Bool]] {
        var influence = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        
        // Mark the cell itself
        influence[row][col] = true
        
        // Mark the row
        for c in 0..<gridSize {
            if c != col {
                let distance = abs(c - col)
                if distance <= 2 {
                    influence[row][c] = true
                }
            }
        }
        
        // Mark the column
        for r in 0..<gridSize {
            if r != row {
                let distance = abs(r - row)
                if distance <= 2 {
                    influence[r][col] = true
                }
            }
        }
        
        return influence
    }
    
    func getInfluenceIntensity(from sourceRow: Int, sourceCol: Int, to targetRow: Int, targetCol: Int) -> Int {
        // Calculate Manhattan distance
        let rowDistance = abs(targetRow - sourceRow)
        let colDistance = abs(targetCol - sourceCol)
        
        // Check if in same row or column
        if sourceRow == targetRow || sourceCol == targetCol {
            let distance = max(rowDistance, colDistance)
            
            if distance == 0 {
                return 3 // Own cell - this is crucial
            } else if distance == 1 {
                return 2 // Adjacent cell
            } else if distance == 2 {
                return 1 // Two cells away
            }
        }
        
        return 0 // No influence
    }
    
    // Get the numerical impact a magnet would have if placed
    func getInfluenceValue(at row: Int, col: Int, magnetType: Int) -> Int {
        switch magnetType {
        case 1:  // Positive magnet
            return 3  // Own cell gets +3
        case -1: // Negative magnet
            return -3 // Own cell gets -3
        default:
            return 0
        }
    }
    
    // Get the numerical impact on a cell from a magnet placed elsewhere
    func getInfluenceValue(from sourceRow: Int, sourceCol: Int, to targetRow: Int, targetCol: Int, magnetType: Int) -> Int {
        let intensity = getInfluenceIntensity(from: sourceRow, sourceCol: sourceCol, to: targetRow, targetCol: targetCol)
        return intensity * magnetType
    }
    
    // Clear all cell selections
    func clearAllSelections() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].isSelected = false
            }
        }
        
        // Notify delegate
        delegate?.gameStateDidChange()
    }
    
    // Get the percentage of neutralization for a cell
    func getNeutralizationPercentage(at row: Int, col: Int) -> Double {
        let initialCharge = gameState.grid[row][col].initialCharge
        let currentValue = gameState.grid[row][col].currentFieldValue
        
        // If not a target cell or initial charge is 0, return 0
        if initialCharge == 0 {
            return 0.0
        }
        
        // If neutralized, return 1.0 (100%)
        if currentValue == 0 {
            return 1.0
        }
        
        // If overshot (crossed zero), return a value > 1.0
        if (initialCharge > 0 && currentValue < 0) || (initialCharge < 0 && currentValue > 0) {
            return 1.2
        }
        
        // Calculate progress toward neutralization
        let progress = 1.0 - (Double(abs(currentValue)) / Double(abs(initialCharge)))
        return max(0.0, min(1.0, progress))
    }
}
