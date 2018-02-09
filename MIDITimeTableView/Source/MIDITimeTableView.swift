//
//  MIDITimeTableView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Auto scrolling direction type
public struct MIDITimeTableViewAutoScrollDirection: OptionSet {

  // MARK: Option Set

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  // MARK: Init

  /// Default initilization with one or more direction types.
  ///
  /// - Parameter type: Direction types.
  public init(type: [MIDITimeTableViewAutoScrollDirection]) {
    var direction = MIDITimeTableViewAutoScrollDirection()
    type.forEach({ direction.insert($0) })
    self = direction
  }

  /// Left direction
  public static let left = MIDITimeTableViewAutoScrollDirection(rawValue: 1 << 0)
  /// Right direction
  public static let right = MIDITimeTableViewAutoScrollDirection(rawValue: 1 << 1)
  /// Up direction
  public static let up = MIDITimeTableViewAutoScrollDirection(rawValue: 1 << 2)
  /// Down direction
  public static let down = MIDITimeTableViewAutoScrollDirection(rawValue: 1 << 3)
}

/// Populates the `MIDITimeTableView` with the datas of rows and cells.
public protocol MIDITimeTableViewDataSource: class {
  /// Number of rows in the time table.
  ///
  /// - Parameter midiTimeTableView: Time table to populate rows.
  /// - Returns: Number of rows populate.
  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int

  /// Time signature of the time table.
  ///
  /// - Parameter midiTimeTableView: Time table to set time signature.
  /// - Returns: Time signature of the time table.
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature

  /// Row data for each row in the time table.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that populates row data.
  ///   - index: Index of row to populate data.
  /// - Returns: Row data of time table for an index.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowAt index: Int) -> MIDITimeTableRowData
}

/// Edited cell data. Holds the edited cell's index before editing, and new row index, position and duration data after editing.
public typealias MIDITimeTableViewEditedCellData = (index: MIDITimeTableCellIndex, newRowIndex: Int, newPosition: Double, newDuration: Double)

/// Delegate functions to inform about editing cells and sizing of the time table.
public protocol MIDITimeTableViewDelegate: class {
  /// Informs about the cell is either moved to another position, changed duration or changed position in a current or a new row.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that performed changes on.
  ///   - cells: Edited cells data with changes before and after.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit cells: [MIDITimeTableViewEditedCellData])

  /// Informs about the cell is being deleted.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that performed changes on.
  ///   - cells: Row and column indices of the cells will be deleting.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDelete cells: [MIDITimeTableCellIndex])

  /// Measure view height in the time table.
  ///
  /// - Parameter midiTimeTableView: Time table to set its measure view's height.
  /// - Returns: Height of measure view.
  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat

  /// Height of each row in the time table.
  ///
  /// - Parameter midiTimeTableView: Time table to set its rows height.
  /// - Returns: Height of each row.
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat

  /// Width of header cells in each row.
  ///
  /// - Parameter midiTimeTableView: Time table to set its header cells widths in each row.
  /// - Returns: Width of header cell in each row.
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat

  /// Informs about user updated playhead position.
  ///
  /// - Parameter midiTimeTableView: Time table that updated.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double)
}

/// Draws time table with multiple rows and editable cells. Heavily customisable.
open class MIDITimeTableView: UIScrollView, MIDITimeTableCellViewDelegate, MIDITimeTablePlayheadViewDelegate {
  /// Property to show measure bar. Defaults true.
  public var showsMeasure: Bool = true
  /// Property to show header cells in each row. Defaults true.
  public var showsHeaders: Bool = true
  /// Property to show grid. Defaults true.
  public var showsGrid: Bool = true
  /// Property to show playhead. Defaults true.
  public var showsPlayhead: Bool = true

  /// Speed of zooming by pinch gesture.
  public var zoomSpeed: CGFloat = 0.4
  /// Maximum width of a measure bar after zooming in. Defaults 500.
  public var maxMeasureWidth: CGFloat = 500
  /// Minimum width of a measure bar after zooming out. Defaults 100.
  public var minMeasureWidth: CGFloat = 100
  /// Initial width of a measure bar. Defaults 200.
  public var measureWidth: CGFloat = 200 {
    didSet {
      if measureWidth >= maxMeasureWidth {
        measureWidth = maxMeasureWidth
      } else if measureWidth <= minMeasureWidth {
        measureWidth = minMeasureWidth
      }
    }
  }

