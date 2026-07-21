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
public protocol MIDITimeTableViewDataSource: AnyObject {
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

/// Edited cell data. Holds the edited cell's stable id and its index before editing, and new row
/// index, position and duration data after editing.
///
/// Prefer `id` to locate the cell in your own data going forward — it stays valid regardless of
/// how many other cells were added, removed or reordered since. `index` is a snapshot of the
/// cell's (row, array-position) at the moment the edit was reported and can go stale the instant
/// another edit in the same batch shifts it.
public typealias MIDITimeTableViewEditedCellData = (id: MIDITimeTableCellID, index: MIDITimeTableCellIndex, newRowIndex: Int, newPosition: Double, newDuration: Double)

/// Delegate functions to inform about editing cells and sizing of the time table.
public protocol MIDITimeTableViewDelegate: AnyObject {
  /// Informs about the cell edit's resolved overlaps: cells trimmed, removed or split because
  /// the moved/resized cell now covers them. Call `rowData.apply(result)` in your implementation
  /// to keep your data in sync in a single step. Has a default no-op implementation below, so
  /// existing conformers don't need to adopt it.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table that performed changes on.
  ///   - result: Resolved edit result with updated, removed and newly split cells.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit result: MIDITimeTableCellEditResult)

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

  /// Number of grid subdivisions per beat, used for snapping cell moves/resizes and
  /// playhead/range head drags, and for drawing the finest ("subbeat") grid lines. For example,
  /// 4 snaps to sixteenth notes within a quarter-note beat.
  ///
  /// Has a default implementation returning 4, so existing conformers don't need to adopt it. If
  /// you want snapping to follow your time signature's note value, return
  /// `timeSignature(of:).noteValue.rawValue` (or any other subdivision count you prefer — the two
  /// are independent: note value describes the meter, this describes the editing grid).
  ///
  /// - Parameter midiTimeTableView: Time table to set its snap resolution.
  /// - Returns: Number of subdivisions per beat. Values below 1 are treated as 1.
  func midiTimeTableViewSnapResolution(_ midiTimeTableView: MIDITimeTableView) -> Int

  /// Informs about user updated playhead position.
  ///
  /// - Parameter midiTimeTableView: Time table that updated.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double)

  /// Informs about user updated range head position.
  ///
  /// - Parameter midiTimeTableView: Time table that updated.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double)

  /// Informs about history has been changed. You need to update your `rowData` with history's `currentItem`.
  ///
  /// - Parameters:
  ///   - midiTimeTableView: Time table taht updated.
  ///   - history: History object of the time table.
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, historyDidChange history: MIDITimeTableHistory)
}

extension MIDITimeTableViewDelegate {
  /// Default no-op implementation, so existing conformers of `MIDITimeTableViewDelegate` don't
  /// break when this method was added. Adopt it to receive resolved overlap information.
  public func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit result: MIDITimeTableCellEditResult) {}

  /// Default implementation returning 4 (sixteenth notes in a quarter-note beat), matching the
  /// time table's long-standing built-in behavior. Override to customise snapping.
  public func midiTimeTableViewSnapResolution(_ midiTimeTableView: MIDITimeTableView) -> Int { 4 }
}

/// Draws time table with multiple rows and editable cells. Heavily customisable.
open class MIDITimeTableView: UIScrollView, MIDITimeTableCellViewDelegate, MIDITimeTablePlayheadViewDelegate, MIDITimeTableHistoryDelegate {
  /// Property to show measure bar. Defaults true.
  public var showsMeasure: Bool = true
  /// Property to show header cells in each row. Defaults true.
  public var showsHeaders: Bool = true
  /// Property to show grid. Defaults true.
  public var showsGrid: Bool = true
  /// Property to show playhead. Defaults true.
  public var showsPlayhead: Bool = true
  /// Property to show range head that sets the playable are on the timetable. Defaults true.
  public var showsRangeHead: Bool = true
  /// When true, the range head automatically moves forward to stay at or after the end of the
  /// furthest cell, so it never gets left behind as cells are added or extended. It never moves
  /// backwards on its own; dragging it manually still works as before. Defaults true.
  public var autoExtendsRangeHead: Bool = true
  /// Property to enable/disable history feature. Deafults true.
  public var holdsHistory: Bool = true

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
  /// Rangehead view that shows or adjusts the playable area on the timetable.
  public private(set) var rangeheadView = MIDITimeTablePlayheadView()

