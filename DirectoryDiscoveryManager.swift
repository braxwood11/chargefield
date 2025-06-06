//
//  DirectoryDiscoveryManager.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import Foundation

// MARK: - Directory Metadata
struct DirectoryMetadata: Codable {
    let path: DirectoryPath
    var visitCount: Int
    var lastVisited: Date
    var firstDiscovered: Date
    var isFavorite: Bool
    
    init(path: DirectoryPath) {
        self.path = path
        self.visitCount = 1
        self.lastVisited = Date()
        self.firstDiscovered = Date()
        self.isFavorite = false
    }
    
    var specialIcon: String? {
        switch path {
        case .classified, .project_alpha, .maintenance, .logs:
            return "🔒"
        case .special:
            return "⚠️"
        case .training:
            return "🎓"
        case .assignments:
            return "⚡"
        case .archived:
            return "📋"
        case .root:
            return "🏠"
        case .catalog:
            return "📚"
        }
    }
    
    var accessibilityDescription: String {
        let timesText = visitCount == 1 ? "time" : "times"
        let lastVisitedText = formatRelativeTime(lastVisited)
        return "\(path.displayName) • Visited \(visitCount) \(timesText) • Last: \(lastVisitedText)"
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Directory Discovery Manager
class DirectoryDiscoveryManager {
    static let shared = DirectoryDiscoveryManager()
    
    private var discoveredDirectories: [DirectoryPath: DirectoryMetadata] = [:]
    private let saveKey = "DiscoveredDirectories"
    private let maxFavorites = 5
    
    private init() {
        loadDiscoveredDirectories()
        
        // Always ensure root is discovered
        if discoveredDirectories[.root] == nil {
            discoverDirectory(.root)
        }
    }
    
    // MARK: - Discovery Tracking
    func discoverDirectory(_ path: DirectoryPath) {
        if var metadata = discoveredDirectories[path] {
            // Update existing
            metadata.visitCount += 1
            metadata.lastVisited = Date()
            discoveredDirectories[path] = metadata
        } else {
            // Add new discovery
            discoveredDirectories[path] = DirectoryMetadata(path: path)
        }
        
        saveDiscoveredDirectories()
        
        // Post notification for potential achievements/messages
        NotificationCenter.default.post(
            name: .directoryDiscovered,
            object: nil,
            userInfo: ["directory": path]
        )
    }
    
    func hasDiscovered(_ path: DirectoryPath) -> Bool {
        return discoveredDirectories[path] != nil
    }
    
    func getMetadata(for path: DirectoryPath) -> DirectoryMetadata? {
        return discoveredDirectories[path]
    }
    
    func getAllDiscovered() -> [DirectoryMetadata] {
        return Array(discoveredDirectories.values).sorted { metadata1, metadata2 in
            // Sort by: favorites first, then by last visited
            if metadata1.isFavorite != metadata2.isFavorite {
                return metadata1.isFavorite && !metadata2.isFavorite
            }
            return metadata1.lastVisited > metadata2.lastVisited
        }
    }
    
    // MARK: - Favorites Management
    func toggleFavorite(_ path: DirectoryPath) -> Bool {
        guard var metadata = discoveredDirectories[path] else { return false }
        
        if metadata.isFavorite {
            // Remove from favorites
            metadata.isFavorite = false
            discoveredDirectories[path] = metadata
            saveDiscoveredDirectories()
            return true
        } else {
            // Check if we can add more favorites
            let currentFavoritesCount = getFavorites().count
            guard currentFavoritesCount < maxFavorites else { return false }
            
            // Add to favorites
            metadata.isFavorite = true
            discoveredDirectories[path] = metadata
            saveDiscoveredDirectories()
            return true
        }
    }
    
    func getFavorites() -> [DirectoryMetadata] {
        return discoveredDirectories.values
            .filter { $0.isFavorite }
            .sorted { $0.lastVisited > $1.lastVisited }
    }
    
    func getFavoritesCount() -> Int {
        return getFavorites().count
    }
    
    func getMaxFavorites() -> Int {
        return maxFavorites
    }
    
    func canAddMoreFavorites() -> Bool {
        return getFavoritesCount() < maxFavorites
    }
    
    // MARK: - Statistics
    func getTotalDiscovered() -> Int {
        return discoveredDirectories.count
    }
    
    func getTotalHiddenDiscovered() -> Int {
        return discoveredDirectories.keys.filter { $0.isHidden }.count
    }
    
    func getMostVisited() -> DirectoryMetadata? {
        return discoveredDirectories.values.max { $0.visitCount < $1.visitCount }
    }
    
    // MARK: - Persistence
    private func saveDiscoveredDirectories() {
        if let encoded = try? JSONEncoder().encode(discoveredDirectories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadDiscoveredDirectories() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([DirectoryPath: DirectoryMetadata].self, from: data) else {
            return
        }
        discoveredDirectories = decoded
    }
    
    // MARK: - Reset (for testing)
    func reset() {
        discoveredDirectories.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
        
        // Re-add root
        discoverDirectory(.root)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let directoryDiscovered = Notification.Name("directoryDiscovered")
    static let favoriteToggled = Notification.Name("favoriteToggled")
}
