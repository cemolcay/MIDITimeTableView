//
//  MIDITimeTableView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

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

/// Delegate functions to inform about editing cells and sizing of the time table.
public protocol MIDITimeTableViewDelegate: class {
  /// Informs about the cell is either moved to another position, changed duration or changed position in a current or a new row.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that performed changes on.
  ///   - row: Initial row index of the edited cell.
  ///   - index: Index of the cell in the initial row index.
  ///   - newCellRow: Last row index of cell after editing.
  ///   - newCellPosition: Last position of cell after editing.
  ///   - newCellDuration: Last duration of cell after editing.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEditCellAt row: Int, index: Int, newCellRow: Int, newCellPosition: Double, newCellDuration: Double)

  /// Informs about the cell is being deleted.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that performed changes on.
  ///   - row: Row index of the cell.
  ///   - index: Index of the cell in the row.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDeleteCellAt row: Int, index: Int)

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
  private var editingCellRow: Int?

  /// Data source object of the time table to populate its data.
  public weak var dataSource: MIDITimeTableViewDataSource?
  /// Delegate object of the time table to inform about changes and customise sizing.
  public weak var timeTableDelegate: MIDITimeTableViewDelegate?

  private var isMoving = false
  private var isResizing = false
  private var rowHeight: CGFloat = 60
  private var measureHeight: CGFloat = 30
  private var headerCellWidth: CGFloat = 120

  private var dragTimer: Timer?
  private let dragTimerInterval: TimeInterval = 0.5
  private var dragStartPosition: CGPoint = .zero
  private var dragView: UIView?
  private var initialDragViewSize: CGFloat = 30
  private var dragViewAutoScrollingThreshold: CGFloat = 20

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
  public func rowAndColumnIndex(of cell: MIDITimeTableCellView) -> (row: Int, column: Int)? {
    let row = Int((cell.frame.minY - measureHeight) / rowHeight)
    guard let column = cellViews[row].index(of: cell), row < cellViews.count else { return nil }
    return (row, column)
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

    // Make scroll view scroll if drag view hits the limit
    var visibleRect = CGRect(origin: contentOffset, size: bounds.size)
    if touchLocation.y < visibleRect.minY + dragViewAutoScrollingThreshold { // move up
      visibleRect.origin.y -= dragViewAutoScrollingThreshold
      scrollRectToVisible(visibleRect, completion: {
        self.updateDragView(touchLocation: CGPoint(x: touchLocation.x, y: touchLocation.y - self.dragViewAutoScrollingThreshold))
      })
    } else if touchLocation.y > visibleRect.maxY - dragViewAutoScrollingThreshold { // move down
      visibleRect.origin.y += dragViewAutoScrollingThreshold
      scrollRectToVisible(visibleRect, completion: {
        self.updateDragView(touchLocation: CGPoint(x: touchLocation.x, y: touchLocation.y + self.dragViewAutoScrollingThreshold))
      })
    }

    if touchLocation.x < visibleRect.minX + dragViewAutoScrollingThreshold { // move left
      visibleRect.origin.x -= dragViewAutoScrollingThreshold
      scrollRectToVisible(visibleRect, completion: {
        self.updateDragView(touchLocation: CGPoint(x: touchLocation.x - self.dragViewAutoScrollingThreshold, y: touchLocation.y))
      })
    } else if touchLocation.x > visibleRect.maxX - dragViewAutoScrollingThreshold { // move right
      visibleRect.origin.x += dragViewAutoScrollingThreshold
      scrollRectToVisible(visibleRect, completion: {
        self.updateDragView(touchLocation: CGPoint(x: touchLocation.x + self.dragViewAutoScrollingThreshold, y: touchLocation.y))
      })
    }
  }

  private func scrollRectToVisible(_ visibleRect: CGRect, completion: @escaping () -> Void) {
    UIView.animate(
      withDuration: 0.3,
      animations: {
        self.scrollRectToVisible(visibleRect, animated: false)
      },
      completion: { _ in
        completion()
    })
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

  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    endDragging()
  }

  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    endDragging()
  }

  private func endDragging() {
    // Enable scrolling back
    isScrollEnabled = true
    // Reset timer
    dragTimer?.invalidate()
    dragTimer = nil
    // Remove drag view
    dragView?.removeFromSuperview()
    dragView = nil
  }

  private func unselectAllCells() {
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

    if case .began = pan.state {
      editingCellRow = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
      midiTimeTableCellView.isSelected = true
    }

    isMoving = true

    // Horizontal move
    if translation.x > subbeatWidth, midiTimeTableCellView.frame.maxX < contentSize.width {
      midiTimeTableCellView.frame.origin.x += subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, midiTimeTableCellView.frame.minX > headerCellWidth {
      midiTimeTableCellView.frame.origin.x -= subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    // Vertical move
    if translation.y > rowHeight, midiTimeTableCellView.frame.maxY < measureHeight + (rowHeight * CGFloat(cellViews.count)) {
      midiTimeTableCellView.frame.origin.y += rowHeight
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    } else if translation.y < -rowHeight, midiTimeTableCellView.frame.minY > measureHeight {
      midiTimeTableCellView.frame.origin.y -= rowHeight
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    }

    if case .ended = pan.state {
      isMoving = false
      didEditCell(midiTimeTableCellView)
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    if case .began = pan.state {
      editingCellRow = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
      isResizing = true
      midiTimeTableCellView.isSelected = true
    }

    if translation.x > subbeatWidth, midiTimeTableCellView.frame.maxX < contentSize.width - subbeatWidth { // Increase
      midiTimeTableCellView.frame.size.width += subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, midiTimeTableCellView.frame.width > subbeatWidth { // Decrease
      midiTimeTableCellView.frame.size.width -= subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    if case .ended = pan.state {
      isResizing = false
      didEditCell(midiTimeTableCellView)
    }
  }

  public func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView) {
    let row = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
    guard let index = cellViews[row].index(of: midiTimeTableCellView) else { return }
    timeTableDelegate?.midiTimeTableView(self, didDeleteCellAt: row, index: index)
  }

  private func didEditCell(_ cellView: MIDITimeTableCellView) {
    guard let row = editingCellRow, let index = cellViews[row].index(of: cellView) else { return }
    let newCellPosition = Double(cellView.frame.minX - headerCellWidth) / Double(beatWidth)
    let newCellDuration = Double(cellView.frame.size.width / beatWidth)
    let newCellRow = Int((cellView.frame.minY - measureHeight) / rowHeight)

    timeTableDelegate?.midiTimeTableView(
      self,
      didEditCellAt: row,
      index: index,
      newCellRow: newCellRow,
      newCellPosition: newCellPosition,
      newCellDuration: newCellDuration)

    editingCellRow = nil
    cellView.isSelected = false
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
