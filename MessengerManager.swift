//
//  MessageManager.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import Foundation

// MARK: - Message System
// Handles dynamic message delivery based on game events and progress

// MARK: - Message Model
struct Message: Codable {
    let id: String
    let sender: String
    let subject: String
    let body: String
    var timestamp: Date
    var isRead: Bool
    let priority: MessagePriority
    let triggerCondition: MessageTrigger?
    let attachment: MessageAttachment?
    
    enum MessagePriority: Int, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3
    }
}

// MARK: - Message Trigger
enum MessageTrigger: Codable {
    case onLevelComplete(levelId: String)
    case onTutorialComplete(tutorialId: String)
    case afterDelay(seconds: TimeInterval)
    case onAchievement(achievementId: String)
    case onFirstLaunch
    case onDaysSinceLastPlay(days: Int)
    case onPuzzleStreak(count: Int)
    case onFailureCount(count: Int)
    
    private enum CodingKeys: String, CodingKey {
        case type, levelId, tutorialId, seconds, achievementId, days, count
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .onLevelComplete(let levelId):
            try container.encode("onLevelComplete", forKey: .type)
            try container.encode(levelId, forKey: .levelId)
        case .onTutorialComplete(let tutorialId):
            try container.encode("onTutorialComplete", forKey: .type)
            try container.encode(tutorialId, forKey: .tutorialId)
        case .afterDelay(let seconds):
            try container.encode("afterDelay", forKey: .type)
            try container.encode(seconds, forKey: .seconds)
        case .onAchievement(let achievementId):
            try container.encode("onAchievement", forKey: .type)
            try container.encode(achievementId, forKey: .achievementId)
        case .onFirstLaunch:
            try container.encode("onFirstLaunch", forKey: .type)
        case .onDaysSinceLastPlay(let days):
            try container.encode("onDaysSinceLastPlay", forKey: .type)
            try container.encode(days, forKey: .days)
        case .onPuzzleStreak(let count):
            try container.encode("onPuzzleStreak", forKey: .type)
            try container.encode(count, forKey: .count)
        case .onFailureCount(let count):
            try container.encode("onFailureCount", forKey: .type)
            try container.encode(count, forKey: .count)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "onLevelComplete":
            let levelId = try container.decode(String.self, forKey: .levelId)
            self = .onLevelComplete(levelId: levelId)
        case "onTutorialComplete":
            let tutorialId = try container.decode(String.self, forKey: .tutorialId)
            self = .onTutorialComplete(tutorialId: tutorialId)
        case "afterDelay":
            let seconds = try container.decode(TimeInterval.self, forKey: .seconds)
            self = .afterDelay(seconds: seconds)
        case "onAchievement":
            let achievementId = try container.decode(String.self, forKey: .achievementId)
            self = .onAchievement(achievementId: achievementId)
        case "onFirstLaunch":
            self = .onFirstLaunch
        case "onDaysSinceLastPlay":
            let days = try container.decode(Int.self, forKey: .days)
            self = .onDaysSinceLastPlay(days: days)
        case "onPuzzleStreak":
            let count = try container.decode(Int.self, forKey: .count)
            self = .onPuzzleStreak(count: count)
        case "onFailureCount":
            let count = try container.decode(Int.self, forKey: .count)
            self = .onFailureCount(count: count)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown trigger type")
        }
    }
}

// MARK: - Message Attachment
struct MessageAttachment: Codable {
    enum AttachmentType: String, Codable {
        case hint
        case document
        case schematic
        case image
    }
    
    let type: AttachmentType
    let title: String
    let content: String // Could be hint text, document content, or image name
}

// MARK: - Message Manager
class MessageManager {
    static let shared = MessageManager()
    
    private var messages: [Message] = []
    private var triggeredMessageTimers: [String: Timer] = [:]
    private let messageQueue = DispatchQueue(label: "com.chargefield.messages", attributes: .concurrent)
    
    private init() {
        loadMessages()
        loadDefaultMessages()
        checkTriggeredMessages()
    }
    
    // MARK: - Message Loading
    private func loadMessages() {
        // Load saved messages from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: "SavedMessages"),
           let decodedMessages = try? JSONDecoder().decode([Message].self, from: savedData) {
            messages = decodedMessages
        }
    }
    
    private func loadDefaultMessages() {
        // Only add default messages if they don't already exist
        let defaultMessages = createDefaultMessages()
        
        for message in defaultMessages {
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        }
        
        saveMessages()
    }
    
