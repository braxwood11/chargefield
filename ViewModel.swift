//
//  ViewModel.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - Game State Delegate
protocol GameStateDelegate: AnyObject {
    func gameStateDidChange()
    func puzzleSolved()
}

// MARK: - Game View Model
class GameViewModel {
    
    // MARK: - Properties
    private(set) var gameState: PuzzleState
    private let gridSize: Int
    private let fieldCalculator: FieldCalculator
    private let totalPositiveMagnets: Int
    private let totalNegativeMagnets: Int
    private let puzzleMagnetType: MagnetType
    
    weak var delegate: GameStateDelegate?

    // MARK: - Validation Methods
    func canPlaceMagnet(type: Int, at row: Int, col: Int) -> Bool {
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else {
            return false
        }
        
        guard let cell = getCellAt(row: row, col: col) else {
            return false
        }
        
        // Check if cell is placeable
        guard cell.placeable else { return false }
        
        // Check if puzzle is already solved (unless showing solution)
        guard !gameState.puzzleSolved || gameState.showSolution else { return false }
        
        // Check magnet availability based on type
        switch type {
        case 1: // Positive magnet
            return gameState.availableMagnets.positive > 0
        case -1: // Negative magnet
            return gameState.availableMagnets.negative > 0
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    init(puzzle: PuzzleDefinition) {
        self.gridSize = puzzle.gridSize
        self.totalPositiveMagnets = puzzle.positiveMagnets
        self.totalNegativeMagnets = puzzle.negativeMagnets
        self.puzzleMagnetType = puzzle.magnetType
        
        print("DEBUG: GameViewModel initialized with magnetType: \(self.puzzleMagnetType)")
        
        // Initialize field calculator
        self.fieldCalculator = FieldCalculatorFactory.getCalculator(for: puzzle.gridSize)
        
        // Initialize game state
        self.gameState = PuzzleState(
            gridSize: puzzle.gridSize,
            initialCharges: puzzle.initialCharges,
            solution: puzzle.solution,
            placeableGrid: puzzle.placeableGrid,
            positiveMagnets: puzzle.positiveMagnets,
            negativeMagnets: puzzle.negativeMagnets
        )
        
        // Calculate initial field values
        updateFieldValues()
    }
    
    // MARK: - Field Calculation
    func updateFieldValues() {
        // Extract current magnet placements
        var magnets: [[Int]] = []
        for row in gameState.grid {
            magnets.append(row.map { $0.toolEffect })
        }
        
        // Extract initial charges
        var initialCharges: [[Int]] = []
        for row in gameState.grid {
            initialCharges.append(row.map { $0.initialCharge })
        }
        
        // Calculate field values using the optimized calculator
        let fieldValues = fieldCalculator.calculateAllFieldValues(
            initialCharges: initialCharges,
            magnets: magnets,
            magnetType: puzzleMagnetType
        )
        
        // Update grid with calculated values
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].currentFieldValue = fieldValues[row][col]
            }
        }
        
