//
//  TutorialSystem.swift
//  ChargeField
//
//  Created by Assistant on Current Date.
//

import UIKit

// MARK: - Tutorial Step Protocol
protocol TutorialStepProtocol {
    var id: String { get }
    var instruction: String { get }
    var requiresAction: Bool { get }
    var highlightTargets: [HighlightTarget]? { get }
    var validation: TutorialValidation? { get }
    var nextButtonVisible: Bool { get }
}

// MARK: - Tutorial Level Protocol
protocol TutorialLevel {
    var levelId: String { get }
    var title: String { get }
    var description: String { get }
    var puzzleDefinition: PuzzleDefinition { get }
    var steps: [TutorialStep] { get }
    var nextTutorialId: String? { get }
    var completionMessage: String { get }
}

// MARK: - Tutorial Step Implementation
struct TutorialStep: TutorialStepProtocol {
    let id: String
    let instruction: String
    let requiresAction: Bool
    let highlightTargets: [HighlightTarget]?
    let validation: TutorialValidation?
    let nextButtonVisible: Bool
    
    init(
        id: String,
        instruction: String,
        requiresAction: Bool = false,
        highlightTargets: [HighlightTarget]? = nil,
        validation: TutorialValidation? = nil
    ) {
        self.id = id
        self.instruction = instruction
        self.requiresAction = requiresAction
        self.highlightTargets = highlightTargets
        self.validation = validation
        self.nextButtonVisible = !requiresAction
    }
}

// MARK: - Highlight Target
enum HighlightTarget {
    case grid
    case cell(row: Int, col: Int)
    case stabilizerButton
    case suppressorButton
    case resetButton
    case solutionButton
    case custom(identifier: String)
}

// MARK: - Tutorial Validation
enum TutorialValidation {
    case magnetSelected(type: Int)
    case cellSelected(row: Int, col: Int)
    case magnetPlaced(row: Int, col: Int, type: Int)
    case puzzleSolved
    case custom(validator: () -> Bool)
}

// MARK: - Basic Tutorial Implementation
struct BasicTutorial: TutorialLevel {
    let levelId = "tutorial_basics"
    let title = "NeutraTech Orientation #1"
    let description = "Learn the basics of field harmonization"
    
    var puzzleDefinition: PuzzleDefinition {
        return PuzzleDefinition.tutorialPuzzle()
    }
    
    let steps: [TutorialStep] = [
        TutorialStep(
            id: "welcome",
            instruction: "Welcome to NeutraTech! Let's learn how to process energy anomalies.",
            requiresAction: false
        ),
        TutorialStep(
            id: "explain_grid",
            instruction: "This grid represents a containment chamber where energy needs to be balanced.",
            requiresAction: false,
            highlightTargets: [.grid]
        ),
        TutorialStep(
            id: "explain_target_values",
            instruction: "The numbers in cells are target values. You need to match these exactly.",
            requiresAction: false,
            highlightTargets: [.cell(row: 0, col: 0), .cell(row: 2, col: 2)]
        ),
        TutorialStep(
            id: "select_stabilizer",
            instruction: "First, tap the Stabilizer (+) tool to select it.",
            requiresAction: true,
            highlightTargets: [.stabilizerButton],
            validation: .magnetSelected(type: 1)
        ),
        TutorialStep(
            id: "tap_cell_preview",
            instruction: "Now tap on the top-left cell to see how it would affect the field.",
            requiresAction: true,
            highlightTargets: [.cell(row: 0, col: 0)],
            validation: .cellSelected(row: 0, col: 0)
        ),
        TutorialStep(
            id: "tap_again_place",
            instruction: "Tap the cell again to place the stabilizer.",
            requiresAction: true,
            highlightTargets: [.cell(row: 0, col: 0)],
            validation: .magnetPlaced(row: 0, col: 0, type: 1)
        ),
        TutorialStep(
            id: "explain_neutralization",
            instruction: "Great! The cell is now neutralized. Notice the green highlight indicating the field is balanced to zero.",
            requiresAction: false,
            highlightTargets: [.cell(row: 0, col: 0)]
        ),
        TutorialStep(
            id: "explain_suppressor",
            instruction: "Now select the Suppressor (-) tool to decrease field values.",
            requiresAction: true,
            highlightTargets: [.suppressorButton],
            validation: .magnetSelected(type: -1)
        ),
        TutorialStep(
            id: "complete_task",
            instruction: "Complete the puzzle by matching all target values.",
            requiresAction: true,
            validation: .puzzleSolved
        )
    ]
    