    private func createDefaultMessages() -> [Message] {
        return [
            // Initial messages
            Message(
                id: "welcome_001",
                sender: "HR Department",
                subject: "Welcome to NeutraTech",
                body: """
                Dear New Employee,
                
                We're pleased to have you join our team of Field Harmonization Specialists. Your role is vital to our mission of managing energy anomalies.
                
                During your orientation, you'll learn to use our proprietary stabilization and suppression tools to achieve target energy values.
                
                Please report to Dr. Morgan for your orientation training as soon as possible.
                
                IMPORTANT: All field activities are strictly classified. Do not discuss your work with anyone outside the company.
                
                Regards,
                HR Department
                """,
                timestamp: Date(),
                isRead: false,
                priority: .high,
                triggerCondition: .onFirstLaunch,
                attachment: nil
            ),
            
            Message(
                id: "credentials_001",
                sender: "IT Support",
                subject: "Employee Credentials",
                body: """
                NOTIFICATION: SYSTEM ACCESS GRANTED
                
                Your system access has been provisioned with Level 1 clearance.
                
                Your employee ID is NT-7842. Please memorize this number.
                
                Equipment allocation has been approved. Report to Supply (Sub-level 2) to receive your standard-issue harmonization tools.
                
                -- IT Support
                """,
                timestamp: Date().addingTimeInterval(300),
                isRead: false,
                priority: .normal,
                triggerCondition: .onFirstLaunch,
                attachment: nil
            ),
            
            Message(
                id: "training_001",
                sender: "Dr. Morgan",
                subject: "Training Schedule",
                body: """
                Field Specialist,
                
                I've scheduled your orientation for today. Please be prompt.
                
                We'll start with basic field harmonization exercises before moving on to more complex anomaly management.
                
                Looking forward to working with you.
                
                Best regards,
                Dr. Morgan
                """,
                timestamp: Date().addingTimeInterval(600),
                isRead: false,
                priority: .normal,
                triggerCondition: .onFirstLaunch,
                attachment: nil
            ),
            
            // Basic tutorial completion message
            Message(
                id: "tutorial_complete_001",
                sender: "Dr. Morgan",
                subject: "Basic Training Complete - Well Done!",
                body: """
                Excellent work completing your initial training!
                
                You've demonstrated a solid understanding of field harmonization basics. Your performance metrics have been logged and forwarded to management.
                
                You're now cleared for Level 1 field operations. Advanced training modules have been unlocked on your dashboard.
                
                Remember: efficiency and accuracy are paramount. Each anomaly you neutralize helps maintain facility stability.
                
                Keep up the good work,
                Dr. Morgan
                """,
                timestamp: Date(),
                isRead: false,
                priority: .high,
                triggerCondition: .onTutorialComplete(tutorialId: "tutorial_basics"),
                attachment: MessageAttachment(
                    type: .document,
                    title: "Field Operations Manual v1.2",
                    content: "Basic procedures for anomaly neutralization using harmonization tools..."
                )
            ),
            
            // Advanced tutorial completion message
            Message(
                id: "tutorial_complete_002",
                sender: "Dr. Morgan",
                subject: "Advanced Training - Impressive Progress",
                body: """
                Outstanding work on your advanced field harmonization training!
                
                Your understanding of overlapping field effects is exceptional. The ability to strategically place harmonization tools for maximum efficiency is a crucial skill.
                
                Level 2 clearance protocols are now available. You'll notice more complex assignments becoming available on your dashboard.
                
                Your supervisor has expressed interest in your rapid progress. Keep this up and you'll be eligible for specialized assignments soon.
                
                Best regards,
                Dr. Morgan
                """,
                timestamp: Date(),
                isRead: false,
                priority: .high,
                triggerCondition: .onTutorialComplete(tutorialId: "tutorial_advanced"),
                attachment: MessageAttachment(
                    type: .document,
                    title: "Advanced Field Theory Documentation",
                    content: "Detailed analysis of harmonic field interactions and optimization strategies..."
                )
            ),
            
            // Correction protocols completion message
            Message(
                id: "tutorial_complete_003",
                sender: "Senior Technician Walsh",
                subject: "Precision Protocols - Certification Achieved",
                body: """
                Field Specialist,
                
                Dr. Morgan asked me to congratulate you on mastering our correction protocols. Understanding overshoot mechanics isn't just academic - it's a safety requirement.
                
                Your precision in field manipulation meets our highest standards. I've updated your certification to include Hazardous Field Operations.
                
                What you've learned today could save lives in the field. Never underestimate the importance of precision over speed.
                
                You're ready for resource-constrained operations.
                
                Regards,
                Senior Technician Walsh
                """,
                timestamp: Date(),
                isRead: false,
                priority: .high,
                triggerCondition: .onTutorialComplete(tutorialId: "tutorial_correction"),
                attachment: MessageAttachment(
                    type: .schematic,
                    title: "Emergency Correction Procedures",
                    content: "Step-by-step protocols for field overshoot correction and safety procedures..."
                )
            ),
            
            // Efficiency tutorial completion message
            Message(
                id: "tutorial_complete_004",
                sender: "Supervisor Chen",
                subject: "Training Complete - Advanced Certification",
                body: """
                Field Specialist,
                
                Congratulations on completing your full training curriculum. Your mastery of efficient resource utilization is exactly what we need in the field.
                
                Your personnel file has been updated with advanced field harmonization certification. You're now eligible for high-priority assignments and specialized operations.
                
                Management has taken notice of your exceptional performance. Opportunities for advancement will be presented to qualified personnel like yourself.
                
                Report to Assignment Control for your next briefing.
                
                - Supervisor Chen
                """,
                timestamp: Date(),
                isRead: false,
                priority: .urgent,
                triggerCondition: .onTutorialComplete(tutorialId: "tutorial_efficiency"),
                attachment: MessageAttachment(
                    type: .document,
                    title: "Advanced Operations Clearance",
                    content: "Your security clearance has been upgraded. New assignment categories are now available..."
                )
            ),
            
            // Encouragement messages
            Message(
                id: "streak_003",
                sender: "Supervisor Chen",
                subject: "Impressive Performance",
                body: """
                Field Specialist,
                
                Your recent performance has caught our attention. Three successful neutralizations in a row is no small feat.
                
                Keep this up and you might qualify for advanced clearance sooner than expected.
                
                - Supervisor Chen
                """,
                timestamp: Date(),
                isRead: false,
                priority: .normal,
                triggerCondition: .onPuzzleStreak(count: 3),
                attachment: nil
            )
        ]
    }
    
