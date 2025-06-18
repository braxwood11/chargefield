//
//  Views.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import UIKit

// MARK: - Custom Views

// A view for a single cell in the grid
class CellView: UIView {
    // UI Components
    private let chargeLabel = UILabel()
    private let chargeBackground = UIView()
    private let magnetView = UIView()
    private let magnetSymbol = UILabel()
    private let neutralizedIndicator = UIView()
    var previewValue: Int? = nil
    
    // Progress indicator component
    private let fillBarView = UIView()
    
    // Cell data
    var cell: MagnetCell? {
        didSet {
            updateAppearance()
        }
    }
    
    var showHints: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    var selectedMagnetType: Int = 1 {
        didSet {
            updateSelectionAppearance()
        }
    }
    
    // Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // Setup UI components
    private func setupViews() {
        // Main cell view
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        backgroundColor = .white
        
        // Fill bar view (for gradient fill)
        fillBarView.backgroundColor = .clear
        fillBarView.isUserInteractionEnabled = false
        addSubview(fillBarView)
        
        // Neutralized indicator (checkmark or visual cue for neutralized cells)
        neutralizedIndicator.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        neutralizedIndicator.layer.cornerRadius = 3
        neutralizedIndicator.isHidden = true
        addSubview(neutralizedIndicator)
        
        // Charge label background for better visibility
        chargeBackground.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        chargeBackground.layer.cornerRadius = 8
        addSubview(chargeBackground)
        
        // Charge value label (will be positioned in layoutSubviews)
        // Use a variable font size based on cell size
        chargeLabel.font = UIFont.boldSystemFont(ofSize: 12) // Will adjust size in layoutSubviews
        chargeLabel.textAlignment = .center
        addSubview(chargeLabel)
        
        // Magnet view (center)
        magnetView.layer.cornerRadius = 15 // Will adjust in layoutSubviews
        magnetView.isHidden = true
        addSubview(magnetView)
        
        // Magnet symbol (+ or -)
        magnetSymbol.textColor = .white
        magnetSymbol.textAlignment = .center
        magnetSymbol.font = UIFont.boldSystemFont(ofSize: 16) // Will adjust size in layoutSubviews
        magnetView.addSubview(magnetSymbol)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position fill bar at bottom of cell
        fillBarView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        // Position neutralized indicator as a thin border
        neutralizedIndicator.frame = bounds
        
        // Adjust size based on cell size - make them smaller for 5x5 grid
        let isSmallCell = bounds.width < 60 // For 5x5 grid
        
        // Position magnet view in center - make it smaller for 5x5 grid
        let magnetSize: CGFloat = isSmallCell ? 24 : 30
        magnetView.frame = CGRect(
            x: (bounds.width - magnetSize) / 2,
            y: (bounds.height - magnetSize) / 2,
            width: magnetSize,
            height: magnetSize
        )
        magnetView.layer.cornerRadius = magnetSize / 2
        magnetSymbol.frame = magnetView.bounds
        
        // Position charge background for better visibility - move to top left corner for small cells
        let chargeSize: CGFloat = isSmallCell ? 20 : 24
        let chargePositionX: CGFloat = isSmallCell ? 2 : bounds.width - chargeSize - 2
        let chargePositionY: CGFloat = 2
        
        chargeBackground.frame = CGRect(
            x: chargePositionX,
            y: chargePositionY,
            width: chargeSize,
            height: chargeSize
        )
        
        // Position charge label in same position
        chargeLabel.frame = chargeBackground.frame
        
        // Ensure proper z-order
        bringSubviewToFront(chargeBackground)
        bringSubviewToFront(chargeLabel)
        bringSubviewToFront(magnetView)
        
        if !magnetView.isHidden {
                ensureMagnetIsCircular()
            }
    }
    