  // Delegate and data source references
  /// Current data to display of the time table.
  private var rowData = [MIDITimeTableRowData]()
  /// History data that holds each `rowData` on each `reloadData` cycle.
  public private(set) var history = MIDITimeTableHistory()
  /// All row header cell views currently displaying.
  public private(set) var rowHeaderCellViews = [MIDITimeTableHeaderCellView]()
  /// All data cell views currently displaying.
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
  /// Number of grid subdivisions per beat. See `MIDITimeTableViewDelegate.midiTimeTableViewSnapResolution(_:)`.
  private var snapResolution: Int = 4
  private var editingCellIndices = [MIDITimeTableCellIndex]()

  private var dragSelectMinimumPressDuration: TimeInterval = 0.5
  private var dragStartPosition: CGPoint = .zero
  private var dragCurrentPosition: CGPoint?
  private var dragView: UIView?
  private var initialDragViewSize: CGFloat = 90
  private var dragViewAutoScrollingThreshold: CGFloat = 100
  private var autoScrollingTimer: Timer?
  private var autoScrollingTimerInterval: TimeInterval = 0.3

  private var beatWidth: CGFloat {
    return measureWidth / CGFloat(measureView.beatCount)
  }

  private var subbeatWidth: CGFloat {
    return beatWidth / CGFloat(snapResolution)
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
    // Measure
    addSubview(measureView)
    // History
    history.delegate = self
    // Playhead
    addSubview(playheadView)
    playheadView.delegate = self
    playheadView.layer.zPosition = 10
    playheadView.shapeType = .playhead
    // Rangehead
    addSubview(rangeheadView)
    rangeheadView.delegate = self
    rangeheadView.layer.zPosition = 10
    rangeheadView.shapeType = .range
    // Grid
    layer.insertSublayer(gridLayer, at: 0)
    // Zoom gesture
    let pinch = UIPinchGestureRecognizer(
      target: self,
      action: #selector(didPinch(pinch:)))
    addGestureRecognizer(pinch)
    // Tap gesture
    let tap = UITapGestureRecognizer(
      target: self,
      action: #selector(didTap(tap:)))
    addGestureRecognizer(tap)
    // Drag to select gesture. A long press (rather than a quick swipe, which should scroll)
    // starts the marquee selection rectangle.
    let dragSelect = UILongPressGestureRecognizer(
      target: self,
      action: #selector(didLongPressForDragSelect(longPress:)))
    dragSelect.minimumPressDuration = dragSelectMinimumPressDuration
    addGestureRecognizer(dragSelect)
  }

  deinit {
    autoScrollingTimer?.invalidate()
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

    // Auto-extend the range head so it never sits behind the furthest cell. Only ever pushes it
    // forward; a manual drag can still bring it further out than the content requires.
    if showsRangeHead, autoExtendsRangeHead, duration > rangeheadView.position {
      rangeheadView.position = duration
    }

    // Calculate optimum bar count for measureView.
    // Fit measure view in time table frame even if not enough data to show in time table.
    let minBarCount = Int(ceil(frame.size.width / measureWidth))
    var barCount = Int(ceil(duration / Double(measureView.beatCount))) + 1
    barCount = max(barCount, minBarCount)
    // Check if range is set.
    if showsRangeHead {
      let rangePosition = rangeheadView.position
      let rangedBarCount = Int(ceil(rangePosition / Double(measureView.beatCount))) + 1
      barCount = max(barCount, rangedBarCount)
    }
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

    // Rangehead
    rangeheadView.rowHeaderWidth = headerCellWidth
    rangeheadView.measureHeight = measureHeight
    rangeheadView.lineHeight = contentSize.height - measureHeight
    rangeheadView.measureBeatWidth = measureWidth / CGFloat(measureView.beatCount)
    rangeheadView.isHidden = !showsRangeHead
    bringSubviewToFront(rangeheadView)

    // Grid layer
    gridLayer.rowCount = rowHeaderCellViews.count
    gridLayer.barCount = measureView.barCount
    gridLayer.rowHeight = rowHeight
    gridLayer.rowHeaderWidth = headerCellWidth
    gridLayer.measureWidth = measureWidth
    gridLayer.measureHeight = measureHeight
    gridLayer.beatCount = measureView.beatCount
    gridLayer.snapResolution = snapResolution
    gridLayer.isHidden = !showsGrid
    gridLayer.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)

    // Measure view's per-bar snap ticks.
    measureView.snapResolution = snapResolution
  }


  /// Populates row and cell datas from its data source and redraws time table. Could be invoked with an history item.
  ///
  /// - Parameter keepHistory: If you specify the history writing even if it is enabled, you can control it from here either.
  /// - Parameter historyItem: Optional history item. Defaults nil.
  public func reloadData(keepHistory: Bool = true, historyItem: MIDITimeTableHistoryItem? = nil) {
    // Reset data source
    rowHeaderCellViews.forEach({ $0.removeFromSuperview() })
    rowHeaderCellViews = []
    cellViews.flatMap({ $0 }).forEach({ $0.removeFromSuperview() })
    cellViews = []

    let numberOfRows = historyItem?.count ?? dataSource?.numberOfRows(in: self) ?? 0
    let timeSignature = dataSource?.timeSignature(of: self) ?? MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    measureView.beatCount = timeSignature.beats

    // Update rowData
    rowData.removeAll()
    for i in 0..<numberOfRows {
      guard let row = historyItem?[i] ?? dataSource?.midiTimeTableView(self, rowAt: i) else { continue }
      rowData.insert(row, at: i)
      let rowHeaderCell = row.headerCellView
      rowHeaderCellViews.append(rowHeaderCell)
      addSubview(rowHeaderCell)

      var cells = [MIDITimeTableCellView]()
      for (index, cell) in row.cells.enumerated() {
        let cellView = row.cellView(cell)
        cellView.tag = index
        cellView.cellID = cell.id
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
    snapResolution = max(1, timeTableDelegate?.midiTimeTableViewSnapResolution(self) ?? snapResolution)

    // Update grid
    gridLayer.setNeedsLayout()

    // Keep history
    if holdsHistory, keepHistory, historyItem == nil {
      history.append(item: rowData)
    }
  }

  /// Applies an edit result to the time table's own row data and cell views incrementally:
  /// only cells actually touched by `result` (updated, removed, or newly inserted) get their
  /// view moved, removed, or created. Every other cell keeps its existing view instance and
  /// stays in the hierarchy exactly as it was, instead of the whole table being torn down and
  /// rebuilt the way `reloadData()` would.
  ///
  /// `didEditCells` already calls this for you after every move/resize, so the time table stays
  /// visually correct on its own. It's exposed publicly in case you want to fold in an edit
  /// result you produced yourself (e.g. replaying one from persistence).
  ///
  /// - Parameter result: The edit result to apply.
  public func applyEditResult(_ result: MIDITimeTableCellEditResult) {
    // Look up every currently-displayed cell view by its stable id before mutating anything, so
    // cells untouched by this edit — the common case, usually all but one — get their exact same
    // view instance reused rather than torn down and recreated.
    var existingViewsByID = [MIDITimeTableCellID: MIDITimeTableCellView]()
    for views in cellViews {
      for view in views {
        if let id = view.cellID { existingViewsByID[id] = view }
      }
    }

    rowData.apply(result)

    var newCellViews = [[MIDITimeTableCellView]]()
    newCellViews.reserveCapacity(rowData.count)
    for row in rowData.indices {
      var rowViews = [MIDITimeTableCellView]()
      rowViews.reserveCapacity(rowData[row].cells.count)
      for (index, cell) in rowData[row].cells.enumerated() {
        let cellView: MIDITimeTableCellView
        if let existing = existingViewsByID.removeValue(forKey: cell.id) {
          cellView = existing
        } else {
          // No prior view shares this id: a brand new cell (e.g. a split-off remainder).
          cellView = rowData[row].cellView(cell)
          cellView.cellID = cell.id
          cellView.delegate = self
          addSubview(cellView)
        }
        cellView.tag = index
        rowViews.append(cellView)
      }
      newCellViews.append(rowViews)
    }

    // Anything left unclaimed no longer has a corresponding cell — removed, or fully covered by
    // the edit — so its view is no longer needed.
    existingViewsByID.values.forEach({ $0.removeFromSuperview() })

    cellViews = newCellViews
    setNeedsLayout()

    if holdsHistory {
      history.append(item: rowData)
    }
  }

  /// Removes the given cells from the time table's own row data and cell views incrementally,
  /// without rebuilding any cell unaffected by the deletion. Call this from
  /// `midiTimeTableView(_:didDelete:)` in place of `reloadData()`.
  ///
  /// - Parameter indices: Row/index pairs of the cells to remove, as reported by `didDelete`.
  public func removeCells(at indices: [MIDITimeTableCellIndex]) {
    let ids = indices.compactMap { index -> MIDITimeTableCellID? in
      guard index.row >= 0, index.row < rowData.count,
        index.index >= 0, index.index < rowData[index.row].cells.count
        else { return nil }
      return rowData[index.row].cells[index.index].id
    }
    applyEditResult(MIDITimeTableCellEditResult(removals: ids))
  }

  /// Gets the row and column index of the cell view in the data source.
  ///
  /// - Parameter cell: The cell you want to get row and column info.
  /// - Returns: Returns a row and column index Int pair in a tuple.
  public func cellIndex(of cell: MIDITimeTableCellView) -> MIDITimeTableCellIndex? {
    let row = Int(((cell.frame.minY - measureHeight) / rowHeight).rounded())
    guard row >= 0, row < cellViews.count, let index = cellViews[row].firstIndex(of: cell) else { return nil }
    return MIDITimeTableCellIndex(row: row, index: index)
  }

  /// Unselects all cells if tapped an empty area of the time table.
  @objc private func didTap(tap: UITapGestureRecognizer) {
    unselectAllCells()
    endDragging()
  }

  // MARK: Drag to select multiple cells

  @objc private func didLongPressForDragSelect(longPress: UILongPressGestureRecognizer) {
    switch longPress.state {
    case .began:
      dragStartPosition = longPress.location(in: self)
      createDragView()
    case .changed:
      let touchLocation = longPress.location(in: self)
      updateDragView(touchLocation: touchLocation)
      endAutoScrolling()

      // Make scroll view scroll if drag view hits the limit
      var autoScrollDirection = MIDITimeTableViewAutoScrollDirection()
      let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
      if touchLocation.y < visibleRect.minY + dragViewAutoScrollingThreshold, contentOffset.y > 0 { // move up
        autoScrollDirection.insert(.up)
      } else if touchLocation.y > visibleRect.maxY - dragViewAutoScrollingThreshold, contentOffset.y + frame.size.height < contentSize.height { // move down
        autoScrollDirection.insert(.down)
      }
      if touchLocation.x < visibleRect.minX + dragViewAutoScrollingThreshold, contentOffset.x > 0 { // move left
        autoScrollDirection.insert(.left)
      } else if touchLocation.x > visibleRect.maxX - dragViewAutoScrollingThreshold, contentOffset.x + frame.size.width < contentSize.width { // move right
        autoScrollDirection.insert(.right)
      }

      if autoScrollDirection.isEmpty {
        endAutoScrolling()
      } else {
        dragCurrentPosition = touchLocation
        startAutoScrollTimer(with: autoScrollDirection)
      }
    case .ended, .cancelled, .failed:
      endDragging()
    default:
      break
    }
  }

  private func createDragView() {
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
    // Block-based, with the direction captured directly — no `userInfo` dictionary/`Any`
    // round-trip to unpack on every tick.
    autoScrollingTimer = Timer.scheduledTimer(withTimeInterval: autoScrollingTimerInterval, repeats: true) { [weak self] _ in
      self?.autoScrollTimerTick(direction: direction)
    }
  }

  private func autoScrollTimerTick(direction: MIDITimeTableViewAutoScrollDirection) {
    guard let dragCurrentPosition = dragCurrentPosition else { return }

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

  private func endDragging() {
    // Disable auto scrolling
    endAutoScrolling()
    // Enable scrolling back
    isScrollEnabled = true
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
    bringSubviewToFront(midiTimeTableCellView)

    if case .began = pan.state {
      midiTimeTableCellView.isSelected = true
      editingCellIndices = cellViews
        .flatMap({ $0 })
        .filter({ $0.isSelected })
        .compactMap({ cellIndex(of: $0) })
    }

    isMoving = true

    let selectedCells = cellViews.flatMap({ $0 }).filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return }

    // Bounding box of the whole selection so the group moves as one unit
    // and no member overshoots the table's edges.
    let groupMinX = selectedCells.map({ $0.frame.minX }).min() ?? headerCellWidth
    let groupMaxX = selectedCells.map({ $0.frame.maxX }).max() ?? headerCellWidth
    let groupMinY = selectedCells.map({ $0.frame.minY }).min() ?? measureHeight
    let groupMaxY = selectedCells.map({ $0.frame.maxY }).max() ?? measureHeight
    let rowsBottom = measureHeight + (rowHeight * CGFloat(cellViews.count))

    // Fully catch up with the pan translation instead of moving a single
    // quantized step per callback, so the selection never trails the finger.
    let xSteps = MIDITimeTableDragStepMath.steps(
      translation: translation.x,
      stepSize: subbeatWidth,
      maxForwardSteps: Int(((contentSize.width - groupMaxX) / subbeatWidth).rounded(.down)),
      maxBackwardSteps: Int(((groupMinX - headerCellWidth) / subbeatWidth).rounded(.down)))

    let ySteps = MIDITimeTableDragStepMath.steps(
      translation: translation.y,
      stepSize: rowHeight,
      maxForwardSteps: Int(((rowsBottom - groupMaxY) / rowHeight).rounded(.down)),
      maxBackwardSteps: Int(((groupMinY - measureHeight) / rowHeight).rounded(.down)))

    if xSteps != 0 || ySteps != 0 {
      let dx = CGFloat(xSteps) * subbeatWidth
      let dy = CGFloat(ySteps) * rowHeight
      for cell in selectedCells {
        cell.frame.origin.x += dx
        cell.frame.origin.y += dy
      }
      // Keep only the leftover (sub-step) translation so it accumulates
      // toward the next step instead of being discarded.
      pan.setTranslation(CGPoint(x: translation.x - dx, y: translation.y - dy), in: self)
    }

    if case .ended = pan.state {
      isMoving = false
      didEditCells(editingCellIndices)
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(midiTimeTableCellView)

    if case .began = pan.state {
      isResizing = true
      midiTimeTableCellView.isSelected = true
      editingCellIndices = cellViews
        .flatMap({ $0 })
        .filter({ $0.isSelected })
        .compactMap({ cellIndex(of: $0) })
    }

    let selectedCells = cellViews.flatMap({ $0 }).filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return }

    // Fully catch up with the pan translation instead of resizing a single
    // quantized step per callback, so resizing never trails the finger.
    let maxForwardSteps = selectedCells
      .map({ Int(((contentSize.width - subbeatWidth - $0.frame.maxX) / subbeatWidth).rounded(.down)) })
      .min() ?? 0
    let maxBackwardSteps = selectedCells
      .map({ Int((($0.frame.width - subbeatWidth) / subbeatWidth).rounded(.down)) })
      .min() ?? 0
    let widthSteps = MIDITimeTableDragStepMath.steps(
      translation: translation.x,
      stepSize: subbeatWidth,
      maxForwardSteps: maxForwardSteps,
      maxBackwardSteps: maxBackwardSteps)

    if widthSteps != 0 {
      let dw = CGFloat(widthSteps) * subbeatWidth
      for cell in selectedCells {
        cell.frame.size.width += dw
      }
      pan.setTranslation(CGPoint(x: translation.x - dw, y: translation.y), in: self)
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
      let newCellRow = Int(((cellView.frame.minY - measureHeight) / rowHeight).rounded())

      editedCells.append((
        cellView.cellID ?? MIDITimeTableCellID(),
        cell,
        newCellRow,
        newCellPosition,
        newCellDuration))
    }

    editingCellIndices = []

    // The resolver only computes what happens to the OTHER cells the edit now overlaps; fold
    // the edited cells' own new geometry in so `result` is a complete, self-sufficient set that
    // both `applyEditResult` below and a host's `rowData.apply(result)` can act on alone.
    var result = MIDITimeTableCellOverlapResolver.resolve(editedCells: editedCells, in: rowData)
    result.updates = editedCells + result.updates

    // Keep the time table's own state correct incrementally before telling anyone about it, so
    // a delegate inspecting the time table during these callbacks already sees the new state.
    applyEditResult(result)

    timeTableDelegate?.midiTimeTableView(self, didEdit: result)
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
      .compactMap({ cellIndex(of: $0) })
    timeTableDelegate?.midiTimeTableView(self, didDelete: deletingCellIndices)
  }

  // MARK: MIDITimeTablePlayheadViewDelegate

  public func playheadView(_ playheadView: MIDITimeTablePlayheadView, didPan panGestureRecognizer: UIPanGestureRecognizer) {
    let translation = panGestureRecognizer.translation(in: self)

    // Fully catch up with the pan translation instead of moving a single
    // quantized step per callback, so the head never trails the finger.
    let steps = MIDITimeTableDragStepMath.steps(
      translation: translation.x,
      stepSize: subbeatWidth,
      maxForwardSteps: Int(((contentSize.width - playheadView.frame.maxX) / subbeatWidth).rounded(.down)),
      maxBackwardSteps: Int(((playheadView.frame.minX - headerCellWidth) / subbeatWidth).rounded(.down)))

    if steps != 0 {
      playheadView.position = max(0, playheadView.position + (Double(steps) / Double(snapResolution)))
      panGestureRecognizer.setTranslation(CGPoint(x: translation.x - (CGFloat(steps) * subbeatWidth), y: translation.y), in: self)
    }

    // Fire delegate
    if panGestureRecognizer.state == .ended || panGestureRecognizer.state == .cancelled || panGestureRecognizer.state == .failed {
      if playheadView == self.playheadView {
        timeTableDelegate?.midiTimeTableView(self, didUpdatePlayhead: playheadView.position)
      } else if playheadView == rangeheadView {
        timeTableDelegate?.midiTimeTableView(self, didUpdateRangeHead: rangeheadView.position)
      }
    }
  }

  // MARK: MIDITimeTableHistoryDelegate

  public func midiTimeTableHistory(_ history: MIDITimeTableHistory, didHistoryChange item: MIDITimeTableHistoryItem) {
    if holdsHistory {
      reloadData(historyItem: item)
      timeTableDelegate?.midiTimeTableView(self, historyDidChange: history)
    }
  }
}