  /// Grid layer to set its customisable properties like drawing rules, colors or line widths.
  public private(set) var gridLayer = MIDITimeTableGridLayer()
  /// Measure view that draws measure bars on it. You can customise its style.
  public private(set) var measureView = MIDITimeTableMeasureView()
  /// Playhead view that shows the current position in timetable. You can set is hidden or movable status as well as its position.
  public private(set) var playheadView = MIDITimeTablePlayheadView()

  // Delegate and data source references
  private var rowData = [MIDITimeTableRowData]()
  public private(set) var rowHeaderCellViews = [MIDITimeTableHeaderCellView]()
  public private(set) var cellViews = [[MIDITimeTableCellView]]()

  /// Data source object of the time table to populate its data.
  public weak var dataSource: MIDITimeTableViewDataSource?
  /// Delegate object of the time table to inform about changes and customise sizing.
  public weak var timeTableDelegate: MIDITimeTableViewDelegate?

  private var isMoving = false
  private var isResizing = false
  private var rowHeight: CGFloat = 60
  private var measureHeight: CGFloat = 30
  private var headerCellWidth: CGFloat = 120
  private var editingCellIndices = [MIDITimeTableCellIndex]()

  private var dragTimer: Timer?
  private var dragTimerInterval: TimeInterval = 0.5
  private var dragStartPosition: CGPoint = .zero
  private var dragCurrentPosition: CGPoint?
  private var dragView: UIView?
  private var initialDragViewSize: CGFloat = 30
  private var dragViewAutoScrollingThreshold: CGFloat = 50
  private var autoScrollingTimer: Timer?
  private var autoScrollingTimerInterval: TimeInterval = 0.3

  private var beatWidth: CGFloat {
    return measureWidth / CGFloat(measureView.beatCount)
  }

  private var subbeatWidth: CGFloat {
    return beatWidth / 4
  }

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    addSubview(measureView)
    addSubview(playheadView)
    playheadView.delegate = self
    playheadView.layer.zPosition = 10
    layer.insertSublayer(gridLayer, at: 0)
    let pinch = UIPinchGestureRecognizer(
      target: self,
      action: #selector(didPinch(pinch:)))
    addGestureRecognizer(pinch)
    let tap = UITapGestureRecognizer(
      target: self,
      action: #selector(didTap(tap:)))
    addGestureRecognizer(tap)
  }

  // MARK: Lifecycle

  open override func layoutSubviews() {
    super.layoutSubviews()

    if isResizing || isMoving {
      return
    }

    for (index, row) in rowHeaderCellViews.enumerated() {
      row.frame = CGRect(
        x: 0,
        y: measureHeight + (CGFloat(index) * rowHeight),
        width: headerCellWidth,
        height: rowHeight)
    }

    var duration = 0.0
    for i in 0..<rowData.count {
      let row = rowData[i]
      duration = row.duration > duration ? row.duration : duration
      for (index, cell) in row.cells.enumerated() {
        let cellView = cellViews[i][index]
        let startX = beatWidth * CGFloat(cell.position)
        let width = beatWidth * CGFloat(cell.duration)
        cellView.frame = CGRect(
          x: headerCellWidth + startX,
          y: measureHeight + (CGFloat(i) * rowHeight),
          width: width,
          height: rowHeight)
      }
    }

    // Calculate optimum bar count for measureView.
    // Fit measure view in time table frame even if not enough data to show in time table.
    let minBarCount = Int(ceil(frame.size.width / measureWidth))
    var barCount = Int(ceil(duration / Double(measureView.beatCount))) + 1
    barCount = max(barCount, minBarCount)
    measureView.barCount = barCount

    measureView.frame = CGRect(
      x: headerCellWidth,
      y: 0,
      width: CGFloat(measureView.barCount) * measureWidth,
      height: measureHeight)

    contentSize = CGSize(
      width: headerCellWidth + measureView.frame.width,
      height: measureView.frame.height + (rowHeight * CGFloat(rowHeaderCellViews.count)))

    // Playhead
    playheadView.rowHeaderWidth = headerCellWidth
    playheadView.measureHeight = measureHeight
    playheadView.lineHeight = contentSize.height - measureHeight
    playheadView.measureBeatWidth = measureWidth / CGFloat(measureView.beatCount)
    playheadView.isHidden = !showsPlayhead

    // Grid layer
    gridLayer.rowCount = rowHeaderCellViews.count
    gridLayer.barCount = measureView.barCount
    gridLayer.rowHeight = rowHeight
    gridLayer.rowHeaderWidth = headerCellWidth
    gridLayer.measureWidth = measureWidth
    gridLayer.measureHeight = measureHeight
    gridLayer.beatCount = measureView.beatCount
    gridLayer.isHidden = !showsGrid
    gridLayer.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
  }

  /// Populates row and cell datas from its data source and redraws time table.
  public func reloadData() {
    // Data source
    rowHeaderCellViews.forEach({ $0.removeFromSuperview() })
    rowHeaderCellViews = []
    cellViews.flatMap({ $0 }).forEach({ $0.removeFromSuperview() })
    cellViews = []

    let numberOfRows = dataSource?.numberOfRows(in: self) ?? 0
    let timeSignature = dataSource?.timeSignature(of: self) ?? MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    measureView.beatCount = timeSignature.beats

    rowData.removeAll()
    for i in 0..<numberOfRows {
      guard let row = dataSource?.midiTimeTableView(self, rowAt: i) else { continue }
      rowData.insert(row, at: i)
      let rowHeaderCell = row.headerCellView
      rowHeaderCellViews.append(rowHeaderCell)
      addSubview(rowHeaderCell)

      var cells = [MIDITimeTableCellView]()
      for (index, cell) in row.cells.enumerated() {
        let cellView = row.cellView(cell)
        cellView.tag = index
        cellView.delegate = self
        cells.append(cellView)
        addSubview(cellView)
      }
      cellViews.append(cells)
    }

    // Delegate
    rowHeight = timeTableDelegate?.midiTimeTableViewHeightForRows(self) ?? rowHeight
    measureHeight = showsMeasure ? (timeTableDelegate?.midiTimeTableViewHeightForMeasureView(self) ?? measureHeight) : 0
    headerCellWidth = showsHeaders ? timeTableDelegate?.midiTimeTableViewWidthForRowHeaderCells(self) ?? headerCellWidth : 0

    gridLayer.setNeedsLayout()
  }

  /// Gets the row and column index of the cell view in the data source.
  ///
  /// - Parameter cell: The cell you want to get row and column info.
  /// - Returns: Returns a row and column index Int pair in a tuple.
  public func cellIndex(of cell: MIDITimeTableCellView) -> MIDITimeTableCellIndex? {
    let row = Int((cell.frame.minY - measureHeight) / rowHeight)
    guard let index = cellViews[row].index(of: cell), row < cellViews.count else { return nil }
    return MIDITimeTableCellIndex(row: row, index: index)
  }

  /// Unselects all cells if tapped an empty area of the time table.
  @objc private func didTap(tap: UITapGestureRecognizer) {
    unselectAllCells()
  }

  // MARK: Drag to select multiple cells

  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)