    // Update the appearance based on cell data
    private func updateAppearance() {
        guard let cell = cell else { return }
        
        // Update charge label based on current field value
        chargeLabel.text = "\(cell.currentFieldValue)"
        
        // Set charge label color with much brighter colors
        if cell.currentFieldValue < 0 {
            chargeLabel.textColor = UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0) // Very bright blue
        } else if cell.currentFieldValue > 0 {
            chargeLabel.textColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0) // Very bright red
        } else {
            chargeLabel.textColor = UIColor.green // Match terminal theme
        }
        
        // Show charge label and background only for target cells or when hints are on
        let isTargetCell = cell.initialCharge != 0
        chargeLabel.isHidden = !isTargetCell && !showHints
        chargeBackground.isHidden = !isTargetCell && !showHints
        
        // Make charge background more transparent so colors are more visible
        chargeBackground.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        // Update border for selection
        layer.borderWidth = cell.isSelected ? 2 : 1
        layer.borderColor = cell.isSelected ? UIColor.green.cgColor : UIColor.green.withAlphaComponent(0.5).cgColor
        
        // Show magnet if present with much brighter colors
        if cell.toolEffect != 0 {
            magnetView.isHidden = false
            if cell.toolEffect > 0 {
                magnetView.backgroundColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0)
                magnetSymbol.text = "+"
            } else {
                magnetView.backgroundColor = UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
                magnetSymbol.text = "-"
            }
            
            // CRITICAL: Ensure magnet is always circular
            ensureMagnetIsCircular()
            
        } else {
            magnetView.isHidden = true
        }
        
        // Update neutralization status
        updateNeutralizationStatus()
        
        // Show selection overlay if selected
        updateSelectionAppearance()
    }
    
    private func ensureMagnetIsCircular() {
        // Reset any leftover transforms that might cause issues
        if magnetView.transform != .identity {
            magnetView.transform = .identity
        }
        
        // Recalculate and apply the correct corner radius
        let isSmallCell = bounds.width < 60
        let magnetSize: CGFloat = isSmallCell ? 24 : 30
        
        // Ensure the frame is correct
        magnetView.frame = CGRect(
            x: (bounds.width - magnetSize) / 2,
            y: (bounds.height - magnetSize) / 2,
            width: magnetSize,
            height: magnetSize
        )
        
        // Set corner radius to exactly half the width for perfect circle
        magnetView.layer.cornerRadius = magnetSize / 2
        
        // Ensure symbol is centered
        magnetSymbol.frame = magnetView.bounds
    }
    
    // Update the neutralization status and visualization
    private func updateNeutralizationStatus() {
        guard let cell = cell else { return }
        
        // Clear existing layers
        fillBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Only process cells with initial charge (target cells)
        if cell.initialCharge == 0 {
            neutralizedIndicator.isHidden = true
            backgroundColor = .white
            return
        }
        
        // Handle neutralized cells
        if cell.isNeutralized {
            neutralizedIndicator.isHidden = false
            backgroundColor = UIColor.green.withAlphaComponent(0.15)
            
            // Add checkmark or other completion indicator
            let checkLayer = CAShapeLayer()
            checkLayer.path = UIBezierPath(roundedRect: CGRect(x: 5, y: 5, width: bounds.width - 10, height: bounds.height - 10), cornerRadius: 3).cgPath
            checkLayer.strokeColor = UIColor.green.cgColor
            checkLayer.fillColor = UIColor.clear.cgColor
            checkLayer.lineWidth = 2
            fillBarView.layer.addSublayer(checkLayer)
            
            return
        }
        
        // Hide neutralized indicator for non-neutralized cells
        neutralizedIndicator.isHidden = true
        
        // Handle overshooting
        if cell.isOvershot {
            // Cell went past zero (wrong direction)
            displayOvershootState()
            return
        }
        
        // Regular progress toward neutralization
        displayNeutralizationProgress()
    }
    
    // Display the overshooting state (past zero)
    private func displayOvershootState() {
        guard let cell = cell else { return }
        
        // Background with warning color
        backgroundColor = UIColor.orange.withAlphaComponent(0.15)
        
        // Create striped pattern to indicate overshooting
        let stripeLayer = CAShapeLayer()
        
        // Create a clip path to constrain stripes within the cell bounds
        let clipPath = UIBezierPath(rect: bounds)
        stripeLayer.fillColor = nil
        
        // Create the diagonal stripes path
        let path = UIBezierPath()
        let stripeWidth: CGFloat = 5.0
        let spacing: CGFloat = 10.0
        
        // Draw diagonal lines that start from left of the cell and finish at the bottom
        for x in stride(from: -bounds.height, to: bounds.width, by: spacing) {
            let startPoint = CGPoint(x: x, y: bounds.height)
            let endPoint = CGPoint(x: min(x + bounds.height, bounds.width), y: max(0, bounds.height - (bounds.width - x)))
            
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        
        // Add stripes coming from the top
        for y in stride(from: 0, through: bounds.height, by: spacing) {
            let startPoint = CGPoint(x: 0, y: y)
            let endPoint = CGPoint(x: min(bounds.width, y), y: max(0, y - bounds.width))
            
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        
        // Apply the paths to the shape layer
        stripeLayer.path = path.cgPath
        stripeLayer.lineWidth = stripeWidth
        stripeLayer.strokeColor = UIColor.orange.withAlphaComponent(0.3).cgColor
        stripeLayer.masksToBounds = true
        stripeLayer.frame = bounds
        
        fillBarView.layer.addSublayer(stripeLayer)
        
        // Add directional arrow to indicate which way to adjust
        let arrowLayer = CAShapeLayer()
        let arrowSize: CGFloat = 15.0
        let arrowPath = UIBezierPath()
        
        // Point arrow left or right based on needed correction
        if (cell.initialCharge > 0 && cell.currentFieldValue < 0) {
            // Need to add more positive charge
            arrowPath.move(to: CGPoint(x: bounds.width/2 - arrowSize, y: bounds.height/2))
            arrowPath.addLine(to: CGPoint(x: bounds.width/2 + arrowSize, y: bounds.height/2))
            arrowPath.addLine(to: CGPoint(x: bounds.width/2, y: bounds.height/2 - arrowSize/2))
            arrowPath.close()
        } else {
            // Need to add more negative charge
            arrowPath.move(to: CGPoint(x: bounds.width/2 + arrowSize, y: bounds.height/2))
            arrowPath.addLine(to: CGPoint(x: bounds.width/2 - arrowSize, y: bounds.height/2))
            arrowPath.addLine(to: CGPoint(x: bounds.width/2, y: bounds.height/2 - arrowSize/2))
            arrowPath.close()
        }
        
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.fillColor = UIColor.orange.withAlphaComponent(0.5).cgColor
        arrowLayer.masksToBounds = true
        
        fillBarView.layer.addSublayer(arrowLayer)
    }
    
    // Display progress toward neutralization
    private func displayNeutralizationProgress() {
        guard let cell = cell else { return }
        
        // Calculate progress percentage
        let initialAbsValue = abs(cell.initialCharge)
        let currentAbsValue = abs(cell.currentFieldValue)
        let progressPercentage = initialAbsValue > 0 ? 1.0 - (Double(currentAbsValue) / Double(initialAbsValue)) : 0.0
        
        // Use brighter base colors
        let baseColor: UIColor = cell.initialCharge < 0 ?
            UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0) : // Bright blue
            UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)   // Bright red
        
        let progressColor = UIColor.green.withAlphaComponent(0.4)
        
        // Use lighter cell background to let colors stand out
        backgroundColor = .white // Match terminal theme
        
        // Base layer with reduced opacity to make colors more visible
        let baseLayer = CALayer()
        baseLayer.frame = fillBarView.bounds
        baseLayer.backgroundColor = baseColor.withAlphaComponent(0.3).cgColor // More visible
        fillBarView.layer.addSublayer(baseLayer)
        
        // Progress layer (green progress toward neutralization)
        if progressPercentage > 0 {
            let progressLayer = CALayer()
            progressLayer.frame = CGRect(
                x: 0,
                y: fillBarView.bounds.height * (1 - CGFloat(progressPercentage)),
                width: fillBarView.bounds.width,
                height: fillBarView.bounds.height * CGFloat(progressPercentage)
            )
            progressLayer.backgroundColor = progressColor.cgColor
            fillBarView.layer.addSublayer(progressLayer)
        }
        
        // Add remaining value indicator (shows how much is left to neutralize)
        if showHints && progressPercentage < 1.0 {
            // Calculate the remaining value needed
            let remainingValue = cell.initialCharge > 0 ? cell.currentFieldValue : -cell.currentFieldValue
            
            // Create a small label to show the remaining charge
            let remainingLayer = CATextLayer()
            remainingLayer.string = "\(remainingValue)"
            remainingLayer.fontSize = 10
            remainingLayer.alignmentMode = .center
            remainingLayer.foregroundColor = cell.initialCharge > 0 ? UIColor.red.cgColor : UIColor.blue.cgColor
            remainingLayer.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
            remainingLayer.cornerRadius = 3
            remainingLayer.contentsScale = UIScreen.main.scale
            
            // Position at the bottom-left
            remainingLayer.frame = CGRect(x: 4, y: bounds.height - 16, width: 20, height: 12)
            
            fillBarView.layer.addSublayer(remainingLayer)
        }
        
        // Set background color based on progress
        if progressPercentage > 0.7 {
            // Close to neutralized - light green tint
            backgroundColor = UIColor.green.withAlphaComponent(0.05 + (progressPercentage - 0.7) * 0.1)
        } else {
            // Further from neutralized - very light base color tint
            backgroundColor = baseColor.withAlphaComponent(0.05)
        }
        
        // Add pulsing animation for cells that are close to being neutralized
        if progressPercentage > 0.8 && progressPercentage < 1.0 {
            addPulsingAnimation()
        }
    }
    
    // Add pulsing animation for cells close to neutralization
    private func addPulsingAnimation() {
        let pulseLayer = CAShapeLayer()
        pulseLayer.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), cornerRadius: 3).cgPath
        pulseLayer.strokeColor = UIColor.green.cgColor
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.lineWidth = 1.5
        pulseLayer.name = "pulseLayer"
        
        // Create pulsing animation
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.8
        animation.toValue = 0.2
        animation.duration = 1.0
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        
        pulseLayer.add(animation, forKey: "pulseAnimation")
        fillBarView.layer.addSublayer(pulseLayer)
    }
    
    // Update the appearance based on selection state
    func updateSelectionAppearance() {
        // Remove existing selection layer if any
        layer.sublayers?.filter { $0.name == "selectionLayer" }.forEach { $0.removeFromSuperlayer() }
        
        guard let cell = cell else { return }
        
        // Create new selection layer if needed
        if cell.isSelected {
            let selectionLayer = CALayer()
            selectionLayer.frame = bounds
            selectionLayer.name = "selectionLayer"
            
            // Set color based on selected magnet type - much lower opacity
            if selectedMagnetType == 1 {
                selectionLayer.backgroundColor = UIColor.red.withAlphaComponent(0.15).cgColor
                selectionLayer.borderColor = UIColor.red.withAlphaComponent(0.5).cgColor
                selectionLayer.borderWidth = 2
            } else if selectedMagnetType == -1 {
                selectionLayer.backgroundColor = UIColor.blue.withAlphaComponent(0.15).cgColor
                selectionLayer.borderColor = UIColor.blue.withAlphaComponent(0.5).cgColor
                selectionLayer.borderWidth = 2
            } else {
                selectionLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.1).cgColor
                selectionLayer.borderColor = UIColor.gray.withAlphaComponent(0.4).cgColor
                selectionLayer.borderWidth = 2
            }
            
            layer.insertSublayer(selectionLayer, at: 0)  // Insert at bottom
        }
    }
    
    func showInfluence(intensity: Int, magnetType: Int) {
        // Only show influence preview if not selected
        guard let cell = cell, !cell.isSelected else { return }
        
        // Remove existing influence layer if any
        layer.sublayers?.filter { $0.name == "influenceLayer" }.forEach { $0.removeFromSuperlayer() }
        
        // Create influence layer if needed
        if intensity > 0 {
            let influenceLayer = CALayer()
            influenceLayer.frame = bounds
            influenceLayer.name = "influenceLayer"
            
            // Set color based on magnet type and intensity - show for ALL cells
            let alpha = CGFloat(intensity) * 0.05 + 0.05
            
            if magnetType == 1 {
                influenceLayer.backgroundColor = UIColor.red.withAlphaComponent(alpha).cgColor
                influenceLayer.borderColor = UIColor.red.withAlphaComponent(alpha * 2).cgColor
                influenceLayer.borderWidth = 1
            } else if magnetType == -1 {
                influenceLayer.backgroundColor = UIColor.blue.withAlphaComponent(alpha).cgColor
                influenceLayer.borderColor = UIColor.blue.withAlphaComponent(alpha * 2).cgColor
                influenceLayer.borderWidth = 1
            }
            
            layer.insertSublayer(influenceLayer, at: 0)  // Insert at bottom
            
            // Show numerical impact ONLY for cells with initial charge
            if cell.initialCharge != 0 {
                // Calculate the influence value
                let influenceValue = intensity * magnetType
                
                // Create a label to show the potential change
                let impactLayer = CATextLayer()
                let sign = influenceValue > 0 ? "+" : ""
                impactLayer.string = "\(sign)\(influenceValue)"
                impactLayer.fontSize = 12
                impactLayer.alignmentMode = .center
                impactLayer.foregroundColor = magnetType > 0 ? UIColor.red.cgColor : UIColor.blue.cgColor
                impactLayer.backgroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
                impactLayer.cornerRadius = 4
                impactLayer.contentsScale = UIScreen.main.scale
                
                // Position in the center
                impactLayer.frame = CGRect(
                    x: (bounds.width - 30) / 2,
                    y: (bounds.height - 20) / 2,
                    width: 30,
                    height: 20
                )
                
                influenceLayer.addSublayer(impactLayer)
            }
        }
    }

    func showCentralMagnetInfluence(magnetType: Int) {
        // This special method shows the ±3 influence for the central cell
        // even when it's selected
        
        // Remove existing influence layer if any
        layer.sublayers?.filter { $0.name == "influenceLayer" }.forEach { $0.removeFromSuperlayer() }
        
        // Create influence layer
        let influenceLayer = CALayer()
        influenceLayer.frame = bounds
        influenceLayer.name = "influenceLayer"
        
        // Set color based on magnet type
        let alpha = 0.2  // Stronger alpha for the central cell
        
        if magnetType == 1 {
            influenceLayer.backgroundColor = UIColor.red.withAlphaComponent(alpha).cgColor
            influenceLayer.borderColor = UIColor.red.withAlphaComponent(alpha * 2).cgColor
            influenceLayer.borderWidth = 1
        } else if magnetType == -1 {
            influenceLayer.backgroundColor = UIColor.blue.withAlphaComponent(alpha).cgColor
            influenceLayer.borderColor = UIColor.blue.withAlphaComponent(alpha * 2).cgColor
            influenceLayer.borderWidth = 1
        }
        
        layer.insertSublayer(influenceLayer, at: 0)
        
        // Add a label showing the ±3 value
        let valueLayer = CATextLayer()
        let value = 3 * magnetType
        let sign = value > 0 ? "+" : ""
        valueLayer.string = "\(sign)\(value)"
        valueLayer.fontSize = 14
        valueLayer.alignmentMode = .center
        valueLayer.foregroundColor = magnetType > 0 ? UIColor.red.cgColor : UIColor.blue.cgColor
        valueLayer.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
        valueLayer.cornerRadius = 4
        valueLayer.contentsScale = UIScreen.main.scale
        
        // Position in the center
        valueLayer.frame = CGRect(
            x: (bounds.width - 30) / 2,
            y: (bounds.height - 20) / 2,
            width: 30,
            height: 20
        )
        
        influenceLayer.addSublayer(valueLayer)
    }

    
    func clearInfluence() {
        layer.sublayers?.filter { $0.name == "influenceLayer" }.forEach { $0.removeFromSuperlayer() }
        previewValue = nil
    }
    
    // MARK: - Animation Methods
    
    /// Prepare magnet for animation without showing it
    func prepareMagnetForAnimation(magnetType: Int) {
        // Update the cell's underlying data but don't show the magnet yet
        updateMagnetAppearance(magnetType: magnetType)
        
        // Store the current corner radius before hiding
        let currentCornerRadius = magnetView.layer.cornerRadius
        
        magnetView.isHidden = true
        magnetView.alpha = 0
        magnetView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        // Scale down the corner radius to match the small transform
        magnetView.layer.cornerRadius = currentCornerRadius * 0.1
    }

    /// Animate magnet placement with magnetic snap effect
    func animateMagnetPlacement(magnetType: Int, completion: (() -> Void)? = nil) {
        // Store original state
        let originalTransform = magnetView.transform
        let originalAlpha = magnetView.alpha
        
        // Start with magnet completely hidden - DON'T show it yet
        magnetView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        magnetView.alpha = 0
        magnetView.isHidden = true // Keep it hidden until animation starts
        
        // Update magnet appearance but keep it hidden
        updateMagnetAppearance(magnetType: magnetType)
        
        // Store the original corner radius
        let originalCornerRadius = magnetView.layer.cornerRadius
        
        // Create placement effect with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Show the magnet only when animation starts
        magnetView.isHidden = false
        
        // Scale the corner radius down for the initial small state
        magnetView.layer.cornerRadius = originalCornerRadius * 0.1
        
        // Magnetic snap animation with bounce
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.magnetView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.magnetView.alpha = 1.0
            // Scale corner radius up to slightly larger than normal
            self.magnetView.layer.cornerRadius = originalCornerRadius * 1.1
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.magnetView.transform = originalTransform
                // Reset corner radius to normal
                self.magnetView.layer.cornerRadius = originalCornerRadius
            } completion: { _ in
                // Call completion AFTER the magnet has actually appeared
                completion?()
            }
        }
        
        // Add glow effect
        addPlacementGlow(magnetType: magnetType)
    }
    
    /// Animate magnet removal with dissolution effect
    func animateMagnetRemoval(completion: (() -> Void)? = nil) {
            guard !magnetView.isHidden else {
                completion?()
                return
            }
            
            // Light haptic feedback for removal
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Create particle dissolution effect
            createRemovalParticles()
            
            // Scale down and fade out
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                self.magnetView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.magnetView.alpha = 0
            } completion: { _ in
                self.magnetView.isHidden = true
                self.magnetView.transform = .identity
                self.magnetView.alpha = 1.0
                completion?()
            }
        }
    
    /// Animate field influence effect on affected cells
    func animateFieldInfluence(intensity: Int, magnetType: Int) {
        // Create ripple effect
        let rippleView = UIView()
        rippleView.backgroundColor = magnetType == 1 ?
            UIColor.red.withAlphaComponent(0.3) :
            UIColor.blue.withAlphaComponent(0.3)
        rippleView.layer.cornerRadius = 4
        rippleView.frame = bounds.insetBy(dx: 4, dy: 4)
        rippleView.alpha = 0
        addSubview(rippleView)
        
        // Brief highlight animation
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            rippleView.alpha = 0.6
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                rippleView.alpha = 0
                rippleView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } completion: { _ in
                rippleView.removeFromSuperview()
            }
        }
    }
    
    /// Animate successful neutralization with green success effect
    func animateNeutralizationSuccess() {
        // Create success flash
        let successFlash = UIView()
        successFlash.backgroundColor = UIColor.green.withAlphaComponent(0.6)
        successFlash.layer.cornerRadius = 4
        successFlash.frame = bounds
        successFlash.alpha = 0
        addSubview(successFlash)
        
        // Success particle burst
        createSuccessParticles()
        
        // Flash animation
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            successFlash.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                successFlash.alpha = 0
            } completion: { _ in
                successFlash.removeFromSuperview()
            }
        }
        
        // Scale pulse for emphasis
        let originalTransform = transform
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                self.transform = originalTransform
            }
        }
        
        // Medium haptic feedback for success
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Animate overshoot warning with orange shake effect
    func animateOvershootWarning() {
        // Create warning flash
        let warningFlash = UIView()
        warningFlash.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        warningFlash.layer.cornerRadius = 4
        warningFlash.frame = bounds
        warningFlash.alpha = 0
        addSubview(warningFlash)
        
        // Warning shake animation
        let shakeAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        shakeAnimation.fromValue = -3
        shakeAnimation.toValue = 3
        shakeAnimation.duration = 0.1
        shakeAnimation.autoreverses = true
        shakeAnimation.repeatCount = 3
        
        layer.add(shakeAnimation, forKey: "overshootShake")
        
        // Flash animation
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            warningFlash.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                warningFlash.alpha = 0
            } completion: { _ in
                warningFlash.removeFromSuperview()
            }
        }
        
        // Light haptic feedback for warning
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Animate incremental value change with subtle number effect
    func animateValueChange(from oldValue: Int, to newValue: Int) {
        // Animate the charge label with a subtle scale effect
        let originalTransform = chargeLabel.transform
        
        // Brief scale up then back down
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.chargeLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        } completion: { _ in
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
                self.chargeLabel.transform = originalTransform
            }
        }
        
        // Color flash based on change direction
        let originalColor = chargeLabel.textColor
        let flashColor = newValue > oldValue ?
            UIColor.red.withAlphaComponent(0.8) :
            UIColor.blue.withAlphaComponent(0.8)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.chargeLabel.textColor = flashColor
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                self.chargeLabel.textColor = originalColor
            }
        }
        
        // Create subtle number change particles
        if abs(newValue - oldValue) > 1 {
            createValueChangeParticles(changeAmount: newValue - oldValue)
        }
    }
    
    // MARK: - Private Animation Helpers
    
    private func updateMagnetAppearance(magnetType: Int) {
        if magnetType > 0 {
            magnetView.backgroundColor = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0)
            magnetSymbol.text = "+"
        } else {
            magnetView.backgroundColor = UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
            magnetSymbol.text = "-"
        }
        
        // Ensure the magnet stays circular by updating corner radius
        // This should match the calculation from layoutSubviews
        let isSmallCell = bounds.width < 60
        let magnetSize: CGFloat = isSmallCell ? 24 : 30
        magnetView.layer.cornerRadius = magnetSize / 2
    }
    
    // Add the giant flash effect method
    private func createGiantFlashEffect(magnetType: Int) {
        // Create a large flash view that covers the entire cell and beyond
        let flashView = UIView()
        flashView.backgroundColor = magnetType == 1 ?
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8) :  // Bright red
            UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.8)    // Bright blue
        
        // Make it much larger than the cell
        flashView.frame = bounds.insetBy(dx: -20, dy: -20)
        flashView.layer.cornerRadius = flashView.frame.width / 2
        flashView.alpha = 0
        insertSubview(flashView, at: 0) // Behind the magnet
        
        // Giant flash animation - quick bright flash then fade
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            flashView.alpha = 1.0
            flashView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                flashView.alpha = 0
                flashView.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
            } completion: { _ in
                flashView.removeFromSuperview()
            }
        }
    }
    
    private func addPlacementGlow(magnetType: Int) {
        // Create temporary glow effect
        let glowView = UIView()
        glowView.backgroundColor = magnetType == 1 ?
            UIColor.red.withAlphaComponent(0.1) :
            UIColor.blue.withAlphaComponent(0.1)
        glowView.layer.cornerRadius = bounds.width / 2
        glowView.frame = bounds.insetBy(dx: -5, dy: -5)
        glowView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        insertSubview(glowView, at: 0)
        
        // Glow animation
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut) {
            glowView.alpha = 0
            glowView.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        } completion: { _ in
            glowView.removeFromSuperview()
        }
    }
    
    private func createRemovalParticles() {
        let particleCount = 6
        let magnetCenter = CGPoint(x: magnetView.center.x, y: magnetView.center.y)
        
        for i in 0..<particleCount {
            let particle = UIView()
            particle.backgroundColor = magnetView.backgroundColor
            particle.frame = CGRect(x: 0, y: 0, width: 3, height: 3)
            particle.layer.cornerRadius = 1.5
            particle.center = magnetCenter
            addSubview(particle)
            
            // Random direction and distance
            let angle = Double(i) * (2 * Double.pi / Double(particleCount))
            let distance: CGFloat = 20
            let endX = magnetCenter.x + cos(angle) * distance
            let endY = magnetCenter.y + sin(angle) * distance
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                particle.center = CGPoint(x: endX, y: endY)
                particle.alpha = 0
                particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            } completion: { _ in
                particle.removeFromSuperview()
            }
        }
    }
    
    private func createSuccessParticles() {
        let particleCount = 8
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        
        for i in 0..<particleCount {
            let particle = UIView()
            particle.backgroundColor = UIColor.green
            particle.frame = CGRect(x: 0, y: 0, width: 2, height: 2)
            particle.layer.cornerRadius = 1
            particle.center = centerPoint
            particle.alpha = 0.8
            addSubview(particle)
            
            // Random direction and distance
            let angle = Double(i) * (2 * Double.pi / Double(particleCount)) + Double.random(in: -0.2...0.2)
            let distance: CGFloat = CGFloat.random(in: 15...25)
            let endX = centerPoint.x + CGFloat(cos(angle)) * distance
            let endY = centerPoint.y + CGFloat(sin(angle)) * distance
            
            UIView.animate(withDuration: 0.4, delay: Double.random(in: 0...0.1), options: .curveEaseOut) {
                particle.center = CGPoint(x: endX, y: endY)
                particle.alpha = 0
                particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            } completion: { _ in
                particle.removeFromSuperview()
            }
        }
    }

    private func createValueChangeParticles(changeAmount: Int) {
        let particleCount = min(abs(changeAmount), 4) // Limit particles based on change amount
        let centerPoint = CGPoint(x: chargeLabel.center.x, y: chargeLabel.center.y)
        let particleColor = changeAmount > 0 ? UIColor.red : UIColor.blue
        
        for i in 0..<particleCount {
            let particle = UIView()
            particle.backgroundColor = particleColor.withAlphaComponent(0.6)
            particle.frame = CGRect(x: 0, y: 0, width: 1.5, height: 1.5)
            particle.layer.cornerRadius = 0.75
            particle.center = centerPoint
            particle.alpha = 0.7
            addSubview(particle)
            
            // Small random movement
            let angle = Double.random(in: 0...(2 * Double.pi))
            let distance: CGFloat = CGFloat.random(in: 8...15)
            let endX = centerPoint.x + CGFloat(cos(angle)) * distance
            let endY = centerPoint.y + CGFloat(sin(angle)) * distance
            
            UIView.animate(withDuration: 0.3, delay: Double.random(in: 0...0.05), options: .curveEaseOut) {
                particle.center = CGPoint(x: endX, y: endY)
                particle.alpha = 0
            } completion: { _ in
                particle.removeFromSuperview()
            }
        }
    }
}

