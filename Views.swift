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
        
        // Target value label (top-left)
        targetLabel.font = UIFont.boldSystemFont(ofSize: 12)
        targetLabel.textAlignment = .left
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position target label in top-left
        targetLabel.frame = CGRect(x: 5, y: 5, width: bounds.width / 2, height: 20)
        
        // Position current value label in bottom-right
        currentValueLabel.frame = CGRect(x: bounds.width / 2, y: bounds.height - 25, width: bounds.width / 2 - 5, height: 20)
        
        // Position magnet view in center
        magnetView.frame = CGRect(x: (bounds.width - 30) / 2, y: (bounds.height - 30) / 2, width: 30, height: 30)
        magnetSymbol.frame = magnetView.bounds
    }
    
    // Update the appearance based on cell data
    func updateAppearance() {
        guard let cell = cell else { return }
        
        // Set background color based on cell state
                if cell.targetValue != -99 && cell.currentFieldValue == cell.targetValue {
                    backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 0.50) // Vibrant green
                } else if cell.targetValue != -99 {
                    backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 1.0) // Vibrant yellow
                } else {
                    backgroundColor = .white
                }
        
        // Update border for selection
        layer.borderWidth = cell.isSelected ? 2 : 1
        layer.borderColor = cell.isSelected ? UIColor.black.cgColor : UIColor.lightGray.cgColor
        
        // Set target value if it exists
        if cell.targetValue != -99 {
            targetLabel.text = "\(cell.targetValue)"
            targetLabel.textColor = cell.targetValue < 0 ? .blue : cell.targetValue > 0 ? .red : .gray
            targetLabel.isHidden = false
        } else {
            targetLabel.isHidden = true
        }
        
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
                
                // Set color based on selected magnet type
                if selectedMagnetType == 1 {
                    selectionLayer.backgroundColor = UIColor.red.withAlphaComponent(0.4).cgColor
                } else if selectedMagnetType == -1 {
                    selectionLayer.backgroundColor = UIColor.blue.withAlphaComponent(0.4).cgColor
                } else {
                    selectionLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.2).cgColor
                }
                
                layer.addSublayer(selectionLayer)
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
                
                // Set color based on magnet type and intensity (0-3)
                let alpha = CGFloat(intensity) * 0.1 + 0.1 // 0.2 for intensity 1, 0.3 for 2, 0.4 for 3
                
                if magnetType == 1 {
                    influenceLayer.backgroundColor = UIColor.red.withAlphaComponent(alpha).cgColor
                } else if magnetType == -1 {
                    influenceLayer.backgroundColor = UIColor.blue.withAlphaComponent(alpha).cgColor
                }
                
                layer.addSublayer(influenceLayer)
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
    
    func setMessage(_ message: String) {
        messageLabel.text = message
    }
}
