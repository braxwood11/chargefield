//
//  TutorialManager.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/30/25.
//

import UIKit

class TutorialManager {
    enum TutorialStep: Int, CaseIterable {
        case welcome
        case explainGrid
        case explainTargetValues
        case selectStabilizer
        case tapCellToPreview
        case tapAgainToPlace
        case explainNeutralization
        case explainSuppressor
        case completeTask
        case finished
    }
    
    weak var accessProvider: TutorialAccessible?
    var currentStep: TutorialStep = .welcome
    var isActive = true
    weak var gameViewController: GameViewController?
    
    // Track which cells to highlight for each step
    func getHighlightedElement() -> Any? {
            switch currentStep {
            case .explainGrid:
                return accessProvider?.getGridView()
            case .explainTargetValues:
                return [accessProvider?.getCellView(at: 0, col: 0), accessProvider?.getCellView(at: 2, col: 2)]
            case .selectStabilizer:
                return accessProvider?.getStabilizerButton()
            case .tapCellToPreview, .tapAgainToPlace:
                return accessProvider?.getCellView(at: 0, col: 0)
            case .explainNeutralization:
                return accessProvider?.getCellView(at: 0, col: 0)
            case .explainSuppressor:
                return accessProvider?.getSuppressorButton()
            default:
                return nil
            }
        }
    
    func requiresAction() -> Bool {
        switch currentStep {
        case .selectStabilizer, .tapCellToPreview, .tapAgainToPlace,
             .explainSuppressor, .completeTask:
            return true
        case .welcome, .explainGrid, .explainTargetValues, .explainNeutralization, .finished:
            return false
        }
    }
    
    func getInstructionText() -> String {
        switch currentStep {
        case .welcome:
            return "Welcome to NeutraTech! Let's learn how to process energy anomalies."
        case .explainGrid:
            return "This grid represents a containment chamber where energy needs to be balanced."
        case .explainTargetValues:
            return "The numbers in cells are target values. You need to match these exactly."
        case .selectStabilizer:
            return "First, tap the Stabilizer (+) tool to select it."
        case .tapCellToPreview:
            return "Now tap on the top-left cell to see how it would affect the field."
        case .tapAgainToPlace:
            return "Tap the cell again to place the stabilizer."
        case .explainNeutralization:
            return "Great! The cell is now neutralized. Notice the green highlight indicating the field is balanced to zero."
        case .explainSuppressor:
            return "Now select the Suppressor (-) tool to decrease field values."
        case .completeTask:
            return "Complete the puzzle by matching all target values."
        case .finished:
            return "Great job! You've completed your training."
        }
    }
    
    func advanceToNextStep() {
        let allSteps = TutorialStep.allCases
        let currentIndex = allSteps.firstIndex(of: currentStep) ?? 0
        let nextIndex = min(currentIndex + 1, allSteps.count - 1)
        currentStep = allSteps[nextIndex]
    }
    
    func shouldAllowFullInteraction() -> Bool {
        // During the "complete task" step, allow interaction with all UI elements
        return currentStep == .completeTask
    }
}