    let nextTutorialId: String? = "tutorial_advanced"
    let completionMessage = "Great job! You've completed your training."
}

// MARK: - Tutorial Campaign Manager
class TutorialCampaign {
    static let shared = TutorialCampaign()
    
    private var tutorials: [String: TutorialLevel] = [:]
    
    private init() {
        registerDefaultTutorials()
    }
    
    private func registerDefaultTutorials() {
        // Register basic tutorial
        let basicTutorial = BasicTutorial()
        tutorials[basicTutorial.levelId] = basicTutorial
        
        // TODO: Add more tutorials here as they're created
    }
    
    func loadTutorial(_ id: String) -> TutorialLevel? {
        return tutorials[id]
    }
    
    func getAvailableTutorials() -> [TutorialLevel] {
        let progress = GameProgressManager.shared
        
        return tutorials.values.filter { tutorial in
            // Show tutorial if it's the first one or if the previous is completed
            if tutorial.levelId == "tutorial_basics" {
                return true
            }
            
            // Check if any tutorial has this as its next tutorial
            for (_, otherTutorial) in tutorials {
                if otherTutorial.nextTutorialId == tutorial.levelId {
                    return progress.isTutorialCompleted(otherTutorial.levelId)
                }
            }
            
            return false
        }.sorted { $0.levelId < $1.levelId }
    }
    
    func registerTutorial(_ tutorial: TutorialLevel) {
        tutorials[tutorial.levelId] = tutorial
    }
}

// MARK: - Tutorial Coordinator
class TutorialCoordinator {
    weak var gameViewController: GameViewController?
    weak var overlayView: TutorialOverlayView?
    
    private var currentTutorial: TutorialLevel?
    private var currentStepIndex: Int = 0
    private var isActive: Bool = false
    
    // MARK: - Initialization
    init(gameViewController: GameViewController) {
        self.gameViewController = gameViewController
    }
    
    // MARK: - Tutorial Management
    func startTutorial(_ tutorialId: String) {
        guard let tutorial = TutorialCampaign.shared.loadTutorial(tutorialId) else {
            print("Tutorial not found: \(tutorialId)")
            return
        }
        
        currentTutorial = tutorial
        currentStepIndex = 0
        isActive = true
        
        // Create and show overlay
        createOverlay()
        updateCurrentStep()
    }
    
    func advanceToNextStep() {
        guard let tutorial = currentTutorial,
              currentStepIndex < tutorial.steps.count - 1 else {
            completeTutorial()
            return
        }
        
        currentStepIndex += 1
        updateCurrentStep()
    }
    
    func validateCurrentStep() -> Bool {
        guard let tutorial = currentTutorial,
              currentStepIndex < tutorial.steps.count else {
            return false
        }
        
        let step = tutorial.steps[currentStepIndex]
        guard let validation = step.validation else {
            return true
        }
        
        switch validation {
        case .magnetSelected(let type):
            return gameViewController?.viewModel?.getSelectedMagnetType() == type
            
        case .cellSelected(let row, let col):
            return gameViewController?.viewModel?.getCellAt(row: row, col: col)?.isSelected ?? false
            
        case .magnetPlaced(let row, let col, let type):
            return gameViewController?.viewModel?.getCellAt(row: row, col: col)?.toolEffect == type
            
        case .puzzleSolved:
            return gameViewController?.viewModel?.isPuzzleSolved() ?? false
            
        case .custom(let validator):
            return validator()
        }
    }
    