        // Check solution and notify delegate
        checkSolution()
        delegate?.gameStateDidChange()
    }
    
    // MARK: - Solution Checking
    private func checkSolution() {
        let wasSolved = gameState.puzzleSolved
        var allNeutralized = true
        
        // Check all target cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = gameState.grid[row][col]
                
                // Only cells with initial charge need to be neutralized
                if cell.initialCharge != 0 && cell.currentFieldValue != 0 {
                    allNeutralized = false
                    break
                }
            }
            if !allNeutralized { break }
        }
        
        gameState.puzzleSolved = allNeutralized
        
        // Notify delegate if puzzle was just solved
        if !wasSolved && gameState.puzzleSolved {
            delegate?.puzzleSolved()
        }
    }
    
    // MARK: - Cell Selection
    func selectCell(at row: Int, col: Int) {
        // Clear previous selections
        clearAllSelections()
        
        // Select new cell if placeable
        if gameState.grid[row][col].placeable {
            gameState.grid[row][col].isSelected = true
            delegate?.gameStateDidChange()
        }
    }
    
    func clearAllSelections() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].isSelected = false
            }
        }
        delegate?.gameStateDidChange()
    }
    
    // MARK: - Magnet Placement
    func placeOrRemoveMagnet(at row: Int, col: Int) {
        guard gameState.grid[row][col].placeable else { return }
        guard !gameState.puzzleSolved || gameState.showSolution else { return }
        
        let currentValue = gameState.grid[row][col].toolEffect
        let oldMagnet = currentValue
        var newMagnet = 0
        
        // Handle eraser mode
        if gameState.selectedMagnetType == 0 && currentValue != 0 {
            // Return magnet to inventory
            if currentValue == 1 {
                gameState.availableMagnets.positive += 1
            } else if currentValue == -1 {
                gameState.availableMagnets.negative += 1
            }
            gameState.grid[row][col].toolEffect = 0
            newMagnet = 0
        }
        // Handle positive magnet placement
        else if gameState.selectedMagnetType == 1 && currentValue != 1 {
            guard gameState.availableMagnets.positive > 0 else { return }
            
            // Return existing magnet if any
            if currentValue == -1 {
                gameState.availableMagnets.negative += 1
            }
            
            gameState.availableMagnets.positive -= 1
            gameState.grid[row][col].toolEffect = 1
            newMagnet = 1
        }
        // Handle negative magnet placement
        else if gameState.selectedMagnetType == -1 && currentValue != -1 {
            guard gameState.availableMagnets.negative > 0 else { return }
            
            // Return existing magnet if any
            if currentValue == 1 {
                gameState.availableMagnets.positive += 1
            }
            
            gameState.availableMagnets.negative -= 1
            gameState.grid[row][col].toolEffect = -1
            newMagnet = -1
        }
        
        // Clear selection
        gameState.grid[row][col].isSelected = false
        
        // Update field values efficiently
        if oldMagnet != newMagnet {
            updateFieldValueForMagnetChange(
                at: GridPosition(row: row, col: col),
                oldMagnet: oldMagnet,
                newMagnet: newMagnet
            )
        }
    }
    
    func getCurrentMagnetType() -> MagnetType {
            return puzzleMagnetType
        }
    
    private func updateFieldValueForMagnetChange(at position: GridPosition, oldMagnet: Int, newMagnet: Int) {
        // Extract initial charges
        var initialCharges: [[Int]] = []
        for row in gameState.grid {
            initialCharges.append(row.map { $0.initialCharge })
        }
        
        // Use optimized field calculator with the correct magnet type
        let fieldValues = fieldCalculator.updateFieldValue(
            at: position,
            oldMagnet: oldMagnet,
            newMagnet: newMagnet,
            initialCharges: initialCharges,
            magnetType: puzzleMagnetType  // Add this parameter
        )
        
        // Update grid
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].currentFieldValue = fieldValues[row][col]
            }
        }
        
        // Check solution
        checkSolution()
        delegate?.gameStateDidChange()
    }
    
    // MARK: - Reset & Solution
    func resetPuzzle() {
        // Clear all magnets
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                gameState.grid[row][col].toolEffect = 0
                gameState.grid[row][col].isSelected = false
                gameState.grid[row][col].currentFieldValue = gameState.grid[row][col].initialCharge
            }
        }
        
        // Reset available magnets
        gameState.availableMagnets = (positive: totalPositiveMagnets, negative: totalNegativeMagnets)
        gameState.puzzleSolved = false
        gameState.showSolution = false
        
        updateFieldValues()
    }
    
    func toggleSolution() {
        if gameState.showSolution {
            resetPuzzle()
        } else {
            // Apply inverted solution
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if row < gameState.solution.count && col < gameState.solution[row].count {
                        // Invert the magnet value from the solution
                        let invertedMagnetValue = -gameState.solution[row][col]
                        gameState.grid[row][col].toolEffect = invertedMagnetValue
                    }
                }
            }
            
            // Update available magnets
            let positiveCount = gameState.solution.flatMap { $0 }.filter { $0 == -1 }.count
            let negativeCount = gameState.solution.flatMap { $0 }.filter { $0 == 1 }.count
            gameState.availableMagnets = (
                positive: totalPositiveMagnets - positiveCount,
                negative: totalNegativeMagnets - negativeCount
            )
            
            gameState.showSolution = true
            updateFieldValues()
        }
    }
    
    func toggleHints() {
        gameState.showHints.toggle()
        delegate?.gameStateDidChange()
    }
    
    func areHintsEnabled() -> Bool {
        return gameState.showHints
    }
    
    // MARK: - Influence Calculation
    func getInfluenceArea(for row: Int, col: Int) -> [[Bool]] {
            let position = GridPosition(row: row, col: col)
            let affectedPositions = fieldCalculator.getInfluencePattern(for: position, magnetType: puzzleMagnetType)
            
            var influence = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
            
            for (pos, _) in affectedPositions {
                if pos.row >= 0 && pos.row < gridSize && pos.col >= 0 && pos.col < gridSize {
                    influence[pos.row][pos.col] = true
                }
            }
            
            return influence
        }
    
    func getInfluenceIntensity(from sourceRow: Int, sourceCol: Int, to targetRow: Int, targetCol: Int) -> Int {
            let source = GridPosition(row: sourceRow, col: sourceCol)
            let target = GridPosition(row: targetRow, col: targetCol)
            let pattern = fieldCalculator.getInfluencePattern(for: source, magnetType: puzzleMagnetType)
            
            return pattern[target] ?? 0
        }
    
    func getInfluenceValue(at row: Int, col: Int, magnetType: Int) -> Int {
        return getInfluenceValue(from: row, sourceCol: col, to: row, targetCol: col, magnetType: magnetType)
    }
    
    func getInfluenceValue(from sourceRow: Int, sourceCol: Int, to targetRow: Int, targetCol: Int, magnetType: Int) -> Int {
        let source = GridPosition(row: sourceRow, col: sourceCol)
        let target = GridPosition(row: targetRow, col: targetCol)
        
        return fieldCalculator.getInfluenceValue(
            from: source,
            to: target,
            magnetType: magnetType
        )
    }
    
    // MARK: - Analysis Methods
    func getNeutralizationPercentage(at row: Int, col: Int) -> Double {
        let position = GridPosition(row: row, col: col)
        let initialCharge = gameState.grid[row][col].initialCharge
        
        return fieldCalculator.getNeutralizationProgress(
            for: position,
            initialCharge: initialCharge
        )
    }
    
    func getOvershotCells() -> [GridPosition] {
        var initialCharges: [[Int]] = []
        for row in gameState.grid {
            initialCharges.append(row.map { $0.initialCharge })
        }
        
        return fieldCalculator.getOvershotCells(initialCharges: initialCharges)
    }
    
    // MARK: - Puzzle Info
    func getPuzzleInfo() -> PuzzleInfo {
        var targetCellCount = 0
        var neutralizedCount = 0
        var overshotCount = 0
        
        let overshotCells = Set(getOvershotCells())
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = gameState.grid[row][col]
                if cell.initialCharge != 0 {
                    targetCellCount += 1
                    if cell.isNeutralized {
                        neutralizedCount += 1
                    }
                    if overshotCells.contains(GridPosition(row: row, col: col)) {
                        overshotCount += 1
                    }
                }
            }
        }
        
        return PuzzleInfo(
            gridSize: gridSize,
            targetCells: targetCellCount,
            neutralizedCells: neutralizedCount,
            overshotCells: overshotCount,
            availablePositiveMagnets: gameState.availableMagnets.positive,
            availableNegativeMagnets: gameState.availableMagnets.negative,
            isSolved: gameState.puzzleSolved,
            isShowingSolution: gameState.showSolution
        )
    }
    
    // MARK: - Public Accessors
    func setSelectedMagnetType(_ type: Int) {
        gameState.selectedMagnetType = type
        delegate?.gameStateDidChange()
    }
    
    func getSelectedMagnetType() -> Int {
        return gameState.selectedMagnetType
    }
    
    func isShowingSolution() -> Bool {
        return gameState.showSolution
    }
    
    func isPuzzleSolved() -> Bool {
        return gameState.puzzleSolved
    }
    
    func getAvailableMagnets() -> (positive: Int, negative: Int) {
        return gameState.availableMagnets
    }
    
    func getCellAt(row: Int, col: Int) -> MagnetCell? {
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else {
            return nil
        }
        return gameState.grid[row][col]
    }
    
    func removeMagnetDirectly(at row: Int, col: Int) {
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else { return }
        
        let currentValue = gameState.grid[row][col].toolEffect
        
        // Return magnet to inventory
        if currentValue == 1 {
            gameState.availableMagnets.positive += 1
        } else if currentValue == -1 {
            gameState.availableMagnets.negative += 1
        }
        
        // Remove the magnet
        gameState.grid[row][col].toolEffect = 0
        gameState.grid[row][col].isSelected = false
        
        // Update field values
        updateFieldValues()
    }
    
    func getGridSize() -> Int {
        return gridSize
    }
    
    func getGameStateForSaving() -> PuzzleState {
        return gameState
    }
}

// MARK: - Puzzle Info Structure
struct PuzzleInfo {
    let gridSize: Int
    let targetCells: Int
    let neutralizedCells: Int
    let overshotCells: Int
    let availablePositiveMagnets: Int
    let availableNegativeMagnets: Int
    let isSolved: Bool
    let isShowingSolution: Bool
    
    var progress: Float {
        guard targetCells > 0 else { return 0 }
        return Float(neutralizedCells) / Float(targetCells)
    }
    
    var efficiency: Float {
        guard targetCells > 0 else { return 0 }
        let perfectScore = Float(targetCells)
        let currentScore = Float(neutralizedCells) - Float(overshotCells) * 0.5
        return max(0, currentScore / perfectScore)
    }
}

