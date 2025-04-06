//
//  TutorialOverlayView.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/30/25.
//

import UIKit

class TutorialOverlayView: UIView {
    public var instructionLabel = UILabel()
    public var nextButton = UIButton(type: .system)
    private var highlightView = UIView()
    private var highlightedFrame: CGRect?
    var allowFullInteraction = false
    
    private var instructionTopConstraint: NSLayoutConstraint?
    private var instructionCenterYConstraint: NSLayoutConstraint?
    private var buttonTopConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Initialize UI elements before configuring them
        nextButton = UIButton(type: .system) // This line is missing
        instructionLabel = UILabel()
        highlightView = UIView()
        
        // Instruction label setup
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
        
        // Store constraint references separately (this was missing)
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Change the constraints to position at bottom
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -160), // Position near bottom
            instructionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            nextButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            nextButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            nextButton.widthAnchor.constraint(equalToConstant: 130),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Store a reference to the bottom constraint instead of center Y
        instructionCenterYConstraint = instructionLabel.constraints.first {
            $0.firstAttribute == .bottom && $0.secondItem === safeAreaLayoutGuide
        }
        
        buttonTopConstraint = nextButton.constraints.first {
            $0.firstAttribute == .top && $0.secondItem === instructionLabel
        }
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
        
        bringSubviewToFront(instructionLabel)
            bringSubviewToFront(nextButton)
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
            
            // Make sure instruction label and next button stay on top
            bringSubviewToFront(instructionLabel)
            bringSubviewToFront(nextButton)
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
        // Remove any existing constraints
        instructionCenterYConstraint?.isActive = false
        instructionTopConstraint?.isActive = false
        
        // Remove instruction label from current position
        instructionLabel.removeFromSuperview()
        
        // Re-add it to ensure proper z-ordering
        addSubview(instructionLabel)
        
        // Create a specific frame for the instruction
        let topPadding: CGFloat = 240 // Increased further to move it down more
        let horizontalPadding: CGFloat = 20
        let width = bounds.width - (horizontalPadding * 2)
        
        // Ensure text wrapping works properly
        instructionLabel.numberOfLines = 0
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.preferredMaxLayoutWidth = width
        
        // Make sure text properly sizes
        instructionLabel.sizeToFit()
        
        // Calculate the proper height with some padding
        let calculatedHeight = instructionLabel.frame.height + 16
        
        // Position the label centered horizontally
        let xPosition = (bounds.width - width) / 2 // This ensures proper centering
        
        // Update frame with calculated position and size
        instructionLabel.frame = CGRect(
            x: xPosition,
            y: topPadding,
            width: width,
            height: calculatedHeight
        )
        
        // Make it look like a small banner
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        instructionLabel.layer.cornerRadius = 6
        instructionLabel.layer.borderWidth = 1
        instructionLabel.layer.borderColor = UIColor.green.cgColor
        
        // Hide the next button since it's not needed for this step
        nextButton.isHidden = true
    }

    func resetInstructionPosition() {
        // Deactivate top constraint and reactivate center constraint
        instructionTopConstraint?.isActive = false
        instructionCenterYConstraint?.isActive = true
        
        // Reset background
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Always allow interaction with the button
        if nextButton.frame.contains(point) {
            return true
        }
        
        // If full interaction is allowed, only intercept touches on the overlay UI elements
        if allowFullInteraction {
            return instructionLabel.frame.contains(point)
        }
        
        // Otherwise use the existing logic
        if instructionLabel.frame.contains(point) {
            return true
        }
        
        if let highlightedFrame = highlightedFrame, highlightedFrame.contains(point) {
            return false
        }
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch began in tutorial overlay")
        let point = touches.first?.location(in: self)
        print("Touch location: \(String(describing: point))")
        print("Next button frame: \(nextButton.frame)")
        
        if let point = point, nextButton.frame.contains(point) {
            print("Touch is inside button frame")
            nextButton.sendActions(for: .touchUpInside)
        }
        
        super.touchesBegan(touches, with: event)
    }
    
}
