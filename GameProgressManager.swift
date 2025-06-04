//
//  GameProgressManager.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import Foundation

// MARK: - Game Progress Manager
// Handles saving and loading game state, tutorial progress, and message states

class GameProgressManager {
    
    // MARK: - Save Data Structure
    struct SaveData: Codable {
        var completedLevels: Set<String>
        var tutorialsCompleted: Set<String>
        var messagesRead: Set<String>
        var currentPuzzleState: PuzzleSaveState?
        var lastPlayedDate: Date
        var totalPlayTime: TimeInterval
        var statistics: GameStatistics
        
        init() {
            self.completedLevels = []
            self.tutorialsCompleted = []
            self.messagesRead = []
            self.currentPuzzleState = nil
            self.lastPlayedDate = Date()
            self.totalPlayTime = 0
            self.statistics = GameStatistics()
        }
    }
    
    // MARK: - Puzzle Save State
    
    struct MagnetInventory: Codable {
            let positive: Int
            let negative: Int
        }
    
    struct PuzzleSaveState: Codable {
            let puzzleId: String
            let gridSize: Int
            let initialCharges: [[Int]]
            let solution: [[Int]]
            let currentMagnetPlacements: [[Int]]
            let availableMagnets: MagnetInventory   // <— changed
            let puzzleType: PuzzleType
            let difficulty: String?
            let timeSpent: TimeInterval

            enum PuzzleType: String, Codable {
                case tutorial, random, campaign
            }
        }
    
    // MARK: - Game Statistics
    struct GameStatistics: Codable {
        var puzzlesCompleted: Int = 0
        var perfectSolutions: Int = 0
        var totalMagnetsPlaced: Int = 0
        var totalMovesUndone: Int = 0
        var fastestSolveTime: TimeInterval = .infinity
        var averageSolveTime: TimeInterval = 0
        
        mutating func updateAverageSolveTime(newTime: TimeInterval) {
            if puzzlesCompleted == 0 {
                averageSolveTime = newTime
            } else {
                let total = averageSolveTime * Double(puzzlesCompleted) + newTime
                averageSolveTime = total / Double(puzzlesCompleted + 1)
            }
            
            if newTime < fastestSolveTime {
                fastestSolveTime = newTime
            }
        }
    }
    
    // MARK: - Properties
    private static let saveKey = "ChargeFieldSaveData"
    private static let userDefaults = UserDefaults.standard
    static let shared = GameProgressManager()
    
    private var currentSaveData: SaveData
    private var sessionStartTime: Date
    
    // MARK: - Initialization
    private init() {
        self.currentSaveData = GameProgressManager.load()
        self.sessionStartTime = Date()
    }
    
    // MARK: - Save/Load Methods
    static func save(_ data: SaveData? = nil) {
        let dataToSave = data ?? shared.currentSaveData
        
        // Update play time before saving
        let currentSessionTime = Date().timeIntervalSince(shared.sessionStartTime)
        var updatedData = dataToSave
        updatedData.totalPlayTime += currentSessionTime
        updatedData.lastPlayedDate = Date()
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(updatedData) {
            userDefaults.set(encoded, forKey: saveKey)
            userDefaults.synchronize()
            
            // Update current save data
            shared.currentSaveData = updatedData
            shared.sessionStartTime = Date() // Reset session timer
        }
    }
    
    static func load() -> SaveData {
        guard let savedData = userDefaults.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: savedData) else {
            return SaveData()
        }
        return decoded
    }
    
    static func reset() {
        userDefaults.removeObject(forKey: saveKey)
        userDefaults.synchronize()
        shared.currentSaveData = SaveData()
        shared.sessionStartTime = Date()
    }
    
    // MARK: - Progress Tracking Methods
    func markLevelCompleted(_ levelId: String, solveTime: TimeInterval) {
        currentSaveData.completedLevels.insert(levelId)
        currentSaveData.statistics.puzzlesCompleted += 1
        currentSaveData.statistics.updateAverageSolveTime(newTime: solveTime)
        GameProgressManager.save()
    }
    
    func markTutorialCompleted(_ tutorialId: String) {
        currentSaveData.tutorialsCompleted.insert(tutorialId)
        GameProgressManager.save()
    }
    
    func markMessageRead(_ messageId: String) {
        currentSaveData.messagesRead.insert(messageId)
        GameProgressManager.save()
    }
    
    func isLevelCompleted(_ levelId: String) -> Bool {
        return currentSaveData.completedLevels.contains(levelId)
    }
    
    func isTutorialCompleted(_ tutorialId: String) -> Bool {
        return currentSaveData.tutorialsCompleted.contains(tutorialId)
    }
    
    func isMessageRead(_ messageId: String) -> Bool {
        return currentSaveData.messagesRead.contains(messageId)
    }
    
    // MARK: - Puzzle State Methods
    func savePuzzleState(from gameState: PuzzleState, puzzleId: String, puzzleType: PuzzleSaveState.PuzzleType, difficulty: String? = nil, timeSpent: TimeInterval) {
        // Extract current magnet placements
        var magnetPlacements: [[Int]] = []
        for row in gameState.grid {
            magnetPlacements.append(row.map { $0.toolEffect })
        }
        
        // Extract initial charges
        var initialCharges: [[Int]] = []
        for row in gameState.grid {
            initialCharges.append(row.map { $0.initialCharge })
        }
        
        let puzzleState = PuzzleSaveState(
            puzzleId: puzzleId,
            gridSize: gameState.grid.count,
            initialCharges: initialCharges,
            solution: gameState.solution,
            currentMagnetPlacements: magnetPlacements,
            availableMagnets: MagnetInventory(
                positive: gameState.availableMagnets.positive,
                negative: gameState.availableMagnets.negative
            ),
            puzzleType: puzzleType,
            difficulty: difficulty,
            timeSpent: timeSpent
        )
        
        currentSaveData.currentPuzzleState = puzzleState
        GameProgressManager.save()
    }
    
    func clearCurrentPuzzle() {
        currentSaveData.currentPuzzleState = nil
        GameProgressManager.save()
    }
    
    func getCurrentPuzzleState() -> PuzzleSaveState? {
        return currentSaveData.currentPuzzleState
    }
    
    // MARK: - Statistics Methods
    func recordMagnetPlaced() {
        currentSaveData.statistics.totalMagnetsPlaced += 1
    }
    
    func recordMoveUndone() {
        currentSaveData.statistics.totalMovesUndone += 1
    }
    
    func recordPerfectSolution() {
        currentSaveData.statistics.perfectSolutions += 1
    }
    
    func getStatistics() -> GameStatistics {
        return currentSaveData.statistics
    }
    
    // MARK: - Utility Methods
    func getTotalPlayTime() -> TimeInterval {
        let currentSessionTime = Date().timeIntervalSince(sessionStartTime)
        return currentSaveData.totalPlayTime + currentSessionTime
    }
    
    func getCompletedLevelCount() -> Int {
        return currentSaveData.completedLevels.count
    }
    
    func getUnreadMessageCount() -> Int {
        // This will be updated when we implement the message system
        return 1 // Placeholder
    }
}

// MARK: - Extensions for Easy Access
extension GameProgressManager {
    // Convenience computed properties
    var hasCompletedTutorial: Bool {
        return isTutorialCompleted("tutorial_basics")
    }
    
    var canAccessAdvancedLevels: Bool {
        return hasCompletedTutorial
    }
}