    // MARK: - Message Management
    func getAllMessages() -> [Message] {
        return messageQueue.sync {
            messages.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    func getUnreadMessages() -> [Message] {
        return messageQueue.sync {
            messages.filter { !$0.isRead }.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    func getUnreadCount() -> Int {
        return messageQueue.sync {
            messages.filter { !$0.isRead }.count
        }
    }
    
    func markAsRead(_ messageId: String) {
        messageQueue.async(flags: .barrier) { [weak self] in
            if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                self?.messages[index].isRead = true
                self?.saveMessages()
                
                // Update progress manager
                GameProgressManager.shared.markMessageRead(messageId)
            }
        }
    }
    
    func getMessage(by id: String) -> Message? {
        return messageQueue.sync {
            messages.first { $0.id == id }
        }
    }
    
    // MARK: - Trigger Checking
    func checkTriggeredMessages() {
        let progress = GameProgressManager.shared
        
        messageQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            for (index, message) in self.messages.enumerated() {
                guard let trigger = message.triggerCondition else { continue }
                
                var shouldDeliver = false
                
                switch trigger {
                case .onFirstLaunch:
                    shouldDeliver = true // Always deliver on first launch
                    
                case .onTutorialComplete(let tutorialId):
                    shouldDeliver = progress.isTutorialCompleted(tutorialId)
                    
                case .onLevelComplete(let levelId):
                    shouldDeliver = progress.isLevelCompleted(levelId)
                    
                case .afterDelay(let seconds):
                    // Set up timer if not already set
                    if self.triggeredMessageTimers[message.id] == nil {
                        DispatchQueue.main.async {
                            let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
                                self.deliverMessage(message)
                            }
                            self.triggeredMessageTimers[message.id] = timer
                        }
                    }
                    
                case .onPuzzleStreak(let count):
                    // Check if player has completed 'count' puzzles in a row
                    // This would need additional tracking in GameProgressManager
                    shouldDeliver = false // Placeholder
                    
                default:
                    shouldDeliver = false
                }
                
                if shouldDeliver {
                    // Update timestamp to current time when delivering
                    var deliveredMessage = message
                    deliveredMessage.timestamp = Date()
                    self.messages[index] = deliveredMessage
                    
                    // Post notification for UI updates
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .newMessageReceived,
                            object: nil,
                            userInfo: ["messageId": message.id]
                        )
                    }
                }
            }
            
            self.saveMessages()
        }
    }
    
    private func deliverMessage(_ message: Message) {
        // This method is called when a delayed message should be delivered
        NotificationCenter.default.post(
            name: .newMessageReceived,
            object: nil,
            userInfo: ["messageId": message.id]
        )
    }
    
    // MARK: - Persistence
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "SavedMessages")
        }
    }
    
    // MARK: - Message Creation
    func createAndQueueMessage(
        sender: String,
        subject: String,
        body: String,
        priority: Message.MessagePriority = .normal,
        trigger: MessageTrigger? = nil,
        attachment: MessageAttachment? = nil
    ) {
        let newMessage = Message(
            id: UUID().uuidString,
            sender: sender,
            subject: subject,
            body: body,
            timestamp: Date(),
            isRead: false,
            priority: priority,
            triggerCondition: trigger,
            attachment: attachment
        )
        
        messageQueue.async(flags: .barrier) { [weak self] in
            self?.messages.append(newMessage)
            self?.saveMessages()
            self?.checkTriggeredMessages()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Cancel all timers
        triggeredMessageTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let messageRead = Notification.Name("messageRead")
}
