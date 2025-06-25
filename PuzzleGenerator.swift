//
//  PuzzleGenerator.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import Foundation

// MARK: - Puzzle Generator
class PuzzleGenerator {
    
    // MARK: - Difficulty Configuration
    struct DifficultyConfig {
        let targetCellRange: ClosedRange<Int>
        let placementStrategy: PlacementStrategy
        
        enum PlacementStrategy {
            case even       // Easier - spread out targets
            case clustered  // Harder - group targets
            case mixed      // Medium - combination
        }
        
        static func config(for difficulty: String, gridSize: Int) -> DifficultyConfig {
            switch (difficulty.lowercased(), gridSize) {
            case ("easy", 4):
                return DifficultyConfig(
                    targetCellRange: 8...10,
                    placementStrategy: .even
                )
            case ("medium", 4):
                return DifficultyConfig(
                    targetCellRange: 7...9,
                    placementStrategy: .mixed
                )
            case ("hard", 4):
                return DifficultyConfig(
                    targetCellRange: 6...8,
                    placementStrategy: .clustered
                )
            case ("easy", 5):
                return DifficultyConfig(
                    targetCellRange: 12...15,
                    placementStrategy: .even
                )
            case ("medium", 5):
                return DifficultyConfig(
                    targetCellRange: 9...12,
                    placementStrategy: .mixed
                )
            case ("hard", 5):
                return DifficultyConfig(
                    targetCellRange: 8...10,
                    placementStrategy: .clustered
                )
            default:
                // Default medium difficulty
                return DifficultyConfig(
                    targetCellRange: 9...12,
                    placementStrategy: .mixed
                )
            }
        }
    }
    
    // MARK: - Generate Random Puzzle
    static func generateRandomPuzzle(
        gridSize: Int = 5,
        difficulty: String = "medium",
        positiveMagnets: Int = 3,
        negativeMagnets: Int = 3,
        magnetType: MagnetType = .standard
    ) -> PuzzleDefinition {
        
        let config = DifficultyConfig.config(for: difficulty, gridSize: gridSize)
        
        // Step 1: Generate random magnet placements (solution)
        let solution = generateRandomSolution(
            gridSize: gridSize,
            positiveMagnets: positiveMagnets,
            negativeMagnets: negativeMagnets
        )
        
        // Step 2: Calculate resulting field values
        let fieldCalculator = FieldCalculatorFactory.getCalculator(for: gridSize)
        let fieldValues = calculateFieldValues(
            solution: solution,
            gridSize: gridSize,
            calculator: fieldCalculator,
            magnetType: magnetType
        )
        
        // Step 3: Select target cells based on difficulty
        let targetCellCount = Int.random(in: config.targetCellRange)
        let initialCharges = selectTargetCells(
            fieldValues: fieldValues,
            targetCount: targetCellCount,
            strategy: config.placementStrategy,
            gridSize: gridSize
        )
        
        // All cells are placeable by default
        let placeableGrid = Array(
            repeating: Array(repeating: true, count: gridSize),
            count: gridSize
        )
        
        return PuzzleDefinition(
            gridSize: gridSize,
            initialCharges: initialCharges,
            solution: solution,
            placeableGrid: placeableGrid,
            positiveMagnets: positiveMagnets,
            negativeMagnets: negativeMagnets,
            magnetType: magnetType
        )
    }
    
