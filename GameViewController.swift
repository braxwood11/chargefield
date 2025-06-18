//
//  GameViewController.swift
//  ChargeField
//
//  Created by Braxton Smallwood on 3/20/25.
//

import UIKit

class GameViewController: UIViewController {
    
    // MARK: - Properties
    private(set) var viewModel: GameViewModel?
    private var fieldCalculator: FieldCalculator?
    private var tutorialCoordinator: TutorialCoordinator?
    private var animationController: GameAnimationController?
    private var gameSession: GameSession?
    
    // Animation state tracking
    private var cellsBeingAnimated: Set<GridPosition> = []
    
    // MARK: - UI Properties
    private var cellViews: [[CellView]] = []
    private(set) var gridView: UIView?
    private(set) var positiveButton: MagnetButton?
    private(set) var negativeButton: MagnetButton?
    private var resetButton: UIButton?
    private var solutionButton: UIButton?
    private(set) var messageView: MessageView?
    private(set) var progressBar: UIProgressView?
    private(set) var progressLabel: UILabel?
    
    // MARK: - Configuration
    var isLaunchedFromDashboard = false
    var tutorialId: String?
    var tutorialCompleted = false
    
    // MARK: - Initialization
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
        setupGestureRecognizers()
        
        // Initialize components
        animationController = GameAnimationController(viewController: self)
        
