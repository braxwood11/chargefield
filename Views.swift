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
    private let targetLabel = UILabel()
    private let currentValueLabel = UILabel()
    private let magnetView = UIView()
    private let magnetSymbol = UILabel()
    
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
        
        // Target value label (top-center)
        targetLabel.font = UIFont.boldSystemFont(ofSize: 12)
        targetLabel.textAlignment = .center
        addSubview(targetLabel)
        
        // Current value label (bottom-right)
        currentValueLabel.font = UIFont.systemFont(ofSize: 10)
        currentValueLabel.textAlignment = .right
        addSubview(currentValueLabel)
        
        // Magnet view (center)
        magnetView.layer.cornerRadius = 15 // Half of width/height for circle
        magnetView.isHidden = true
        addSubview(magnetView)
        
        // Magnet symbol (+ or -)
        magnetSymbol.textColor = .white
        magnetSymbol.textAlignment = .center
        magnetSymbol.font = UIFont.boldSystemFont(ofSize: 16)
        magnetView.addSubview(magnetSymbol)
        
        // Fill bar view (for gradient fill)
        fillBarView.backgroundColor = .clear
        fillBarView.isUserInteractionEnabled = false
        addSubview(fillBarView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position fill bar at bottom or side of cell - now treating it as a vertical bar
        fillBarView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        // Position elements on top of the fill bar
        // Position target label in top-center
        targetLabel.frame = CGRect(x: (bounds.width - 40) / 2, y: 5, width: 40, height: 20)
        targetLabel.textAlignment = .center
        
        // Position current value label in bottom-right
        currentValueLabel.frame = CGRect(x: bounds.width - 25, y: bounds.height - 25, width: 20, height: 20)
        
        // Position magnet view in center
        magnetView.frame = CGRect(x: (bounds.width - 30) / 2, y: (bounds.height - 30) / 2, width: 30, height: 30)
        magnetSymbol.frame = magnetView.bounds
        
        // Ensure proper z-order
        bringSubviewToFront(targetLabel)
        bringSubviewToFront(currentValueLabel)
        bringSubviewToFront(magnetView)
    }
    
    // Update the appearance based on cell data
    func updateAppearance() {
        guard let cell = cell else { return }
        
        // Set target value if it exists
        if cell.targetValue != -99 {
            targetLabel.text = "\(cell.targetValue)"
            targetLabel.textColor = cell.targetValue < 0 ? .blue : .red
            targetLabel.isHidden = false
            
            // Update charge indicators - this will set background
            updateChargeIndicators(target: cell.targetValue, current: cell.currentFieldValue)
        } else {
            targetLabel.isHidden = true
            fillBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            backgroundColor = .white
        }
        
        // Update border for selection
        layer.borderWidth = cell.isSelected ? 2 : 1
        layer.borderColor = cell.isSelected ? UIColor.black.cgColor : UIColor.lightGray.cgColor
        
        // Set current field value if hints are on
        currentValueLabel.text = "\(cell.currentFieldValue)"
        currentValueLabel.textColor = cell.currentFieldValue < 0 ? .blue : cell.currentFieldValue > 0 ? .red : .gray
        currentValueLabel.isHidden = !showHints
        
        // Show magnet if present
        if cell.magnetValue != 0 {
            magnetView.isHidden = false
            magnetView.backgroundColor = cell.magnetValue > 0 ? .red : .blue
            magnetSymbol.text = cell.magnetValue > 0 ? "+" : "-"
        } else {
            magnetView.isHidden = true
        }
        
        // Show selection overlay if selected
        updateSelectionAppearance()
    }
    
    // Update charge proximity indicators
    private func updateChargeIndicators(target: Int, current: Int) {
        // Clear existing layers
        fillBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Calculate difference and progress
        let difference = current - target
        let matched = (difference == 0)
        
        // Determine base color based on target sign
        let baseColor: UIColor = target < 0 ? .blue : .red
        
        // Draw the fill bar based on the new color scheme
        drawNewFillBar(target: target, current: current, baseColor: baseColor, matched: matched)
    }
    
    // Draw the fill bar with the new color scheme
    private func drawNewFillBar(target: Int, current: Int, baseColor: UIColor, matched: Bool) {
        // Calculate the percentage filled based on proximity to target
        let maxValue = abs(target) // Scale based on target magnitude
        var fillPercentage: CGFloat = 0.0
        let greenColor = UIColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 0.6) // Reduced opacity
        
        if matched {
            // Exactly matched - full green bar with reduced opacity
            let fillLayer = CALayer()
            fillLayer.frame = fillBarView.bounds
            fillLayer.backgroundColor = greenColor.withAlphaComponent(0.25).cgColor
            fillBarView.layer.addSublayer(fillLayer)
            
            // Update background for a matched cell
            backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 0.15) // Lighter green
            return
        }
        
        // Different color treatment based on position relative to target
        let overShooting = (target < 0 && current < target) || (target > 0 && current > target)
        let wrongDirection = (target < 0 && current > 0) || (target > 0 && current < 0)
        
        if wrongDirection {
            // Wrong direction completely (e.g., positive when should be negative)
            // Fill with opposite color but with reduced opacity
            let oppositeColor = target < 0 ? UIColor.red : UIColor.blue
            
            let fillLayer = CALayer()
            fillLayer.frame = fillBarView.bounds
            fillLayer.backgroundColor = oppositeColor.withAlphaComponent(0.2).cgColor
            fillBarView.layer.addSublayer(fillLayer)
            
            // Set background to base color with very low transparency
            backgroundColor = baseColor.withAlphaComponent(0.05)
            return
        }
        
        if overShooting {
            // Beyond target (overshooting) - reduced opacity
            let warningColor = UIColor.orange
            
            let fillLayer = CALayer()
            fillLayer.frame = fillBarView.bounds
            fillLayer.backgroundColor = warningColor.withAlphaComponent(0.2).cgColor
            fillBarView.layer.addSublayer(fillLayer)
            
            // Set background to orange with very low transparency
            backgroundColor = warningColor.withAlphaComponent(0.1)
            return
        }
        
        // Regular case - approaching target
        // Calculate how close we are to target (0 to 1)
        if target < 0 {
            // For negative targets
            fillPercentage = min(1.0, abs(CGFloat(current) / CGFloat(target)))
        } else {
            // For positive targets
            fillPercentage = min(1.0, CGFloat(current) / CGFloat(target))
        }
        
        // Base layer (colored by target sign) with reduced opacity
        let baseLayer = CALayer()
        baseLayer.frame = fillBarView.bounds
        baseLayer.backgroundColor = baseColor.withAlphaComponent(0.15).cgColor
        fillBarView.layer.addSublayer(baseLayer)
        
        // Green progress fill proportional to progress - with reduced opacity
        if fillPercentage > 0 {
            let greenLayer = CALayer()
            greenLayer.frame = CGRect(
                x: 0,
                y: fillBarView.bounds.height * (1 - fillPercentage),
                width: fillBarView.bounds.width,
                height: fillBarView.bounds.height * fillPercentage
            )
            greenLayer.backgroundColor = greenColor.withAlphaComponent(0.2).cgColor
            fillBarView.layer.addSublayer(greenLayer)
        }
        
        // Set background color based on closeness - but much more subtle
        if fillPercentage > 0.7 {
            // Close to target - very light green tint
            backgroundColor = greenColor.withAlphaComponent(0.05 + (fillPercentage - 0.7) * 0.1)
        } else {
            // Further from target - very light base color tint
            backgroundColor = baseColor.withAlphaComponent(0.05)
        }
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
    
    // Show influence preview based on intensity
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
            
            // Set color based on magnet type and intensity (0-3) - much lower opacity
            let alpha = CGFloat(intensity) * 0.05 + 0.05 // 0.1 for intensity 1, 0.15 for 2, 0.2 for 3
            
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
        }
    }
    
    // Clear influence preview
    func clearInfluence() {
        layer.sublayers?.filter { $0.name == "influenceLayer" }.forEach { $0.removeFromSuperlayer() }
    }
}

// A view for magnet selection buttons
class MagnetButton: UIButton {
    // Properties
    var magnetType: Int = 0
    var count: Int?
    
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
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        titleLabel?.numberOfLines = 2
        titleLabel?.textAlignment = .center
        layer.cornerRadius = 20
        clipsToBounds = true
    }
    
    // Configure the button for a specific magnet type
    func configure(type: Int, count: Int? = nil, isSelected: Bool) {
        self.magnetType = type
        self.count = count
        
        // Set background color based on type
        if type == 1 {
            backgroundColor = .red
            setTitle("+", for: .normal)
            setTitleColor(.white, for: .normal)
        } else if type == -1 {
            backgroundColor = .blue
            setTitle("-", for: .normal)
            setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = UIColor.lightGray
            setTitle("X", for: .normal)
            setTitleColor(.black, for: .normal)
        }
        
        // Add count text if available
        if let count = count {
            let countText = "\(count) left"
            setTitle("\n\(countText)", for: .normal)
        } else if type == 0 {
            setTitle("\nEraser", for: .normal)
        }
        
        // Show selection border
        layer.borderWidth = isSelected ? 2 : 0
        layer.borderColor = UIColor.black.cgColor
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
