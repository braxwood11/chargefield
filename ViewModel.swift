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
            targetValues: puzzle.targetValues,
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
        // Create a new grid of zeros
        var fieldValues = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        
        // For each magnet, calculate its influence on all cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let magnetValue = gameState.grid[row][col].magnetValue
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
                    let targetValue = gameState.grid[row][col].targetValue
                    let currentValue = gameState.grid[row][col].currentFieldValue
                    
                    if targetValue != -99 && currentValue != targetValue {
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
            
            let currentValue = gameState.grid[row][col].magnetValue
            
            // If eraser is selected, remove any magnet
            if gameState.selectedMagnetType == 0 && currentValue != 0 {
                if currentValue == 1 {
                    gameState.availableMagnets.positive += 1
                } else if currentValue == -1 {
                    gameState.availableMagnets.negative += 1
                }
                gameState.grid[row][col].magnetValue = 0
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
                gameState.grid[row][col].magnetValue = 1
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
                gameState.grid[row][col].magnetValue = -1
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
                    gameState.grid[row][col].magnetValue = 0
                    gameState.grid[row][col].isSelected = false
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
            // Apply solution
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if row < gameState.solution.count && col < gameState.solution[row].count {
                        gameState.grid[row][col].magnetValue = gameState.solution[row][col]
                    }
                }
            }
            
            // Update available magnets
            let positiveCount = gameState.solution.flatMap { $0 }.filter { $0 == 1 }.count
            let negativeCount = gameState.solution.flatMap { $0 }.filter { $0 == -1 }.count
            gameState.availableMagnets = (positive: 3 - positiveCount, negative: 3 - negativeCount)
            
            gameState.showSolution = true
            
            // Update field values
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
    
    // Calculate intensity of influence at a specific position
       func getInfluenceIntensity(from sourceRow: Int, sourceCol: Int, to targetRow: Int, targetCol: Int) -> Int {
           // Calculate Manhattan distance
           let rowDistance = abs(targetRow - sourceRow)
           let colDistance = abs(targetCol - sourceCol)
           
           // Check if in same row or column
           if sourceRow == targetRow || sourceCol == targetCol {
               let distance = max(rowDistance, colDistance)
               
               if distance == 0 {
                   return 3 // Own cell
               } else if distance == 1 {
                   return 2 // Adjacent cell
               } else if distance == 2 {
                   return 1 // Two cells away
               }
           }
           
           return 0 // No influence
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

}