    // MARK: - UI Updates
    private func createOverlay() {
        guard let gameView = gameViewController?.view else { return }
        
        let overlay = TutorialOverlayView(frame: gameView.bounds)
        overlay.setNextButtonAction(self, action: #selector(nextButtonTapped))
        
        gameView.addSubview(overlay)
        overlayView = overlay
    }
    
    private func updateCurrentStep() {
        guard let tutorial = currentTutorial,
              currentStepIndex < tutorial.steps.count,
              let overlay = overlayView else {
            return
        }
        
        let step = tutorial.steps[currentStepIndex]
        
        // Set interaction mode
        overlay.allowFullInteraction = (step.id == "complete_task")
        
        // Update instruction text
        overlay.setInstructionText(step.instruction)
        
        // Show/hide next button
        overlay.showNextButton(step.nextButtonVisible)
        
        // Clear previous highlights
        overlay.clearHighlight()
        
        // Apply new highlights
        if let targets = step.highlightTargets {
            highlightTargets(targets)
        }
        
        // Special handling for certain steps
        if step.id == "complete_task" {
            overlay.isHidden = true
            showCompletionBanner()
        } else {
            overlay.isHidden = false
        }
    }
    
    private func highlightTargets(_ targets: [HighlightTarget]) {
        guard let overlay = overlayView else { return }
        
        var viewsToHighlight: [UIView] = []
        
        for target in targets {
            switch target {
            case .grid:
                if let gridView = gameViewController?.gridView {
                    viewsToHighlight.append(gridView)
                }
                
            case .cell(let row, let col):
                if let cellView = gameViewController?.getCellView(at: row, col: col) {
                    viewsToHighlight.append(cellView)
                }
                
            case .stabilizerButton:
                if let button = gameViewController?.getStabilizerButton() {
                    viewsToHighlight.append(button)
                }
                
            case .suppressorButton:
                if let button = gameViewController?.getSuppressorButton() {
                    viewsToHighlight.append(button)
                }
                
            case .resetButton, .solutionButton, .custom:
                // Handle other cases as needed
                break
            }
        }
        
        if viewsToHighlight.count == 1 {
            overlay.highlightElement(viewsToHighlight[0])
        } else if viewsToHighlight.count > 1 {
            overlay.highlightMultipleElements(viewsToHighlight)
        }
    }
    
    private func showCompletionBanner() {
        guard let gameView = gameViewController?.view else { return }
        
        let banner = UIView()
        TerminalTheme.styleContainer(banner, borderOpacity: 1.0)
        banner.translatesAutoresizingMaskIntoConstraints = false
        gameView.addSubview(banner)
        
        let instructionLabel = TerminalLabel()
        instructionLabel.style = .body
        instructionLabel.text = currentTutorial?.steps[currentStepIndex].instruction ?? ""
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.topAnchor, constant: 90),
            banner.centerXAnchor.constraint(equalTo: gameView.centerXAnchor),
            banner.widthAnchor.constraint(equalTo: gameView.widthAnchor, multiplier: 0.9),
            
            instructionLabel.topAnchor.constraint(equalTo: banner.topAnchor, constant: 10),
            instructionLabel.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -10),
            instructionLabel.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 10),
            instructionLabel.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Completion
    private func completeTutorial() {
        guard let tutorial = currentTutorial else { return }
        
        // Mark tutorial as completed
        GameProgressManager.shared.markTutorialCompleted(tutorial.levelId)
        
        // Check for triggered messages
        MessageManager.shared.checkTriggeredMessages()
        
        // Clean up
        overlayView?.removeFromSuperview()
        overlayView = nil
        isActive = false
        
        // Show completion message
        showCompletionAlert()
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "Training Complete!",
            message: currentTutorial?.completionMessage ?? "Great job!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Return to Dashboard", style: .default) { [weak self] _ in
            self?.gameViewController?.navigationController?.popViewController(animated: true)
        })
        
        gameViewController?.present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        guard let tutorial = currentTutorial,
              let step = tutorial.steps[safe: currentStepIndex] else {
            return
        }
        
        // For steps that require action, validate before advancing
        if step.requiresAction {
            if validateCurrentStep() {
                advanceToNextStep()
            } else {
                // Visual feedback that validation failed
                showValidationFeedback()
            }
        } else {
            // For non-action steps, advance immediately
            advanceToNextStep()
        }
    }
    
    private func showValidationFeedback() {
        // Add visual feedback for failed validation
        guard let overlay = overlayView else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            overlay.nextButton.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                overlay.nextButton.backgroundColor = .black
            }
        }
    }
    
    // MARK: - External Events
    func handleGameStateChange() {
        guard isActive,
              let step = currentTutorial?.steps[currentStepIndex],
              step.requiresAction else {
            return
        }
        
        // Check if current step is now valid
        if validateCurrentStep() {
            advanceToNextStep()
        }
    }
}