    // Start drag timer.
    guard let touchLocation = touches.first?.location(in: self) else { return }
    dragStartPosition = touchLocation
    dragTimer = Timer.scheduledTimer(
      timeInterval: dragTimerInterval,
      target: self,
      selector: #selector(createDragView),
      userInfo: nil,
      repeats: false)
  }

  @objc private func createDragView() {
    isScrollEnabled = false

    // Drag start position.
    dragStartPosition.x -= initialDragViewSize/2
    dragStartPosition.y -= initialDragViewSize/2

    // Create drag view.
    dragView = UIView(frame: CGRect(origin: dragStartPosition, size: .zero))
    dragView?.layer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor
    dragView?.layer.borderColor = UIColor.white.cgColor
    dragView?.layer.borderWidth = 1
    addSubview(dragView!)
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 1,
      options: [],
      animations: {
        self.dragView?.frame = CGRect(
          x: self.dragStartPosition.x,
          y: self.dragStartPosition.y,
          width: self.initialDragViewSize,
          height: self.initialDragViewSize)
      },
      completion: nil)

    // Reset drag timer.
    dragTimer?.invalidate()
    dragTimer = nil
  }

  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard let touchLocation = touches.first?.location(in: self) else { return }
    updateDragView(touchLocation: touchLocation)
    endAutoScrolling()

    // Make scroll view scroll if drag view hits the limit
    var autoScrollDirection = MIDITimeTableViewAutoScrollDirection()
    var visibleRect = CGRect(origin: contentOffset, size: bounds.size)
    if touchLocation.y < visibleRect.minY + dragViewAutoScrollingThreshold { // move up
      visibleRect.origin.y -= dragViewAutoScrollingThreshold
      autoScrollDirection.insert(.up)
    } else if touchLocation.y > visibleRect.maxY - dragViewAutoScrollingThreshold { // move down
      autoScrollDirection.insert(.down)
    }
    if touchLocation.x < visibleRect.minX + dragViewAutoScrollingThreshold { // move left
      autoScrollDirection.insert(.left)
    } else if touchLocation.x > visibleRect.maxX - dragViewAutoScrollingThreshold { // move right
      autoScrollDirection.insert(.right)
    }

    if autoScrollDirection.isEmpty {
      endAutoScrolling()
    } else {
      dragCurrentPosition = touchLocation
      startAutoScrollTimer(with: autoScrollDirection)
    }
  }

  private func updateDragView(touchLocation: CGPoint) {
    guard let dragView = dragView else { return }

    // Set drag view frame
    let origin = dragStartPosition
    if touchLocation.y < origin.y && touchLocation.x < origin.x {
      dragView.frame = CGRect(
        x: touchLocation.x,
        y: touchLocation.y,
        width: origin.x - touchLocation.x,
        height: origin.y - touchLocation.y)
    } else if touchLocation.y < origin.y && touchLocation.x > origin.x {
      dragView.frame = CGRect(
        x: origin.x,
        y: touchLocation.y,
        width: touchLocation.x - origin.x,
        height: origin.y - touchLocation.y)
    } else if touchLocation.y > origin.y && touchLocation.x > origin.x {
      dragView.frame = CGRect(
        x: origin.x,
        y: origin.y,
        width: touchLocation.x - origin.x,
        height: touchLocation.y - origin.y)
    } else if touchLocation.y > origin.y && touchLocation.x < origin.x {
      dragView.frame = CGRect(
        x: touchLocation.x,
        y: origin.y,
        width: origin.x - touchLocation.x,
        height: touchLocation.y - origin.y)
    }

    // Make cells selected.
    cellViews
      .flatMap({ $0 })
      .forEach({ $0.isSelected = dragView.frame.intersects($0.frame) })
  }

  private func startAutoScrollTimer(with direction: MIDITimeTableViewAutoScrollDirection) {
    autoScrollingTimer = Timer.scheduledTimer(
      timeInterval: autoScrollingTimerInterval,
      target: self,
      selector: #selector(autoScrollTimerTick(timer:)),
      userInfo: ["direction": direction],
      repeats: true)
  }

  @objc private func autoScrollTimerTick(timer: Timer) {
    guard let userInfo = timer.userInfo as? [String: Any],
      let dragCurrentPosition = dragCurrentPosition,
      let direction = userInfo["direction"] as? MIDITimeTableViewAutoScrollDirection
      else { return }

    var scrollDirection = CGPoint.zero
    if direction.contains(.left) {
      scrollDirection.x -= 1
    }
    if direction.contains(.right) {
      scrollDirection.x += 1
    }
    if direction.contains(.up) {
      scrollDirection.y -= 1
    }
    if direction.contains(.down) {
      scrollDirection.y += 1
    }

    // Calculate and auto scroll

    let scrollAmount = CGSize(
      width: scrollDirection.x * dragViewAutoScrollingThreshold,
      height: scrollDirection.y * dragViewAutoScrollingThreshold)

    let visibleRect = CGRect(
      origin: CGPoint(
        x: contentOffset.x + scrollAmount.width,
        y: contentOffset.y + scrollAmount.height),
      size: bounds.size)

    let position = CGPoint(
      x: dragCurrentPosition.x + scrollAmount.width,
      y: dragCurrentPosition.y + scrollAmount.height)

    UIView.animate(
      withDuration: autoScrollingTimerInterval,
      animations: {
        self.scrollRectToVisible(visibleRect, animated: false)
        self.updateDragView(touchLocation: position)
      },
      completion: { _ in self.updateDragView(touchLocation: position)})
  }

  private func endAutoScrolling() {
    autoScrollingTimer?.invalidate()
    autoScrollingTimer = nil
    dragCurrentPosition = nil
  }

  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    endDragging()
  }

  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    endDragging()
  }

  private func endDragging() {
    // Disable auto scrolling
    endAutoScrolling()
    // Enable scrolling back
    isScrollEnabled = true
    // Reset timer
    dragTimer?.invalidate()
    dragTimer = nil
    // Remove drag view
    dragView?.removeFromSuperview()
    dragView = nil
  }

  /// Makes all cells unselected.
  public func unselectAllCells() {
    cellViews.flatMap({ $0 }).forEach({ $0.isSelected = false })
  }

  // MARK: Zooming

  @objc func didPinch(pinch: UIPinchGestureRecognizer) {
    switch pinch.state {
    case .began, .changed:
      var deltaScale = pinch.scale
      deltaScale = ((deltaScale - 1) * zoomSpeed) + 1
      deltaScale = min(deltaScale, maxMeasureWidth/measureWidth)
      deltaScale = max(deltaScale, minMeasureWidth/measureWidth)
      measureWidth *= deltaScale
      setNeedsLayout()
      pinch.scale = 1
    default:
      return
    }
  }

  // MARK: MIDITimeTableCellViewDelegate

  public func midiTimeTableCellViewDidMove(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    let selectedCells = cellViews.flatMap({ $0 }).filter({ $0.isSelected })

    if case .began = pan.state {
      midiTimeTableCellView.isSelected = true
      editingCellIndices = cellViews.flatMap({ $0 }).filter({ $0.isSelected }).flatMap({ cellIndex(of: $0) })
    }

    isMoving = true

    for cell in selectedCells {
      // Horizontal move
      if translation.x > subbeatWidth, cell.frame.maxX < contentSize.width {
        cell.frame.origin.x += subbeatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      } else if translation.x < -subbeatWidth, cell.frame.minX > headerCellWidth {
        cell.frame.origin.x -= subbeatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      }

      // Vertical move
      if translation.y > rowHeight, cell.frame.maxY < measureHeight + (rowHeight * CGFloat(cellViews.count)) {
        cell.frame.origin.y += rowHeight
        pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
      } else if translation.y < -rowHeight, cell.frame.minY > measureHeight {
        cell.frame.origin.y -= rowHeight
        pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
      }
    }

    if case .ended = pan.state {
      isMoving = false
      didEditCells(editingCellIndices)
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    let selectedCells = cellViews.flatMap({ $0 }).filter({ $0.isSelected })

    if case .began = pan.state {
      isResizing = true
      midiTimeTableCellView.isSelected = true
      editingCellIndices = cellViews.flatMap({ $0 }).filter({ $0.isSelected }).flatMap({ cellIndex(of: $0) })
    }

    for cell in selectedCells {
      if translation.x > subbeatWidth, cell.frame.maxX < contentSize.width - subbeatWidth { // Increase
        cell.frame.size.width += subbeatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      } else if translation.x < -subbeatWidth, cell.frame.width > subbeatWidth { // Decrease
        cell.frame.size.width -= subbeatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      }
    }

    if case .ended = pan.state {
      isResizing = false
      didEditCells(editingCellIndices)
    }
  }

  private func didEditCells(_ cells: [MIDITimeTableCellIndex]) {
    var editedCells = [MIDITimeTableViewEditedCellData]()

    for cell in cells {
      let cellView = cellViews[cell.row][cell.index]
      let newCellPosition = Double(cellView.frame.minX - headerCellWidth) / Double(beatWidth)
      let newCellDuration = Double(cellView.frame.size.width / beatWidth)
      let newCellRow = Int((cellView.frame.minY - measureHeight) / rowHeight)

      editedCells.append((
        cell,
        newCellRow,
        newCellPosition,
        newCellDuration))
    }

    editingCellIndices = []
    timeTableDelegate?.midiTimeTableView(self, didEdit: editedCells)
  }

  public func midiTimeTableCellViewDidTap(_ midiTimeTableCellView: MIDITimeTableCellView) {
    for cell in cellViews.flatMap({ $0 }) {
      cell.isSelected = cell == midiTimeTableCellView
    }
  }

  public func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView) {
    let deletingCellIndices = cellViews
      .flatMap({ $0 })
      .filter({ $0.isSelected })
      .flatMap({ cellIndex(of: $0) })
    timeTableDelegate?.midiTimeTableView(self, didDelete: deletingCellIndices)
  }

  // MARK: MIDITimeTablePlayheadViewDelegate

  public func playheadView(_ playheadView: MIDITimeTablePlayheadView, didPan panGestureRecognizer: UIPanGestureRecognizer) {
    let translation = panGestureRecognizer.translation(in: self)

    // Horizontal move
    if translation.x > subbeatWidth, playheadView.frame.maxX < contentSize.width {
      playheadView.position += 0.25
      timeTableDelegate?.midiTimeTableView(self, didUpdatePlayhead: playheadView.position)
      panGestureRecognizer.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, playheadView.frame.minX > headerCellWidth {
      playheadView.position -= 0.25
      timeTableDelegate?.midiTimeTableView(self, didUpdatePlayhead: playheadView.position)
      panGestureRecognizer.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }
  }
}