    // MARK: - Solution Generation
    private static func generateRandomSolution(
        gridSize: Int,
        positiveMagnets: Int,
        negativeMagnets: Int
    ) -> [[Int]] {
        
        var solution = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        var availablePositions = [(row: Int, col: Int)]()
        
        // Create list of all positions
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                availablePositions.append((row: row, col: col))
            }
        }
        
        // Shuffle positions
        availablePositions.shuffle()
        
        // Place positive magnets
        for i in 0..<positiveMagnets {
            if i < availablePositions.count {
                let pos = availablePositions[i]
                solution[pos.row][pos.col] = 1
            }
        }
        
        // Place negative magnets
        for i in 0..<negativeMagnets {
            let index = positiveMagnets + i
            if index < availablePositions.count {
                let pos = availablePositions[index]
                solution[pos.row][pos.col] = -1
            }
        }
        
        return solution
    }
    
    // MARK: - Field Calculation
    private static func calculateFieldValues(
        solution: [[Int]],
        gridSize: Int,
        calculator: FieldCalculator,
        magnetType: MagnetType = .standard
    ) -> [[Int]] {
        
        // Initial charges are all zero for puzzle generation
        let initialCharges = Array(
            repeating: Array(repeating: 0, count: gridSize),
            count: gridSize
        )
        
        return calculator.calculateAllFieldValues(
                initialCharges: initialCharges,
                magnets: solution,
                magnetType: magnetType
            )
    }
    
    private static func calculateFieldValuesWithMagnetType(
        initialCharges: [[Int]],
        magnets: [[Int]],
        calculator: FieldCalculator,
        magnetType: MagnetType
    ) -> [[Int]] {
        
        var fieldValues = initialCharges.map { $0 }
        
        // Apply each magnet's influence using the specified type
        for row in 0..<magnets.count {
            for col in 0..<magnets[row].count {
                let magnetValue = magnets[row][col]
                if magnetValue != 0 {
                    let position = GridPosition(row: row, col: col)
                    let pattern = calculator.getInfluencePattern(for: position, magnetType: magnetType)
                    
                    for (targetPosition, strength) in pattern {
                        fieldValues[targetPosition.row][targetPosition.col] += strength * magnetValue
                    }
                }
            }
        }
        
        return fieldValues
    }
    
    // MARK: - Target Cell Selection
    private static func selectTargetCells(
        fieldValues: [[Int]],
        targetCount: Int,
        strategy: DifficultyConfig.PlacementStrategy,
        gridSize: Int
    ) -> [[Int]] {
        
        var initialCharges = Array(
            repeating: Array(repeating: 0, count: gridSize),
            count: gridSize
        )
        
        switch strategy {
        case .even:
            selectEvenlyDistributedTargets(
                initialCharges: &initialCharges,
                fieldValues: fieldValues,
                count: targetCount,
                gridSize: gridSize
            )
            
        case .clustered:
            selectClusteredTargets(
                initialCharges: &initialCharges,
                fieldValues: fieldValues,
                count: targetCount,
                gridSize: gridSize
            )
            
        case .mixed:
            selectMixedTargets(
                initialCharges: &initialCharges,
                fieldValues: fieldValues,
                count: targetCount,
                gridSize: gridSize
            )
        }
        
        return initialCharges
    }
    
    // MARK: - Selection Strategies
    
    private static func selectEvenlyDistributedTargets(
        initialCharges: inout [[Int]],
        fieldValues: [[Int]],
        count: Int,
        gridSize: Int
    ) {
        // Divide grid into regions
        let regions = min(3, gridSize - 1)
        let cellsPerRegion = (count / (regions * regions)) + 1
        
        var regionCounts = Array(
            repeating: Array(repeating: 0, count: regions),
            count: regions
        )
        
        // Get all non-zero positions
        var candidates: [(row: Int, col: Int, value: Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if fieldValues[row][col] != 0 {
                    candidates.append((row, col, fieldValues[row][col]))
                }
            }
        }
        
        // Shuffle for randomness
        candidates.shuffle()
        
        var selectedCount = 0
        
        // First pass: distribute evenly across regions
        for candidate in candidates {
            let regionRow = min(candidate.row * regions / gridSize, regions - 1)
            let regionCol = min(candidate.col * regions / gridSize, regions - 1)
            
            if regionCounts[regionRow][regionCol] < cellsPerRegion {
                initialCharges[candidate.row][candidate.col] = candidate.value
                regionCounts[regionRow][regionCol] += 1
                selectedCount += 1
                
                if selectedCount >= count { break }
            }
        }
        
        // Second pass: fill remaining slots
        if selectedCount < count {
            for candidate in candidates {
                if initialCharges[candidate.row][candidate.col] == 0 {
                    initialCharges[candidate.row][candidate.col] = candidate.value
                    selectedCount += 1
                    
                    if selectedCount >= count { break }
                }
            }
        }
    }
    
    private static func selectClusteredTargets(
        initialCharges: inout [[Int]],
        fieldValues: [[Int]],
        count: Int,
        gridSize: Int
    ) {
        // Select 1-2 cluster centers
        let clusterCount = count > 10 ? 2 : 1
        var clusterCenters: [(row: Int, col: Int)] = []
        
        for _ in 0..<clusterCount {
            clusterCenters.append((
                row: Int.random(in: 0..<gridSize),
                col: Int.random(in: 0..<gridSize)
            ))
        }
        
        // Get all non-zero positions with distances
        var candidates: [(position: (row: Int, col: Int), value: Int, distance: Int)] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if fieldValues[row][col] != 0 {
                    // Find minimum Manhattan distance to any cluster
                    var minDistance = Int.max
                    for center in clusterCenters {
                        let distance = abs(row - center.row) + abs(col - center.col)
                        minDistance = min(minDistance, distance)
                    }
                    
                    candidates.append((
                        position: (row, col),
                        value: fieldValues[row][col],
                        distance: minDistance
                    ))
                }
            }
        }
        
        // Sort by distance (closest first)
        candidates.sort { $0.distance < $1.distance }
        
        // Select cells with some randomness
        var selectedCount = 0
        for candidate in candidates {
            if Double.random(in: 0...1) > 0.2 || selectedCount < count / 2 {
                initialCharges[candidate.position.row][candidate.position.col] = candidate.value
                selectedCount += 1
                
                if selectedCount >= count { break }
            }
        }
        
        // Fill remaining if needed
        if selectedCount < count {
            for candidate in candidates {
                if initialCharges[candidate.position.row][candidate.position.col] == 0 {
                    initialCharges[candidate.position.row][candidate.position.col] = candidate.value
                    selectedCount += 1
                    
                    if selectedCount >= count { break }
                }
            }
        }
    }
    
    private static func selectMixedTargets(
        initialCharges: inout [[Int]],
        fieldValues: [[Int]],
        count: Int,
        gridSize: Int
    ) {
        // Get all non-zero positions
        var candidates: [(row: Int, col: Int, value: Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if fieldValues[row][col] != 0 {
                    candidates.append((row, col, fieldValues[row][col]))
                }
            }
        }
        
        // Sort by absolute value (highest first)
        candidates.sort { abs($0.value) > abs($1.value) }
        
        var selectedCount = 0
        
        // First, include some extreme values
        let extremeCount = min(count / 3, 3)
        for i in 0..<min(extremeCount, candidates.count) {
            let candidate = candidates[i]
            initialCharges[candidate.row][candidate.col] = candidate.value
            selectedCount += 1
        }
        
        // Then add some low values
        let lowValueCandidates = candidates.filter { abs($0.value) <= 2 }
        let lowCount = min(count / 4, lowValueCandidates.count)
        
        for i in 0..<lowCount {
            let candidate = lowValueCandidates[i]
            if initialCharges[candidate.row][candidate.col] == 0 {
                initialCharges[candidate.row][candidate.col] = candidate.value
                selectedCount += 1
            }
        }
        
        // Fill the rest randomly
        candidates.shuffle()
        for candidate in candidates {
            if selectedCount >= count { break }
            
            if initialCharges[candidate.row][candidate.col] == 0 {
                initialCharges[candidate.row][candidate.col] = candidate.value
                selectedCount += 1
            }
        }
    }
}

