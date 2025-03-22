//
//  Models.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - Models

// Represents a cell on the grid
struct MagnetCell {
    // -1 for negative, 0 for none, 1 for positive
    var magnetValue: Int = 0
    // -99 means no target, other values are the target field value
    var targetValue: Int = -99
    // Current calculated field value
    var currentFieldValue: Int = 0
    // Whether this cell can have a magnet placed on it
    var placeable: Bool = true
    // First tap selects the cell, second tap confirms placement
    var isSelected: Bool = false
}

// Represents the game state
struct PuzzleState {
    // Grid of cells
    var grid: [[MagnetCell]]
    // Available magnets
    var availableMagnets: (positive: Int, negative: Int)
    // Currently selected magnet type (-1, 0, 1)
    var selectedMagnetType: Int
    // Whether the puzzle is solved
    var puzzleSolved: Bool
    // Whether to show hints
    var showHints: Bool
    // Whether to show the solution
    var showSolution: Bool
    // The known solution for this puzzle
    var solution: [[Int]]
    
    // Initialize a new puzzle with the given parameters
    init(gridSize: Int, targetValues: [[Int]], solution: [[Int]], placeableGrid: [[Bool]]? = nil, positiveMagnets: Int = 3, negativeMagnets: Int = 3) {
        // Initialize grid
        var initialGrid = Array(repeating: Array(repeating: MagnetCell(), count: gridSize), count: gridSize)
        
        // Set target values
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if row < targetValues.count && col < targetValues[row].count {
                    initialGrid[row][col].targetValue = targetValues[row][col]
                }
                
                // Set placeable status if provided
                if let placeableGrid = placeableGrid, row < placeableGrid.count && col < placeableGrid[row].count {
                    initialGrid[row][col].placeable = placeableGrid[row][col]
                }
            }
        }
        
        self.grid = initialGrid
        self.availableMagnets = (positive: positiveMagnets, negative: negativeMagnets)
        self.selectedMagnetType = 1  // Default to positive
        self.puzzleSolved = false
        self.showHints = false
        self.showSolution = false
        self.solution = solution
    }
}

// MARK: - Puzzle Definitions

struct PuzzleDefinition {
    let gridSize: Int
    let targetValues: [[Int]]
    let solution: [[Int]]
    let placeableGrid: [[Bool]]?
    let positiveMagnets: Int
    let negativeMagnets: Int
    
    // Static function to create the Z pattern puzzle from the original code
    static func zPatternPuzzle() -> PuzzleDefinition {
        let gridSize = 5
        
        // Define the target values for each cell (-99 means no target)
        let targetValues = [
            [-4, -2, 1, 2, 2],
            [-99, -4, -99, 2, -99],
            [-99, -99, 4, -99, -99],
            [-99, 0, -99, -99, -99],
            [1, 2, 4, 2, -1]
        ]
        
        // All cells are placeable
        let placeableGrid = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)
        
        // The verified solution
        let solution = [
            [0, -1, 0, 1, 0],
            [-1, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, -1],
            [0, 0, 1, 0, 0]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            targetValues: targetValues,
            solution: solution,
            placeableGrid: placeableGrid,
            positiveMagnets: 3,
            negativeMagnets: 3
        )
    }
    
    // Generate a random puzzle
        static func generateRandomPuzzle(gridSize: Int = 5, difficulty: String = "medium", positiveMagnets: Int = 3, negativeMagnets: Int = 3) -> PuzzleDefinition {
            return PuzzleGenerator.generateRandomPuzzle(
                gridSize: gridSize,
                difficulty: difficulty,
                positiveMagnets: positiveMagnets,
                negativeMagnets: negativeMagnets
            )
        }
}