        // Configure view model if set
        if let viewModel = viewModel {
            configureWithViewModel(viewModel)
        }
    }
    
    /// Mark affected cells as being animated to prevent premature visual updates
    private func markAffectedCellsAsAnimating(sourceRow: Int, sourceCol: Int) {
        guard let viewModel = viewModel else { return }
        
        let influenceArea = viewModel.getInfluenceArea(for: sourceRow, col: sourceCol)
        
        for row in 0..<influenceArea.count {
            for col in 0..<influenceArea[row].count {
                if influenceArea[row][col] && row < cellViews.count && col < cellViews[row].count {
                    cellsBeingAnimated.insert(GridPosition(row: row, col: col))
                }
            }
        }
    }
    
    /// Clear all animation tracking
    private func clearAnimationTracking() {
        cellsBeingAnimated.removeAll()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCellViews()
        updateUI()
        
        if isLaunchedFromDashboard, let tutorialId = tutorialId, tutorialCoordinator == nil {
                setupTutorial(tutorialId)
            }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCellViews()
    }
    
    deinit {
        // Save current game state if needed
        if let session = gameSession,
           let viewModel = viewModel,
           !viewModel.isPuzzleSolved() {
            GameProgressManager.shared.savePuzzleState(
                from: viewModel.getGameStateForSaving(),
                puzzleId: session.puzzleId,
                puzzleType: session.puzzleType,
                difficulty: session.difficulty,
                timeSpent: session.elapsedTime
            )
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Apply terminal theme
        TerminalTheme.applyBackground(to: self)
        
        // Create UI components using builders
        let statusContainer = ViewBuilder.buildStatusContainer()
        view.addSubview(statusContainer)
        
        // Message view
        messageView = MessageView(frame: .zero)
        messageView?.setMessage("⚡ ALL FIELDS NEUTRALIZED ⚡")
        messageView?.translatesAutoresizingMaskIntoConstraints = false
        messageView?.isHidden = true
        messageView?.updateStyleForTerminalTheme()
        if let messageView = messageView {
            view.addSubview(messageView)
        }
        
        // Grid
        setupGrid()
        
        // Control buttons
        setupMagnetButtons()
        setupControlButtons()
        
        // Progress bar
        progressBar = ViewBuilder.buildProgressBar()
        progressLabel = ViewBuilder.buildProgressLabel()
        if let progressBar = progressBar, let progressLabel = progressLabel {
            view.addSubview(progressBar)
            view.addSubview(progressLabel)
        }
        
        // Layout constraints
        setupConstraints(statusContainer: statusContainer)
    }
    
    private func setupNavigationBar() {
        // Custom back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(returnToDashboard)
        )
        backButton.tintColor = TerminalTheme.Colors.primaryGreen
        navigationItem.leftBarButtonItem = backButton
        
        // Title
        title = "CONTAINMENT CHAMBER"
        TerminalTheme.styleNavigationBar(navigationController?.navigationBar)
    }
    
    private func setupGrid() {
        gridView = ViewBuilder.buildGridView()
        if let gridView = gridView {
            view.addSubview(gridView)
        }
    }
    
    private func setupMagnetButtons() {
        positiveButton = MagnetButton(frame: .zero)
        negativeButton = MagnetButton(frame: .zero)
        
        guard let positiveButton = positiveButton,
              let negativeButton = negativeButton else { return }
        
        positiveButton.translatesAutoresizingMaskIntoConstraints = false
        negativeButton.translatesAutoresizingMaskIntoConstraints = false
        
        positiveButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
        negativeButton.addTarget(self, action: #selector(magnetButtonTapped(_:)), for: .touchUpInside)
        
        view.addSubview(positiveButton)
        view.addSubview(negativeButton)
        
        updateMagnetButtonsStyle()
    }
    
    private func setupControlButtons() {
        solutionButton = ViewBuilder.buildControlButton(
            icon: "puzzlepiece.fill",
            action: #selector(solutionButtonTapped),
            target: self
        )
        
        resetButton = ViewBuilder.buildControlButton(
            icon: "arrow.counterclockwise",
            action: #selector(resetButtonTapped),
            target: self
        )
        
        if let solutionButton = solutionButton, let resetButton = resetButton {
            view.addSubview(solutionButton)
            view.addSubview(resetButton)
        }
    }
    
    private func setupGestureRecognizers() {
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(backgroundTapGesture)
    }
    
    private func setupConstraints(statusContainer: UIView) {
        guard let messageView = messageView,
              let gridView = gridView,
              let positiveButton = positiveButton,
              let negativeButton = negativeButton,
              let solutionButton = solutionButton,
              let resetButton = resetButton,
              let progressBar = progressBar,
              let progressLabel = progressLabel else { return }
        
        NSLayoutConstraint.activate([
            // Status container
            statusContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            statusContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Message view
            messageView.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 10),
            messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Grid
            gridView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 20),
            gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridView.widthAnchor.constraint(equalToConstant: 300),
            gridView.heightAnchor.constraint(equalToConstant: 300),
            
            // Magnet buttons
            positiveButton.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 40),
            positiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            positiveButton.widthAnchor.constraint(equalToConstant: 100),
            positiveButton.heightAnchor.constraint(equalToConstant: 100),
            
            negativeButton.topAnchor.constraint(equalTo: positiveButton.topAnchor),
            negativeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),
            negativeButton.widthAnchor.constraint(equalToConstant: 100),
            negativeButton.heightAnchor.constraint(equalToConstant: 100),
            
            // Control buttons
            solutionButton.centerYAnchor.constraint(equalTo: positiveButton.centerYAnchor),
            solutionButton.trailingAnchor.constraint(equalTo: positiveButton.leadingAnchor, constant: -25),
            solutionButton.widthAnchor.constraint(equalToConstant: 60),
            solutionButton.heightAnchor.constraint(equalToConstant: 60),
            
            resetButton.centerYAnchor.constraint(equalTo: positiveButton.centerYAnchor),
            resetButton.leadingAnchor.constraint(equalTo: negativeButton.trailingAnchor, constant: 25),
            resetButton.widthAnchor.constraint(equalToConstant: 60),
            resetButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Progress bar
            progressBar.topAnchor.constraint(equalTo: positiveButton.bottomAnchor, constant: 30),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressBar.heightAnchor.constraint(equalToConstant: 12),
            
            // Progress label
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 4),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - Public Methods
    func setViewModel(_ newViewModel: GameViewModel) {
        self.viewModel = newViewModel
        configureWithViewModel(newViewModel)
    }
    
    // MARK: - Private Configuration
    private func configureWithViewModel(_ viewModel: GameViewModel) {
        viewModel.delegate = self
        
        // Setup field calculator
        let gridSize = viewModel.getGridSize()
        fieldCalculator = FieldCalculatorFactory.getCalculator(for: gridSize)
        
        // Create game session
        let puzzleType: GameProgressManager.PuzzleSaveState.PuzzleType = tutorialId != nil ? .tutorial : .random
        gameSession = GameSession(
            startTime: Date(),
            puzzleId: UUID().uuidString,
            puzzleType: puzzleType,
            difficulty: nil
        )
        
        // Update UI if view is loaded
        if isViewLoaded {
            recreateGridCells()
            updateUI()
            
            // Setup tutorial if needed
            if isLaunchedFromDashboard, let tutorialId = tutorialId {
                setupTutorial(tutorialId)
            }
        }
    }
    
    private func recreateGridCells() {
        guard let viewModel = viewModel,
              let gridView = gridView else { return }
        
        // Remove existing cells
        gridView.subviews.forEach { $0.removeFromSuperview() }
        cellViews.removeAll()
        
        // Create new cells
        cellViews = createCellViews(for: viewModel.getGridSize())
        updateCellViews()
    }
    
    // MARK: - Tutorial Setup
    private func setupTutorial(_ tutorialId: String) {
        tutorialCoordinator = TutorialCoordinator(gameViewController: self)
        tutorialCoordinator?.startTutorial(tutorialId)
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        updateMagnetButtons()
        updateCellViews()
        updateSolutionButton()
        updateMessageView()
        updateProgressDisplay()
    }
    
    private func updateMagnetButtons() {
        guard let viewModel = viewModel,
              let positiveButton = positiveButton,
              let negativeButton = negativeButton else { return }
        
        let availableMagnets = viewModel.getAvailableMagnets()
        let selectedType = viewModel.getSelectedMagnetType()
        
        positiveButton.configure(
            type: 1,
            count: availableMagnets.positive,
            isSelected: selectedType == 1
        )
        
        negativeButton.configure(
            type: -1,
            count: availableMagnets.negative,
            isSelected: selectedType == -1
        )
    }
    
    private func updateMagnetButtonsStyle() {
        guard let positiveButton = positiveButton,
              let negativeButton = negativeButton else { return }
        
        [positiveButton, negativeButton].forEach { button in
            button.backgroundColor = .black
            button.layer.borderWidth = 2
            button.layer.borderColor = TerminalTheme.Colors.borderGreen.cgColor
        }
    }
    
    // Update the updateCellViews method to respect animation tracking
    private func updateCellViews() {
        guard let viewModel = viewModel else { return }
        
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                let position = GridPosition(row: row, col: col)
                
                // Skip cells that are currently being animated - they'll update when animation completes
                guard !cellsBeingAnimated.contains(position) else { continue }
                
                if let cell = viewModel.getCellAt(row: row, col: col) {
                    updateCellView(cellViews[row][col], with: cell)
                }
            }
        }
    }
    
    private func updateSolutionButton() {
        guard let viewModel = viewModel,
              let solutionButton = solutionButton else { return }
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconName = viewModel.isShowingSolution() ? "eye.slash.fill" : "puzzlepiece.fill"
        let icon = UIImage(systemName: iconName, withConfiguration: configuration)
        solutionButton.setImage(icon, for: .normal)
        
        if viewModel.isShowingSolution() {
            solutionButton.backgroundColor = TerminalTheme.Colors.primaryGreen.withAlphaComponent(0.2)
            solutionButton.layer.borderColor = TerminalTheme.Colors.primaryGreen.cgColor
        } else {
            solutionButton.backgroundColor = .black
            solutionButton.layer.borderColor = TerminalTheme.Colors.borderGreen.cgColor
        }
    }
    
    private func updateMessageView() {
        guard let viewModel = viewModel else { return }
        
        // Only show the message view if puzzle is solved AND we're not showing the solution
        // BUT don't actually make it visible yet - let the animation controller handle that
        let shouldBeVisible = viewModel.isPuzzleSolved() && !viewModel.isShowingSolution()
        
        if shouldBeVisible {
            // Prepare the message view but keep it hidden
            // The animation controller will make it visible at the right time
            messageView?.setMessage("⚡ ENERGY HARMONIZED ⚡")
            // Don't set isHidden = false here, let showCompletionMessage() handle the timing
        } else {
            messageView?.isHidden = true
        }
    }
    
    // MARK: - Actions
    @objc private func returnToDashboard() {
        if viewModel?.isPuzzleSolved() == true {
            showCompletionDialog()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func cellTapped(_ gesture: UITapGestureRecognizer) {
        guard let cellView = gesture.view as? CellView,
              let viewModel = viewModel else { return }
        
        let row = cellView.tag / 100
        let col = cellView.tag % 100
        
        // Check tutorial restrictions
        if let coordinator = tutorialCoordinator {
            coordinator.handleGameStateChange()
        }
        
        // Store previous state for animation
        let previousToolEffect = viewModel.getCellAt(row: row, col: col)?.toolEffect ?? 0
        
        // Handle direct magnet removal
        if let cell = viewModel.getCellAt(row: row, col: col), cell.toolEffect != 0 {
            // Store the current field state before removal
            let preRemovalFieldStates = captureCurrentFieldStates()
            
            // Mark cells that will be affected by removal as being animated
            markAffectedCellsAsAnimating(sourceRow: row, sourceCol: col)
            
            // Update model immediately for removal (this is fine since we're removing)
            viewModel.removeMagnetDirectly(at: row, col: col)
            clearAllInfluencePreviews()
            
            // Animate removal with field update
            animationController?.animateMagnetRemoval(at: GridPosition(row: row, col: col),
                                                    cellView: cellView,
                                                    removedType: previousToolEffect) {
                // Update affected cells after removal animation
                self.updateFieldVisuals(previousStates: preRemovalFieldStates)
                // Clear animation tracking
                self.clearAnimationTracking()
            }
            return
        }
        
        // Handle selection and placement
        if let cell = viewModel.getCellAt(row: row, col: col), cell.isSelected {
            // Get the selected magnet type
            let selectedMagnetType = viewModel.getSelectedMagnetType()
            
            // VALIDATE the placement first without updating the model
            if !canPlaceMagnet(type: selectedMagnetType, at: row, col: col) {
                // Clear selection and return
                viewModel.selectCell(at: row, col: col) // This will deselect
                return
            }
            
            // Store current field states before placement
            let prePlacementFieldStates = captureCurrentFieldStates()
            
            // Mark the target cell as being animated to prevent premature updates
            cellsBeingAnimated.insert(GridPosition(row: row, col: col))
            
            // Clear influence previews
            clearAllInfluencePreviews()
            
            // Prepare the cell for animation but don't show the magnet yet
            cellView.prepareMagnetForAnimation(magnetType: selectedMagnetType)
            
            // Start the placement animation
            animationController?.animateMagnetPlacement(
                at: GridPosition(row: row, col: col),
                cellView: cellView,
                magnetType: selectedMagnetType,
                sourceButton: selectedMagnetType == 1 ? positiveButton : negativeButton
            ) {
                // ONLY NOW update the model after the magnet has visually landed
                self.viewModel?.placeOrRemoveMagnet(at: row, col: col)
                
                // Remove this cell from animation tracking since the magnet has landed
                self.cellsBeingAnimated.remove(GridPosition(row: row, col: col))
                
                // Now start the field influence animations
                self.showFieldInfluenceAnimationWithDelayedUpdates(
                    sourceRow: row, sourceCol: col,
                    magnetType: selectedMagnetType,
                    previousStates: prePlacementFieldStates
                )
                
                // Update session tracking
                self.gameSession?.moveCount += 1
                GameProgressManager.shared.recordMagnetPlaced()
            }
            
        } else {
            // Selection case - this is immediate and doesn't need animation delays
            viewModel.selectCell(at: row, col: col)
            showInfluencePreview(row: row, col: col)
        }
    }

    // Add this helper method to validate magnet placement without updating the model
    private func canPlaceMagnet(type: Int, at row: Int, col: Int) -> Bool {
        guard let viewModel = viewModel else { return false }
        return viewModel.canPlaceMagnet(type: type, at: row, col: col)
    }

    @objc private func magnetButtonTapped(_ sender: MagnetButton) {
        viewModel?.setSelectedMagnetType(sender.toolType)
        updateMagnetButtons()
        updateCellViews()
    }
    
    @objc private func resetButtonTapped() {
        // Animate all existing magnets being removed before reset
        animateResetSequence {
            self.viewModel?.resetPuzzle()
            self.gameSession?.undoCount += 1
            GameProgressManager.shared.recordMoveUndone()
            self.updateUI()
        }
    }
    
    @objc private func solutionButtonTapped() {
        viewModel?.toggleSolution()
        updateSolutionButton()
        updateUI()
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if let gridView = gridView, !gridView.frame.contains(location) {
            clearAllSelections()
            clearAllInfluencePreviews()
        }
    }
    
    @objc func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc func buttonTouchUpOutside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Animation Controller Access
    func getCellViews() -> [[CellView]] {
        return cellViews
    }

    // Also add this method to get a specific cell view (useful for animations)
    func getCellViewAt(row: Int, col: Int) -> CellView? {
        guard row >= 0 && row < cellViews.count && col >= 0 && col < cellViews[row].count else {
            return nil
        }
        return cellViews[row][col]
    }
    
    // MARK: - Animation Helper Methods
    
    /// Capture current field states before making changes
    private func captureCurrentFieldStates() -> [GridPosition: (currentValue: Int, isNeutralized: Bool, isOvershot: Bool)] {
        guard let viewModel = viewModel else { return [:] }
        
        var states: [GridPosition: (currentValue: Int, isNeutralized: Bool, isOvershot: Bool)] = [:]
        
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                if let cell = viewModel.getCellAt(row: row, col: col) {
                    let position = GridPosition(row: row, col: col)
                    states[position] = (
                        currentValue: cell.currentFieldValue,
                        isNeutralized: cell.isNeutralized,
                        isOvershot: cell.isOvershot
                    )
                }
            }
        }
        
        return states
    }
    
    /// Update field visuals with special effects for different conditions
    private func updateFieldVisuals(previousStates: [GridPosition: (currentValue: Int, isNeutralized: Bool, isOvershot: Bool)]) {
        guard let viewModel = viewModel else { return }
        
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                let position = GridPosition(row: row, col: col)
                let cellView = cellViews[row][col]
                
                guard let cell = viewModel.getCellAt(row: row, col: col),
                      let previousState = previousStates[position] else { continue }
                
                // Update the cell data first
                updateCellView(cellView, with: cell)
                
                // Check for special conditions and animate accordingly
                if cell.isNeutralized && !previousState.isNeutralized {
                    // Newly neutralized - green success effect
                    cellView.animateNeutralizationSuccess()
                } else if cell.isOvershot && !previousState.isOvershot {
                    // Newly overshot - orange warning effect
                    cellView.animateOvershootWarning()
                } else if cell.currentFieldValue != previousState.currentValue {
                    // Value changed - subtle number change effect
                    cellView.animateValueChange(from: previousState.currentValue, to: cell.currentFieldValue)
                }
            }
        }
    }
    
    // Replace the showFieldInfluenceAnimationWithDelayedUpdates method with this version
    private func showFieldInfluenceAnimationWithDelayedUpdates(sourceRow: Int, sourceCol: Int, magnetType: Int, previousStates: [GridPosition: (currentValue: Int, isNeutralized: Bool, isOvershot: Bool)]) {
        guard let viewModel = viewModel else { return }
        
        let influenceArea = viewModel.getInfluenceArea(for: sourceRow, col: sourceCol)
        let sourcePosition = GridPosition(row: sourceRow, col: sourceCol)
        
        // Group affected cells by their distance from the source
        var cellsByDistance: [Int: [(cellView: CellView, position: GridPosition, intensity: Int)]] = [:]
        
        for row in 0..<influenceArea.count {
            for col in 0..<influenceArea[row].count {
                if row == sourceRow && col == sourceCol { continue }
                
                if influenceArea[row][col] && row < cellViews.count && col < cellViews[row].count {
                    let position = GridPosition(row: row, col: col)
                    let distance = sourcePosition.distance(to: position)
                    
                    let intensity = viewModel.getInfluenceIntensity(
                        from: sourceRow,
                        sourceCol: sourceCol,
                        to: row,
                        targetCol: col
                    )
                    
                    let cellView = cellViews[row][col]
                    
                    if cellsByDistance[distance] == nil {
                        cellsByDistance[distance] = []
                    }
                    cellsByDistance[distance]?.append((cellView: cellView, position: position, intensity: intensity))
                    
                    // Mark this cell as being animated
                    cellsBeingAnimated.insert(position)
                }
            }
        }
        
        // Animate each distance ring with appropriate delays
        let baseDelay: TimeInterval = 0.15  // Increased to give magnet time to land
        let ringDelay: TimeInterval = 0.08 // Delay between distance rings
        
        for distance in cellsByDistance.keys.sorted() {
            guard let cellsAtDistance = cellsByDistance[distance] else { continue }
            
            let ringAnimationDelay = baseDelay + (TimeInterval(distance - 1) * ringDelay)
            
            // Animate all cells at this distance simultaneously (or with very small random offsets)
            for (index, cellData) in cellsAtDistance.enumerated() {
                let randomOffset = Double.random(in: 0...0.02) // Small random offset within the ring
                let finalDelay = ringAnimationDelay + randomOffset
                
                DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
                    // Show influence animation
                    cellData.cellView.animateFieldInfluence(intensity: cellData.intensity, magnetType: magnetType)
                    
                    // Update this cell's visual state after the animation hits
                    if let cell = viewModel.getCellAt(row: cellData.position.row, col: cellData.position.col),
                       let previousState = previousStates[cellData.position] {
                        
                        // Update the cell view
                        self.updateCellView(cellData.cellView, with: cell)
                        
                        // Apply special effect based on condition change
                        if cell.isNeutralized && !previousState.isNeutralized {
                            cellData.cellView.animateNeutralizationSuccess()
                        } else if cell.isOvershot && !previousState.isOvershot {
                            cellData.cellView.animateOvershootWarning()
                        } else if cell.currentFieldValue != previousState.currentValue {
                            cellData.cellView.animateValueChange(from: previousState.currentValue, to: cell.currentFieldValue)
                        }
                        
                        // Remove from animation tracking
                        self.cellsBeingAnimated.remove(cellData.position)
                    }
                }
            }
        }
        
        // Update the source cell immediately since the magnet has already landed there
        if let sourceCell = viewModel.getCellAt(row: sourceRow, col: sourceCol),
           let sourcePreviousState = previousStates[sourcePosition] {
            let sourceCellView = cellViews[sourceRow][sourceCol]
            updateCellView(sourceCellView, with: sourceCell)
            
            if sourceCell.isNeutralized && !sourcePreviousState.isNeutralized {
                sourceCellView.animateNeutralizationSuccess()
            } else if sourceCell.isOvershot && !sourcePreviousState.isOvershot {
                sourceCellView.animateOvershootWarning()
            } else if sourceCell.currentFieldValue != sourcePreviousState.currentValue {
                sourceCellView.animateValueChange(from: sourcePreviousState.currentValue, to: sourceCell.currentFieldValue)
            }
        }
    }
    
    private func showFieldInfluenceAnimation(sourceRow: Int, sourceCol: Int, magnetType: Int) {
        guard let viewModel = viewModel else { return }
        
        let influenceArea = viewModel.getInfluenceArea(for: sourceRow, col: sourceCol)
        let sourcePosition = GridPosition(row: sourceRow, col: sourceCol)
        
        // Group affected cells by their distance from the source
        var cellsByDistance: [Int: [(row: Int, col: Int, intensity: Int)]] = [:]
        
        for row in 0..<influenceArea.count {
            for col in 0..<influenceArea[row].count {
                if row == sourceRow && col == sourceCol { continue }
                
                if influenceArea[row][col] && row < cellViews.count && col < cellViews[row].count {
                    let position = GridPosition(row: row, col: col)
                    let distance = sourcePosition.distance(to: position)
                    
                    let intensity = viewModel.getInfluenceIntensity(
                        from: sourceRow,
                        sourceCol: sourceCol,
                        to: row,
                        targetCol: col
                    )
                    
                    if cellsByDistance[distance] == nil {
                        cellsByDistance[distance] = []
                    }
                    cellsByDistance[distance]?.append((row: row, col: col, intensity: intensity))
                }
            }
        }
        
        // Animate each distance ring with appropriate delays
        let baseDelay: TimeInterval = 0.1
        let ringDelay: TimeInterval = 0.08 // Delay between distance rings
        
        for distance in cellsByDistance.keys.sorted() {
            guard let cellsAtDistance = cellsByDistance[distance] else { continue }
            
            let ringAnimationDelay = baseDelay + (TimeInterval(distance - 1) * ringDelay)
            
            // Animate all cells at this distance simultaneously (with small random offsets)
            for cellData in cellsAtDistance {
                let randomOffset = Double.random(in: 0...0.02) // Small random offset within the ring
                let finalDelay = ringAnimationDelay + randomOffset
                
                DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
                    self.cellViews[cellData.row][cellData.col].animateFieldInfluence(intensity: cellData.intensity, magnetType: magnetType)
                }
            }
        }
    }
    
    private func animateResetSequence(completion: @escaping () -> Void) {
        guard let viewModel = viewModel else {
            completion()
            return
        }
        
        // Mark all cells with magnets as being animated
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                if let cell = viewModel.getCellAt(row: row, col: col), cell.toolEffect != 0 {
                    cellsBeingAnimated.insert(GridPosition(row: row, col: col))
                }
            }
        }
        
        var animationCount = 0
        var completedAnimations = 0
        
        // Count existing magnets
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                if let cell = viewModel.getCellAt(row: row, col: col), cell.toolEffect != 0 {
                    animationCount += 1
                }
            }
        }
        
        guard animationCount > 0 else {
            completion()
            return
        }
        
        // Animate removal of all magnets
        for row in 0..<cellViews.count {
            for col in 0..<cellViews[row].count {
                if let cell = viewModel.getCellAt(row: row, col: col), cell.toolEffect != 0 {
                    let cellView = cellViews[row][col]
                    
                    animationController?.animateMagnetRemoval(
                        at: GridPosition(row: row, col: col),
                        cellView: cellView,
                        removedType: cell.toolEffect
                    ) {
                        completedAnimations += 1
                        if completedAnimations >= animationCount {
                            // Clear all animation tracking before completion
                            self.clearAnimationTracking()
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func clearAllSelections() {
        viewModel?.clearAllSelections()
    }
    
    private func showInfluencePreview(row: Int, col: Int) {
        clearAllInfluencePreviews()
        
        guard let viewModel = viewModel else { return }
        
        let influenceArea = viewModel.getInfluenceArea(for: row, col: col)
        let magnetType = viewModel.getSelectedMagnetType()
        
        // Show central magnet influence
        if row < cellViews.count && col < cellViews[row].count {
            cellViews[row][col].showCentralMagnetInfluence(magnetType: magnetType)
        }
        
        // Show influence on other cells
        for r in 0..<influenceArea.count {
            for c in 0..<influenceArea[r].count {
                if r == row && c == col { continue }
                
                if influenceArea[r][c] {
                    let intensity = viewModel.getInfluenceIntensity(
                        from: row,
                        sourceCol: col,
                        to: r,
                        targetCol: c
                    )
                    
                    if r < cellViews.count && c < cellViews[r].count {
                        cellViews[r][c].showInfluence(intensity: intensity, magnetType: magnetType)
                    }
                }
            }
        }
    }
    
    private func clearAllInfluencePreviews() {
        for rowViews in cellViews {
            for cellView in rowViews {
                cellView.clearInfluence()
            }
        }
    }
    
    private func showCompletionDialog() {
        let alert = UIAlertController(
            title: "Assignment Complete",
            message: "You've successfully processed this assignment. Return to headquarters?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Return", style: .default) { [weak self] _ in
            self?.recordCompletion()
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func recordCompletion() {
        guard let session = gameSession else { return }
        
        GameProgressManager.shared.markLevelCompleted(
            session.puzzleId,
            solveTime: session.elapsedTime
        )
        
        if tutorialId != nil {
            GameProgressManager.shared.markTutorialCompleted(tutorialId!)
            MessageManager.shared.checkTriggeredMessages()
        }
    }
}

// MARK: - GameStateDelegate
extension GameViewController: GameStateDelegate {
    func gameStateDidChange() {
        updateUI()
        tutorialCoordinator?.handleGameStateChange()
    }
    
    func puzzleSolved() {
        // DON'T show message or start animations immediately
        // Instead, wait for any ongoing animations to complete
        
        // Check if there are any cells being animated
        if !cellsBeingAnimated.isEmpty {
            // Wait for animations to complete before starting celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startPuzzleCompletionSequence()
            }
        } else {
            // No animations running, start immediately
            startPuzzleCompletionSequence()
        }
    }
    
    // Add this new method to handle the completion sequence
    private func startPuzzleCompletionSequence() {
        // Update the message view state (but don't show banner yet)
        updateMessageView()
        
        // Start the completion animation, which will show the banner at the right time
        animationController?.animatePuzzleCompletion()
        
        // Handle progress tracking
        if let session = gameSession {
            GameProgressManager.shared.clearCurrentPuzzle()
            
            // Check if it was a perfect solution (minimal moves)
            let availableMagnets = viewModel?.getAvailableMagnets() ?? (positive: 0, negative: 0)
            if session.moveCount <= availableMagnets.positive + availableMagnets.negative {
                GameProgressManager.shared.recordPerfectSolution()
            }
        }
    }
}

// MARK: - TutorialAccessible
extension GameViewController: TutorialAccessible {
    func getStabilizerButton() -> UIView? {
        return positiveButton
    }
    
    func getSuppressorButton() -> UIView? {
        return negativeButton
    }
    
    func getGridView() -> UIView? {
        return gridView
    }
    
    func getCellView(at row: Int, col: Int) -> UIView? {
        if row < cellViews.count && col < cellViews[row].count {
            return cellViews[row][col]
        }
        return nil
    }
}
