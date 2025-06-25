//
//  FieldCalculator.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import Foundation

// MARK: - Grid Position
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
    
    func distance(to other: GridPosition) -> Int {
        return abs(row - other.row) + abs(col - other.col)
    }
    
    func isInSameRowOrColumn(as other: GridPosition) -> Bool {
        return row == other.row || col == other.col
    }
}

// MARK: - Field Calculator
class FieldCalculator {
    
    // MARK: - Properties
    private let gridSize: Int
    private var influenceCache: [GridPosition: [GridPosition: Int]] = [:]
    private var currentFieldValues: [[Int]]
    private var magnetPlacements: [[Int]]
    
    // MARK: - Constants
    private enum FieldStrength {
        static let ownCell = 3
        static let distance1 = 2
        static let distance2 = 1
        static let maxInfluenceDistance = 2
    }
    
    // MARK: - Initialization
    init(gridSize: Int) {
        self.gridSize = gridSize
        self.currentFieldValues = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        self.magnetPlacements = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        
        // Pre-calculate influence patterns for all positions
        precalculateInfluencePatterns()
    }
    
    // MARK: - Influence Pattern Calculation
    private func precalculateInfluencePatterns() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let position = GridPosition(row: row, col: col)
                influenceCache[position] = calculateStandardInfluencePattern(for: position)
            }
        }
    }
    
    private func calculateStandardInfluencePattern(for source: GridPosition) -> [GridPosition: Int] {
        var pattern: [GridPosition: Int] = [:]
        
        // Own cell gets strongest influence
        pattern[source] = FieldStrength.ownCell
        
        // Calculate influence on row
        for col in 0..<gridSize {
            let target = GridPosition(row: source.row, col: col)
            if target != source {
                let distance = abs(col - source.col)
                if distance <= FieldStrength.maxInfluenceDistance {
                    pattern[target] = influenceStrength(for: distance)
                }
            }
        }
        
        // Calculate influence on column
        for row in 0..<gridSize {
            let target = GridPosition(row: row, col: source.col)
            if target != source {
                let distance = abs(row - source.row)
                if distance <= FieldStrength.maxInfluenceDistance {
                    pattern[target] = influenceStrength(for: distance)
                }
            }
        }
        
        return pattern
    }
    
    // Add new method for diagonal patterns
    private func calculateDiagonalInfluencePattern(for source: GridPosition) -> [GridPosition: Int] {
        var pattern: [GridPosition: Int] = [:]
        
        // Own cell gets strongest influence
        pattern[source] = FieldStrength.ownCell
        
        // Diagonal directions: up-left, up-right, down-left, down-right
        let directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        
        for direction in directions {
            for distance in 1...FieldStrength.maxInfluenceDistance {
                let targetRow = source.row + (direction.0 * distance)
                let targetCol = source.col + (direction.1 * distance)
                
                if targetRow >= 0 && targetRow < gridSize && targetCol >= 0 && targetCol < gridSize {
                    let target = GridPosition(row: targetRow, col: targetCol)
                    pattern[target] = influenceStrength(for: distance)
                }
            }
        }
        
        return pattern
    }
    
    private func influenceStrength(for distance: Int) -> Int {
        switch distance {
        case 0: return FieldStrength.ownCell
        case 1: return FieldStrength.distance1
        case 2: return FieldStrength.distance2
        default: return 0
        }
    }
    
    // MARK: - Field Calculation Methods
    
    /// Calculate all field values from scratch (used for initialization)
    func calculateAllFieldValues(initialCharges: [[Int]], magnets: [[Int]], magnetType: MagnetType = .standard) -> [[Int]] {
        // Start with initial charges
        currentFieldValues = initialCharges.map { $0 }
        magnetPlacements = magnets.map { $0 }
        
        // Add influence from each magnet using the correct pattern
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let magnetValue = magnets[row][col]
                if magnetValue != 0 {
                    let position = GridPosition(row: row, col: col)
                    // Get the correct pattern for this magnet type
                    let pattern = getInfluencePattern(for: position, magnetType: magnetType)
                    
                    // Apply the influence directly
                    for (targetPosition, strength) in pattern {
                        currentFieldValues[targetPosition.row][targetPosition.col] += strength * magnetValue
                    }
                }
            }
        }
        
        return currentFieldValues
    }
    
    /// Update field values when a magnet is placed or removed
    func updateFieldValue(at position: GridPosition, oldMagnet: Int, newMagnet: Int, initialCharges: [[Int]], magnetType: MagnetType = .standard) -> [[Int]] {
        // Remove influence of old magnet
        if oldMagnet != 0 {
            removeMagnetInfluence(at: position, magnetType: oldMagnet, magnetPattern: magnetType)
        }
        
        // Update magnet placement
        magnetPlacements[position.row][position.col] = newMagnet
        
        // Add influence of new magnet
        if newMagnet != 0 {
            applyMagnetInfluence(at: position, magnetType: newMagnet, magnetPattern: magnetType)
        }
        
        return currentFieldValues
    }
    
    private func applyMagnetInfluence(at position: GridPosition, magnetType: Int, magnetPattern: MagnetType) {
        let pattern = getInfluencePattern(for: position, magnetType: magnetPattern)
        
        for (targetPosition, strength) in pattern {
            currentFieldValues[targetPosition.row][targetPosition.col] += strength * magnetType
        }
    }
    
    private func removeMagnetInfluence(at position: GridPosition, magnetType: Int, magnetPattern: MagnetType) {
        let pattern = getInfluencePattern(for: position, magnetType: magnetPattern)
        
        for (targetPosition, strength) in pattern {
            currentFieldValues[targetPosition.row][targetPosition.col] -= strength * magnetType
        }
    }
    
    // MARK: - Query Methods
    
    /// Get the influence pattern for a position (for UI preview)
    func getInfluencePattern(for position: GridPosition, magnetType: MagnetType) -> [GridPosition: Int] {
        switch magnetType {
        case .standard:
            return calculateStandardInfluencePattern(for: position)
        case .diagonal:
            return calculateDiagonalInfluencePattern(for: position)
        }
    }
    
    /// Get all positions that would be affected by placing a magnet
    func getAffectedPositions(for position: GridPosition) -> [GridPosition] {
        return influenceCache[position].map { Array($0.keys) } ?? []
    }
    
    /// Calculate what the field would be if a magnet were placed (without actually placing it)
    func previewFieldWithMagnet(at position: GridPosition, magnetType: Int) -> [[Int]] {
        var preview = currentFieldValues.map { $0 }
        
        guard let pattern = influenceCache[position] else { return preview }
        
        for (targetPosition, strength) in pattern {
            preview[targetPosition.row][targetPosition.col] += strength * magnetType
        }
        
        return preview
    }
    
    /// Get the influence value a magnet would have on a specific cell
    func getInfluenceValue(from source: GridPosition, to target: GridPosition, magnetType: Int) -> Int {
        guard let pattern = influenceCache[source],
              let strength = pattern[target] else {
            return 0
        }
        
        return strength * magnetType
    }
    
    // MARK: - Analysis Methods
    
    /// Check if all target cells are neutralized
    func areAllTargetsNeutralized(targetCells: Set<GridPosition>) -> Bool {
        for position in targetCells {
            if currentFieldValues[position.row][position.col] != 0 {
                return false
            }
        }
        return true
    }
    
    /// Get cells that are overshot (went past zero)
    func getOvershotCells(initialCharges: [[Int]]) -> [GridPosition] {
        var overshotCells: [GridPosition] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let initial = initialCharges[row][col]
                let current = currentFieldValues[row][col]
                
                // Check if signs are different (crossed over zero)
                if initial != 0 && ((initial > 0 && current < 0) || (initial < 0 && current > 0)) {
                    overshotCells.append(GridPosition(row: row, col: col))
                }
            }
        }
        
        return overshotCells
    }
    
    /// Calculate neutralization progress
    func getNeutralizationProgress(for position: GridPosition, initialCharge: Int) -> Double {
        let currentValue = currentFieldValues[position.row][position.col]
        
        if initialCharge == 0 {
            return 0.0
        }
        
        if currentValue == 0 {
            return 1.0
        }
        
        // If overshot
        if (initialCharge > 0 && currentValue < 0) || (initialCharge < 0 && currentValue > 0) {
            return 1.2 // Indicate overshoot
        }
        
        // Calculate progress
        let progress = 1.0 - (Double(abs(currentValue)) / Double(abs(initialCharge)))
        return max(0.0, min(1.0, progress))
    }
    
    // MARK: - Optimization Methods
    
    /// Clear cache (call if grid size changes)
    func clearCache() {
        influenceCache.removeAll()
        currentFieldValues = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        magnetPlacements = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
    }
    
    /// Get current field values
    func getCurrentFieldValues() -> [[Int]] {
        return currentFieldValues
    }
    
    /// Get current magnet placements
    func getMagnetPlacements() -> [[Int]] {
        return magnetPlacements
    }
}

// MARK: - Field Calculator Factory
class FieldCalculatorFactory {
    private static var calculators: [Int: FieldCalculator] = [:]
    
    static func getCalculator(for gridSize: Int) -> FieldCalculator {
        if let existing = calculators[gridSize] {
            return existing
        }
        
        let newCalculator = FieldCalculator(gridSize: gridSize)
        calculators[gridSize] = newCalculator
        return newCalculator
    }
    
    static func clearAllCalculators() {
        calculators.removeAll()
    }
}
