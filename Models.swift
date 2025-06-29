//
//  Models.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - Models

enum MagnetType: String, CaseIterable, Codable {
    case standard = "standard"    // Current + pattern (3,2,1)
    case diagonal = "diagonal"    // X pattern (3,2,1 on diagonals)
    
    var displayName: String {
        switch self {
        case .standard: return "Field Stabilizer"
        case .diagonal: return "Diagonal Resonator"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "plus"
        case .diagonal: return "xmark"
        }
    }
}

// Represents a cell on the grid
struct MagnetCell {
    // -1 for negative, 0 for none, 1 for positive
    var toolEffect: Int = 0
    // Define magnet type, initial is standard cross pattern
    var magnetType: MagnetType = .standard
    // Initial charge to be neutralized (non-zero means this is a target cell)
    var initialCharge: Int = 0
    // Current calculated field value
    var currentFieldValue: Int = 0
    // Whether this cell can have a magnet placed on it
    var placeable: Bool = true
    // First tap selects the cell, second tap confirms placement
    var isSelected: Bool = false
    
    // Computed property to determine if the cell is neutralized
    var isNeutralized: Bool {
        return initialCharge != 0 && currentFieldValue == 0
    }
    
    // Computed property to determine if values overshot (went past zero)
    var isOvershot: Bool {
        // Only applies to target cells (with an initial charge)
        guard initialCharge != 0 else { return false }
        
        // Check if signs are different (crossed over zero)
        return (initialCharge > 0 && currentFieldValue < 0) || (initialCharge < 0 && currentFieldValue > 0)
    }
    
    // Computed property to get remaining charge to be neutralized
    var remainingCharge: Int {
        return initialCharge != 0 ? currentFieldValue : 0
    }
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
    init(gridSize: Int, initialCharges: [[Int]], solution: [[Int]], placeableGrid: [[Bool]]? = nil, positiveMagnets: Int = 3, negativeMagnets: Int = 3) {
        // Initialize grid
        var initialGrid = Array(repeating: Array(repeating: MagnetCell(), count: gridSize), count: gridSize)
        
        // Set initial charges
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if row < initialCharges.count && col < initialCharges[row].count {
                    initialGrid[row][col].initialCharge = initialCharges[row][col]
                    initialGrid[row][col].currentFieldValue = initialCharges[row][col]
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
    let initialCharges: [[Int]]
    let solution: [[Int]]
    let placeableGrid: [[Bool]]?
    let positiveMagnets: Int
    let negativeMagnets: Int
    let magnetType: MagnetType
    
    // Static function to create the Z pattern puzzle from the original code
    static func zPatternPuzzle() -> PuzzleDefinition {
        let gridSize = 5
        
        // Define the initial charges for each cell (0 means not a target cell)
        let initialCharges = [
            [-4, -2, 1, 2, 2],
            [0, -4, 0, 2, 0],
            [0, 0, 4, 0, 0],
            [0, 0, 0, 0, 0],
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
            initialCharges: initialCharges,
            solution: solution,
            placeableGrid: placeableGrid,
            positiveMagnets: 3,
            negativeMagnets: 3,
            magnetType: .standard
        )
    }
    
    // Generate a random puzzle
    static func generateRandomPuzzle(gridSize: Int = 5, difficulty: String = "medium", positiveMagnets: Int = 3, negativeMagnets: Int = 3, magnetType: MagnetType = .standard) -> PuzzleDefinition {
        return PuzzleGenerator.generateRandomPuzzle(
            gridSize: gridSize,
            difficulty: difficulty,
            positiveMagnets: positiveMagnets,
            negativeMagnets: negativeMagnets
        )
    }
}

extension PuzzleDefinition {
    static func tutorialPuzzle() -> PuzzleDefinition {
        let gridSize = 3
        
        // Very simple puzzle for tutorial
        let targetValues = [
            [-3, 0, 0],
            [0, 0, 0],
            [0, 0, 3]
        ]
        
        // The solution
        let solution = [
            [-1, 0, 0],
            [0, 0, 0],
            [0, 0, 1]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: targetValues,
            solution: solution,
            placeableGrid: nil,
            positiveMagnets: 1,
            negativeMagnets: 1,
            magnetType: .standard
        )
    }
    
    // Tutorial Level 2: Overlapping Fields
    static func overlappingFieldsPuzzle() -> PuzzleDefinition {
        let gridSize = 4
        
        // Puzzle with two separate overlapping field challenges
        let targetValues = [
            [0, -2, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 3],
            [0, -1, 0, 2]
        ]
        
        // Solution:
        // Stabilizer at (1,1) affects (0,1) with +2 and (3,1) with +1
        // Suppressor at (2,3) affects (2,3) with -3 and (3,3) with -2
        let solution = [
            [0, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, -1],
            [0, 0, 0, 0]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: targetValues,
            solution: solution,
            placeableGrid: nil,
            positiveMagnets: 1,
            negativeMagnets: 1,
            magnetType: .standard
        )
    }
    
    // Tutorial Level 3: Correction Protocols (Overshoot Learning)
    static func correctionProtocolsPuzzle() -> PuzzleDefinition {
        let gridSize = 3
        
        // Plus-sign pattern that encourages overshoot learning
        let targetValues = [
            [-3, -1, 0],
            [-2, 0, 0],
            [1, 0, 0]
        ]
        
        // Solution requires strategic thinking about overshoot
        let solution = [
            [1, 0, 0],
            [0, 0, 0],
            [0, -1, 0]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: targetValues,
            solution: solution,
            placeableGrid: nil,
            positiveMagnets: 1,
            negativeMagnets: 1,
            magnetType: .standard
        )
    }
    
    // Tutorial Level 4: Resource Management
    static func resourceManagementPuzzle() -> PuzzleDefinition {
        let gridSize = 5
        
        let targetValues = [
            [-3, 0, 0, 0, 0],
            [0, 4, 0, 0, 0],
            [-2, 2, -3, 0, 0],
            [2, 4, 0, 0, 0],
            [0, 2, -1, 0, 0]
        ]
        
        let solution = [
            [1, 0, 0, 0, 0],
            [0, -1, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, -1, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: targetValues,
            solution: solution,
            placeableGrid: nil,
            positiveMagnets: 2,
            negativeMagnets: 2,
            magnetType: .standard
        )
    }
    
    // Tutorial Level 5: Resource Management
    static func patternsIdentificationPuzzle() -> PuzzleDefinition {
        let gridSize = 5
        
        let targetValues = [
            [-3, 0, -1, -2, 0],
            [0, 0, -2, 0, -2],
            [-1, 0, 0, -2, 0],
            [0, 0, 0, 0, 0],
            [0, 3, 2, 1, 0]
        ]
        
        // Efficient solution using minimal tools
        let solution = [
            [1, 0, 0, 0, 0],
            [0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, -1, 0, 0, 0]
        ]
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: targetValues,
            solution: solution,
            placeableGrid: nil,
            positiveMagnets: 2,
            negativeMagnets: 1,
            magnetType: .standard
        )
    }
}
