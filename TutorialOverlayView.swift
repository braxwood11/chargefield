//
//  TutorialOverlayView.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/30/25.
//

import UIKit

class TutorialOverlayView: UIView {
    private let instructionLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let highlightView = UIView()
    private var highlightedFrame: CGRect?
    var allowFullInteraction = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Instruction label
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        instructionLabel.layer.cornerRadius = 10
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nextButton)
        
        // Highlight view - will be positioned over the element to highlight
        highlightView.layer.borderColor = UIColor.yellow.cgColor
        highlightView.layer.borderWidth = 3
        highlightView.layer.cornerRadius = 8
        highlightView.clipsToBounds = true
        highlightView.isUserInteractionEnabled = false
        addSubview(highlightView)
        
        // Set constraints for instruction label and next button
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
            instructionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            nextButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setInstructionText(_ text: String) {
        instructionLabel.text = "  \(text)  "
    }
    
    func setNextButtonAction(_ target: Any?, action: Selector) {
        nextButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    func highlightElement(_ element: UIView) {
            // Convert the element's frame to this view's coordinate system
            if let window = element.window, let elementSuperview = element.superview {
                let frameInWindow = elementSuperview.convert(element.frame, to: window)
                let frameInSelf = convert(frameInWindow, from: window)
                
                // Store the highlighted frame
                highlightedFrame = frameInSelf
                
                // Position highlight view around the element
                highlightView.frame = frameInSelf.insetBy(dx: -5, dy: -5)
    
                
                // Create a circular hole in the overlay to show the element
                let path = UIBezierPath(rect: bounds)
                path.append(UIBezierPath(roundedRect: frameInSelf, cornerRadius: element.layer.cornerRadius))
                
                let maskLayer = CAShapeLayer()
                maskLayer.fillRule = .evenOdd
                maskLayer.path = path.cgPath
                
                layer.mask = maskLayer
                
                // Show the highlight view
                highlightView.isHidden = false
            }
        }
    
    func showNextButton(_ show: Bool) {
        nextButton.isHidden = !show
    }
    
    func clearHighlight() {
            layer.mask = nil
            highlightView.isHidden = true
            highlightedFrame = nil
        }
    
    func positionInstructionsAtTop() {
        // Remove existing constraints
        instructionLabel.removeFromSuperview()
        addSubview(instructionLabel)
        
        // Clear existing constraints
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(instructionLabel.constraints)
        
        // Position at top of screen
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 70),
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // Make the instruction background more visible against clear overlay
        instructionLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.9)
    }

    func resetInstructionPosition() {
        // Remove existing constraints
        instructionLabel.removeFromSuperview()
        addSubview(instructionLabel)
        
        // Reset to original position
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(instructionLabel.constraints)
        
        // Original position (center of screen or above next button)
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
            instructionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        // Reset background
        instructionLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            // If full interaction is allowed, only intercept touches on the overlay UI elements
            if allowFullInteraction {
                return nextButton.frame.contains(point) || instructionLabel.frame.contains(point)
            }
            
            // Otherwise use the existing logic
            if nextButton.frame.contains(point) || instructionLabel.frame.contains(point) {
                return true
            }
            
            if let highlightedFrame = highlightedFrame, highlightedFrame.contains(point) {
                return false
            }
            
            return true
        }
    
}