// A simple message view for showing completion or information
class MessageView: UIView {
    private let messageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.green.withAlphaComponent(0.2)
        layer.cornerRadius = 8
        
        messageLabel.textAlignment = .center
        messageLabel.textColor = .green
        messageLabel.font = UIFont.boldSystemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        
        addSubview(messageLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.frame = bounds.insetBy(dx: 10, dy: 10)
    }
    
    // Public method to set the message text
    func setMessage(_ message: String) {
        messageLabel.text = message
    }
}

// A view for magnet selection buttons with improved design
class MagnetButton: UIButton {
    // Properties
    var toolType: Int = 0
    var count: Int?
    
    // UI elements
    private let symbolLabel = UILabel()
    private let countLabel = UILabel()
    
    // Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        // Button setup
        layer.cornerRadius = 20
        clipsToBounds = true
        
        // Setup symbol label (+ or -)
        symbolLabel.textAlignment = .center
        symbolLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        symbolLabel.textColor = .white
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolLabel)
        
        // Setup count label
        countLabel.textAlignment = .center
        countLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        countLabel.textColor = .white
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        
        // Position labels
        NSLayoutConstraint.activate([
            symbolLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -15),
            
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            countLabel.widthAnchor.constraint(equalToConstant: 80),
            countLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // Configure the button for a specific magnet type
    func configure(type: Int, count: Int? = nil, isSelected: Bool) {
        self.toolType = type
        self.count = count
        
        // Set background and text colors to match terminal theme
            backgroundColor = .black
        
        // Set symbol
        if type == 1 {
                symbolLabel.textColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) // Bright red
                symbolLabel.text = "+"
            } else if type == -1 {
                symbolLabel.textColor = UIColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 1.0) // Bright blue
                symbolLabel.text = "−"  // Using unicode minus sign for better appearance
            } else {
                symbolLabel.textColor = .lightGray
                symbolLabel.text = "✕"  // Using unicode multiplication sign for X
            }
        
        // Set count text if available
        if let count = count {
            countLabel.text = "\(count) left"
            countLabel.textColor = .green // Terminal theme
            countLabel.isHidden = false
        } else {
            countLabel.isHidden = true
        }
        
        // Show selection with terminal-style highlight
            if isSelected {
                // Increase border width for more visibility
                layer.borderWidth = 3
                layer.borderColor = UIColor.green.cgColor
                
                // Add a subtle glow effect
                layer.shadowColor = UIColor.green.cgColor
                layer.shadowOffset = CGSize.zero
                layer.shadowRadius = 8
                layer.shadowOpacity = 0.6
            } else {
                // Reset border when not selected
                layer.borderWidth = 2
                layer.borderColor = UIColor.green.withAlphaComponent(0.4).cgColor
                layer.shadowOpacity = 0
            }
        }
}

// Add these extensions at the end of Views.swift
extension CellView {
    func updateStyleForTerminalTheme() {
        // Update cell background to black
        backgroundColor = .white
        
        // Update border
        layer.borderWidth = 1
        layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
        
        // Update label styles
        chargeLabel.font = UIFont.monospacedSystemFont(ofSize: chargeLabel.font.pointSize, weight: .bold)
        
        // Update cell look
        updateAppearance()
    }
    
    // We can't actually override updateAppearance since it's not marked as open/public
    // Instead, modify the original updateAppearance method to include terminal styling
}

extension MessageView {
    func updateStyleForTerminalTheme() {
        backgroundColor = UIColor.black
        layer.borderColor = UIColor.green.cgColor
        layer.borderWidth = 1
        
        // Update label style
        messageLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        messageLabel.textColor = .green
    }
}
