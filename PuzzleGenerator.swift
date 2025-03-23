//
//  PuzzleGenerator.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - Puzzle Generator

class PuzzleGenerator {
    
    // Generate a random puzzle with the specified difficulty
    static func generateRandomPuzzle(gridSize: Int = 5, difficulty: String = "medium", positiveMagnets: Int = 3, negativeMagnets: Int = 3) -> PuzzleDefinition {
        
        // Determine target cell count based on difficulty and grid size
        let targetCellRange: ClosedRange<Int>
        if gridSize == 4 {
            // For 4x4 grid
            switch difficulty.lowercased() {
            case "easy":
                targetCellRange = 8...10  // Less cells for 4x4 easy
            case "hard":
                targetCellRange = 6...8   // Harder with fewer clues
            default: // medium
                targetCellRange = 7...9   // Medium difficulty
            }
        } else {
            // For 5x5 grid (original values)
            switch difficulty.lowercased() {
            case "easy":
                targetCellRange = 12...15
            case "hard":
                targetCellRange = 8...10
            default: // medium
                targetCellRange = 9...12
            }
        }
        
        // Step 1: Generate a random solution (magnet placements)
        var solution = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        var placedPositive = 0
        var placedNegative = 0
        
        // Place magnets randomly
        while placedPositive < positiveMagnets || placedNegative < negativeMagnets {
            let row = Int.random(in: 0..<gridSize)
            let col = Int.random(in: 0..<gridSize)
            
            if solution[row][col] == 0 {
                if placedPositive < positiveMagnets {
                    solution[row][col] = 1
                    placedPositive += 1
                } else if placedNegative < negativeMagnets {
                    solution[row][col] = -1
                    placedNegative += 1
                }
            }
        }
        
        // Step 2: Calculate resulting field values
        let fieldValues = calculateFieldValues(magnets: solution, gridSize: gridSize)
        
        // Step 3: Select target cells (cells that need to be neutralized)
        let targetCellCount = Int.random(in: targetCellRange)
        var initialCharges = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        
        // Strategy for selecting cells based on difficulty
        switch difficulty.lowercased() {
        case "easy":
            // For easy, select cells more evenly across the grid
            selectEvenlyDistributedTargets(initialCharges: &initialCharges, fieldValues: fieldValues, count: targetCellCount, gridSize: gridSize)
        case "hard":
            // For hard, select cells with some clustering
            selectClusteredTargets(initialCharges: &initialCharges, fieldValues: fieldValues, count: targetCellCount, gridSize: gridSize)
        default:
            // For medium, use a balanced approach
            selectBalancedTargets(initialCharges: &initialCharges, fieldValues: fieldValues, count: targetCellCount, gridSize: gridSize)
        }
        
        // All cells are placeable
        let placeableGrid = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: initialCharges,
            solution: solution,
            placeableGrid: placeableGrid,
            positiveMagnets: positiveMagnets,
            negativeMagnets: negativeMagnets
        )
    }
    
    // MARK: - Helper Methods
    
    // Calculate field values based on magnet placements
    private static func calculateFieldValues(magnets: [[Int]], gridSize: Int) -> [[Int]] {
        var fieldValues = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        
        // For each magnet, calculate its influence on all cells
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let magnetValue = magnets[row][col]
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
        
        return fieldValues
    }
    
    // MARK: - Target Cell Selection Strategies
    
    // Select cells evenly distributed across the grid (easier puzzles)
    private static func selectEvenlyDistributedTargets(initialCharges: inout [[Int]], fieldValues: [[Int]], count: Int, gridSize: Int) {
        // Create a list of all cell positions
        var allPositions: [(row: Int, col: Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                allPositions.append((row: row, col: col))
            }
        }
        
        // Shuffle all positions for randomness
        allPositions.shuffle()
        
        // Divide grid into regions to ensure distribution
        let regions = min(3, gridSize - 1) // Number of regions to create (e.g., 3x3 for 5x5 grid)
        var regionMap = Array(repeating: Array(repeating: 0, count: regions), count: regions)
        let maxPerRegion = (count / (regions * regions)) + 1
        
        var selectedCount = 0
        
        // First pass: try to distribute evenly
        for position in allPositions {
            // Calculate which region this position belongs to
            let regionRow = min(Int(Double(position.row) / Double(gridSize) * Double(regions)), regions - 1)
            let regionCol = min(Int(Double(position.col) / Double(gridSize) * Double(regions)), regions - 1)
            
            // If this region has room for more targets
            if regionMap[regionRow][regionCol] < maxPerRegion {
                initialCharges[position.row][position.col] = fieldValues[position.row][position.col]
                regionMap[regionRow][regionCol] += 1
                selectedCount += 1
                
                if selectedCount >= count {
                    break
                }
            }
        }
        
        // Second pass if needed: fill remaining slots
        if selectedCount < count {
            for position in allPositions {
                if initialCharges[position.row][position.col] == 0 { // Not yet assigned
                    initialCharges[position.row][position.col] = fieldValues[position.row][position.col]
                    selectedCount += 1
                    
                    if selectedCount >= count {
                        break
                    }
                }
            }
        }
    }
    
    // Select cells with some clustering (harder puzzles)
    private static func selectClusteredTargets(initialCharges: inout [[Int]], fieldValues: [[Int]], count: Int, gridSize: Int) {
        // Select 1-2 cluster centers
        let clusterCount = 1 + (count > 10 ? 1 : 0)
        var clusterCenters: [(row: Int, col: Int)] = []
        
        for _ in 0..<clusterCount {
            let centerRow = Int.random(in: 0..<gridSize)
            let centerCol = Int.random(in: 0..<gridSize)
            clusterCenters.append((row: centerRow, col: centerCol))
        }
        
        // Create a list of all positions with their distances to the nearest cluster
        var positionsWithDistances: [(position: (row: Int, col: Int), distance: Int)] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let position = (row: row, col: col)
                
                // Find minimum distance to any cluster center
                var minDistance = Int.max
                for center in clusterCenters {
                    let distance = abs(row - center.row) + abs(col - center.col) // Manhattan distance
                    minDistance = min(minDistance, distance)
                }
                
                positionsWithDistances.append((position: position, distance: minDistance))
            }
        }
        
        // Sort by distance (closest first)
        positionsWithDistances.sort { $0.distance < $1.distance }
        
        // Select cells, with some randomness
        var selectedCount = 0
        for entry in positionsWithDistances {
            // Add some randomness to avoid perfect clusters
            if Double.random(in: 0...1) > 0.2 || selectedCount < count / 2 { // Ensure we select at least half the required count
                let row = entry.position.row
                let col = entry.position.col
                
                if initialCharges[row][col] == 0 { // Not yet assigned
                    initialCharges[row][col] = fieldValues[row][col]
                    selectedCount += 1
                    
                    if selectedCount >= count {
                        break
                    }
                }
            }
        }
        
        // Fill any remaining slots
        if selectedCount < count {
            for entry in positionsWithDistances {
                let row = entry.position.row
                let col = entry.position.col
                
                if initialCharges[row][col] == 0 { // Not yet assigned
                    initialCharges[row][col] = fieldValues[row][col]
                    selectedCount += 1
                    
                    if selectedCount >= count {
                        break
                    }
                }
            }
        }
    }
    
    // Balanced approach, including some key cells
    private static func selectBalancedTargets(initialCharges: inout [[Int]], fieldValues: [[Int]], count: Int, gridSize: Int) {
        // Create a list of all positions
        var allPositions: [(row: Int, col: Int, value: Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                allPositions.append((row: row, col: col, value: fieldValues[row][col]))
            }
        }
        
        // First, include some cells with extreme values (highest absolute values)
        let extremeValueCount = min(count / 3, 3) // Up to 1/3 of count or 3, whichever is smaller
        
        // Sort by absolute value, highest first
        let sortedByAbsValue = allPositions.sorted { abs($0.value) > abs($1.value) }
        
        var selectedCount = 0
        
        // Add extreme values first
        for position in sortedByAbsValue.prefix(extremeValueCount) {
            initialCharges[position.row][position.col] = position.value
            selectedCount += 1
        }
        
        // Then add some cells with zero or near-zero values
        let neutralValueCount = min(count / 4, 2) // Up to 1/4 of count or 2, whichever is smaller
        let sortedByValue = allPositions.sorted { abs($0.value) < abs($1.value) }
        
        for position in sortedByValue.prefix(neutralValueCount) {
            if initialCharges[position.row][position.col] == 0 { // Not yet assigned
                initialCharges[position.row][position.col] = position.value
                selectedCount += 1
            }
        }
        
        // Fill the rest with a mix of positions
        var remainingPositions = allPositions.filter { initialCharges[$0.row][$0.col] == 0 }
        remainingPositions.shuffle()
        
        for position in remainingPositions {
            if initialCharges[position.row][position.col] == 0 { // Not yet assigned
                initialCharges[position.row][position.col] = position.value
                selectedCount += 1
                
                if selectedCount >= count {
                    break
                }
            }
        }
    }
}
