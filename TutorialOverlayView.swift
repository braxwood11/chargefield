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
    
    private var instructionTopConstraint: NSLayoutConstraint?
    private var instructionCenterYConstraint: NSLayoutConstraint?
    private var buttonTopConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        func setupConstraintReferences() {
            // Store references to constraints we'll need to modify
            instructionCenterYConstraint = instructionLabel.constraints.first {
                $0.firstAttribute == .centerY && $0.secondItem === self
            }
            
            buttonTopConstraint = nextButton.constraints.first {
                $0.firstAttribute == .top && $0.secondItem === instructionLabel
            }
        }
        
        // Instruction label - positioned higher in the screen
            instructionLabel.textColor = .white
            instructionLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)
            instructionLabel.numberOfLines = 0
            instructionLabel.textAlignment = .center
            instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            instructionLabel.layer.cornerRadius = 10
            instructionLabel.layer.borderWidth = 1
            instructionLabel.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
            instructionLabel.clipsToBounds = true
            instructionLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(instructionLabel)
            
            // Next button - styled like other terminal controls
            nextButton.setTitle("NEXT", for: .normal)
            nextButton.backgroundColor = UIColor.black
            nextButton.setTitleColor(.green, for: .normal)
            nextButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
            nextButton.layer.cornerRadius = 8
            nextButton.layer.borderWidth = 2
            nextButton.layer.borderColor = UIColor.green.cgColor
            nextButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(nextButton)
            
            // Highlight view
            highlightView.layer.borderColor = UIColor.green.cgColor
            highlightView.layer.borderWidth = 3
            highlightView.layer.cornerRadius = 8
            highlightView.clipsToBounds = true
            highlightView.isUserInteractionEnabled = false
            addSubview(highlightView)
            
            // Position the instruction in the middle of the screen
            // and the button a bit below it
            NSLayoutConstraint.activate([
                instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                instructionLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50), // Higher position
                instructionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
                instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
                
                nextButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                nextButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
                nextButton.widthAnchor.constraint(equalToConstant: 130),
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
            print("Setting next button action")
            print("Target: \(String(describing: target))")
            print("Selector: \(action)")
            
            // Remove any existing targets first
            nextButton.removeTarget(nil, action: nil, for: .touchUpInside)
            
            // Add the new target
            nextButton.addTarget(target, action: action, for: .touchUpInside)
            
            // Debug: Add a manual tap recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(debugButtonTap))
            nextButton.addGestureRecognizer(tapGesture)
            
            // Ensure button can be interacted with
            nextButton.isUserInteractionEnabled = true
            nextButton.isEnabled = true
        }
    
    @objc private func debugButtonTap() {
            print("DEBUG: Next button tapped manually!")
            
            // Print button details
            print("Button frame: \(nextButton.frame)")
            print("Button is user interaction enabled: \(nextButton.isUserInteractionEnabled)")
            print("Button is enabled: \(nextButton.isEnabled)")
            print("Button is in view hierarchy: \(nextButton.superview != nil)")
        }
    
    func highlightMultipleElements(_ elements: [UIView?]) {
        // Clear any existing highlights
        clearHighlight()
        
        // Create a path for all elements
        let path = UIBezierPath(rect: bounds)
        
        // Add each non-nil element to the highlight
        for element in elements.compactMap({ $0 }) {
            if let window = element.window, let elementSuperview = element.superview {
                let frameInWindow = elementSuperview.convert(element.frame, to: window)
                let frameInSelf = convert(frameInWindow, from: window)
                
                // Append this element's frame to the path
                path.append(UIBezierPath(roundedRect: frameInSelf, cornerRadius: element.layer.cornerRadius))
                
                // Create highlight border around the element
                let highlightBorder = UIView()
                highlightBorder.layer.borderColor = UIColor.yellow.cgColor
                highlightBorder.layer.borderWidth = 3
                highlightBorder.layer.cornerRadius = 8
                highlightBorder.clipsToBounds = true
                highlightBorder.frame = frameInSelf.insetBy(dx: -5, dy: -5)
                highlightBorder.backgroundColor = UIColor.clear
                highlightBorder.tag = 99999 // Use a tag to identify these views for removal
                highlightBorder.isUserInteractionEnabled = false
                addSubview(highlightBorder)
            }
        }
        
        // Create the mask layer
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath
        
        layer.mask = maskLayer
    }
    
    // Method to make the Next button more visible
    func animateNextButton() {
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.nextButton.alpha = 0.7
        }) { _ in
            self.nextButton.alpha = 1.0
        }
    }

    // Method to update button style to match terminal theme
    func updateNextButtonStyle() {
        nextButton.setTitle("NEXT", for: .normal)
        nextButton.backgroundColor = UIColor.black
        nextButton.setTitleColor(.green, for: .normal)
        nextButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        nextButton.layer.cornerRadius = 8
        nextButton.layer.borderWidth = 2
        nextButton.layer.borderColor = UIColor.green.cgColor
    }

    func adjustLayoutForTutorialStep() {
        // Update next button style to match terminal theme
        nextButton.setTitle("NEXT", for: .normal)
        nextButton.backgroundColor = UIColor.black
        nextButton.setTitleColor(.green, for: .normal)
        nextButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        nextButton.layer.cornerRadius = 8
        nextButton.layer.borderWidth = 2
        nextButton.layer.borderColor = UIColor.green.cgColor
        
        // Make button bigger and more visible
        nextButton.bounds = CGRect(x: 0, y: 0, width: 150, height: 50)
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
        
        // Remove any additional highlight borders
        subviews.filter { $0.tag == 99999 }.forEach { $0.removeFromSuperview() }
    }
    
    func positionInstructionsAtTop() {
        // Deactivate center constraint and create top constraint if needed
        instructionCenterYConstraint?.isActive = false
        
        if instructionTopConstraint == nil {
            instructionTopConstraint = instructionLabel.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor, constant: 20)
        }
        
        instructionTopConstraint?.isActive = true
        
        // Make the instruction background more visible
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        instructionLabel.layer.borderWidth = 1
        instructionLabel.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
    }

    func resetInstructionPosition() {
        // Deactivate top constraint and reactivate center constraint
        instructionTopConstraint?.isActive = false
        instructionCenterYConstraint?.isActive = true
        
        // Reset background
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
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