// MARK: - Puzzle Validator
extension PuzzleGenerator {
    
    /// Validates that a puzzle has a valid solution
    static func validatePuzzle(_ puzzle: PuzzleDefinition) -> Bool {
        // Create a field calculator
        let calculator = FieldCalculatorFactory.getCalculator(for: puzzle.gridSize)
        
        // Calculate what the field would be with the solution
        let fieldWithSolution = calculator.calculateAllFieldValues(
            initialCharges: puzzle.initialCharges,
            magnets: puzzle.solution
        )
        
        // Check if all target cells are neutralized
        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if puzzle.initialCharges[row][col] != 0 {
                    // This is a target cell - it should be neutralized
                    if fieldWithSolution[row][col] != 0 {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    /// Calculates puzzle difficulty score
    static func calculateDifficultyScore(_ puzzle: PuzzleDefinition) -> Float {
        var score: Float = 0
        
        // Factor 1: Number of target cells (fewer = harder)
        let targetCellCount = puzzle.initialCharges.flatMap { $0 }.filter { $0 != 0 }.count
        let totalCells = puzzle.gridSize * puzzle.gridSize
        score += Float(totalCells - targetCellCount) / Float(totalCells) * 30
        
        // Factor 2: Average absolute value of targets (higher = harder)
        let targetValues = puzzle.initialCharges.flatMap { $0 }.filter { $0 != 0 }
        if !targetValues.isEmpty {
            let avgValue = Float(targetValues.map { abs($0) }.reduce(0, +)) / Float(targetValues.count)
            score += min(avgValue * 5, 30)
        }
        
        // Factor 3: Clustering of targets (more clustered = harder)
        score += calculateClusteringScore(puzzle.initialCharges) * 20
        
        // Factor 4: Solution complexity (more magnets used = harder)
        let magnetsUsed = puzzle.solution.flatMap { $0 }.filter { $0 != 0 }.count
        let maxMagnets = puzzle.positiveMagnets + puzzle.negativeMagnets
        score += Float(magnetsUsed) / Float(maxMagnets) * 20
        
        return min(max(score, 0), 100) // Clamp to 0-100
    }
    
    private static func calculateClusteringScore(_ grid: [[Int]]) -> Float {
        var clusterScore: Float = 0
        let nonZeroCells = grid.enumerated().flatMap { row in
            row.element.enumerated().compactMap { col in
                col.element != 0 ? (row: row.offset, col: col.offset) : nil
            }
        }
        
        guard nonZeroCells.count > 1 else { return 0 }
        
        // Calculate average distance between non-zero cells
        var totalDistance = 0
        var pairCount = 0
        
        for i in 0..<nonZeroCells.count {
            for j in (i+1)..<nonZeroCells.count {
                let distance = abs(nonZeroCells[i].row - nonZeroCells[j].row) +
                               abs(nonZeroCells[i].col - nonZeroCells[j].col)
                totalDistance += distance
                pairCount += 1
            }
        }
        
        let avgDistance = Float(totalDistance) / Float(pairCount)
        let maxDistance = Float(grid.count * 2) // Maximum possible distance
        
        // Lower average distance = more clustered = higher score
        clusterScore = 1.0 - (avgDistance / maxDistance)
        
        return clusterScore
    }
}
