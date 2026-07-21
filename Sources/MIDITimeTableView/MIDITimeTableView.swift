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
  /// Cell views currently realized: on screen (plus a small overscan margin, see
  /// `virtualizationOverscanMultiplier`) or pinned because their cell is selected. Renamed from
  /// the old, fully-dense `cellViews` — a cell being absent here doesn't mean it doesn't exist in
  /// the data source, only that it isn't currently rendered as a view. Kept in sync by the
  /// windowing pass in `layoutSubviews`.
  public private(set) var visibleCells = [MIDITimeTableCellView]()
  /// Realized cell views keyed by their cell's stable id, for O(1) lookup (`cellView(for:)`).
  /// Kept in sync with `visibleCells`.
  private var realizedCellViewsByID = [MIDITimeTableCellID: MIDITimeTableCellView]()
  /// Freed cell views available to be dequeued and reconfigured (via a row's
  /// `configureCellView`) for a different cell in the same row, instead of being deallocated and
  /// recreated from scratch. Keyed by row index; a row only accumulates entries here if it
  /// opted into `configureCellView`.
  private var cellViewReusePools = [Int: [MIDITimeTableCellView]]()
  /// Multiplier applied to the current viewport size to compute the overscan margin used to
  /// decide which cells/grid lines/measure bars to realize. Defaults `1`, i.e. content within one
  /// extra screen's worth of scrolling in every direction is realized ahead of time, so fast
  /// scrolling doesn't show a pop-in edge.
  public var virtualizationOverscanMultiplier: CGFloat = 1

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
  private var minimumDragViewDisplaySize: CGFloat = 12
  private var dragViewAutoScrollingThreshold: CGFloat = 100
  private var autoScrollingTimer: Timer?
  private var autoScrollingTimerInterval: TimeInterval = 0.3
  private var autoScrollAccumulatedTranslation: CGPoint = .zero
  private enum AutoScrollingMode {
    case dragSelection
    case cellMove
    case cellResize
  }
  private var autoScrollingMode: AutoScrollingMode?

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
    backgroundColor = .clear
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

    // Realize only the cells within the viewport (plus an overscan margin) or pinned by
    // selection; recycle everything else into its row's reuse pool instead of keeping every
    // cell's view alive regardless of document size. See `dequeueCellView`/`recycleCellView`.
    //
    // Done in two passes rather than one: first work out *which* cells need to end up realized
    // (pure frame math, no view work), then recycle whatever's no longer needed, and only then
    // dequeue/create views for anything newly needed. That ordering matters — it's what lets a
    // view freed by a cell leaving the window in this same pass be immediately reused for a
    // different cell entering it, instead of only becoming available on the pass after.
    let overscanRect = CGRect(origin: contentOffset, size: bounds.size)
      .insetBy(dx: -bounds.width * virtualizationOverscanMultiplier, dy: -bounds.height * virtualizationOverscanMultiplier)

    var duration = 0.0
    var toRealize: [(id: MIDITimeTableCellID, rowIndex: Int, indexInRow: Int, frame: CGRect)] = []
    var neededIDs = Set<MIDITimeTableCellID>()

    for i in 0..<rowData.count {
      let currentRow = rowData[i]
      duration = currentRow.duration > duration ? currentRow.duration : duration
      for (index, cell) in currentRow.cells.enumerated() {
        let startX = beatWidth * CGFloat(cell.position)
        let width = beatWidth * CGFloat(cell.duration)
        let cellFrame = CGRect(
          x: headerCellWidth + startX,
          y: measureHeight + (CGFloat(i) * rowHeight),
          width: width,
          height: rowHeight)

        // A selected cell is pinned: kept realized regardless of the viewport so drag/resize
        // (which reads and writes geometry through the view, not the model, mid-gesture) always
        // has a live view to work with, even mid-scroll.
        guard overscanRect.intersects(cellFrame) || realizedCellViewsByID[cell.id]?.isSelected == true else { continue }
        neededIDs.insert(cell.id)
        toRealize.append((cell.id, i, index, cellFrame))
      }
    }

    for (id, view) in realizedCellViewsByID where !neededIDs.contains(id) {
      recycleCellView(view, id: id)
    }

    var newRealizedByID = [MIDITimeTableCellID: MIDITimeTableCellView]()
    newRealizedByID.reserveCapacity(toRealize.count)
    var newVisibleCells = [MIDITimeTableCellView]()
    newVisibleCells.reserveCapacity(toRealize.count)

    for placement in toRealize {
      let owningRow = rowData[placement.rowIndex]
      let cell = owningRow.cells[placement.indexInRow]
      let cellView = realizedCellViewsByID[placement.id] ?? dequeueCellView(for: cell, rowIndex: placement.rowIndex, owningRow: owningRow)
      cellView.frame = placement.frame
      cellView.tag = placement.indexInRow
      cellView.cellID = placement.id
      newRealizedByID[placement.id] = cellView
      newVisibleCells.append(cellView)
    }

    realizedCellViewsByID = newRealizedByID
    visibleCells = newVisibleCells

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

    // Keep the entire visible timetable surface inside the scroll view's content area, even
    // when there are no rows or only a few rows. Otherwise gestures that begin below the last row
    // can fall outside the scrollable content and never start marquee selection.
    let rowsContentHeight = measureView.frame.height + (rowHeight * CGFloat(rowHeaderCellViews.count))
    contentSize = CGSize(
      width: headerCellWidth + measureView.frame.width,
      height: max(rowsContentHeight, bounds.height))

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
    // Clip line drawing to the viewport. Unlike the rest of this method, this needs to redraw on
    // a pure scroll too (the grid's `frame` itself doesn't change), so ask explicitly rather than
    // rely on the frame assignment above to (not) trigger it.
    gridLayer.virtualizationRect = overscanRect
    gridLayer.setNeedsLayout()

    // Measure view's per-bar snap ticks.
    measureView.snapResolution = snapResolution
    // Same reasoning as the grid layer: only realize bar layers within the viewport, and force a
    // relayout on pure scroll since `measureView.frame` itself doesn't change from it.
    measureView.virtualizationRect = CGRect(
      x: overscanRect.minX - headerCellWidth,
      y: 0,
      width: overscanRect.width,
      height: measureHeight)
    measureView.setNeedsLayout()
  }


  /// Populates row and cell datas from its data source and redraws time table. Could be invoked with an history item.
  ///
  /// - Parameter keepHistory: If you specify the history writing even if it is enabled, you can control it from here either.
  /// - Parameter historyItem: Optional history item. Defaults nil.
  public func reloadData(keepHistory: Bool = true, historyItem: MIDITimeTableHistoryItem? = nil) {
    // Reset data source
    rowHeaderCellViews.forEach({ $0.removeFromSuperview() })
    rowHeaderCellViews = []
    realizedCellViewsByID.values.forEach({ $0.removeFromSuperview() })
    realizedCellViewsByID = [:]
    cellViewReusePools = [:]
    visibleCells = []

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
    }

    // Delegate
    rowHeight = timeTableDelegate?.midiTimeTableViewHeightForRows(self) ?? rowHeight
    measureHeight = showsMeasure ? (timeTableDelegate?.midiTimeTableViewHeightForMeasureView(self) ?? measureHeight) : 0
    headerCellWidth = showsHeaders ? timeTableDelegate?.midiTimeTableViewWidthForRowHeaderCells(self) ?? headerCellWidth : 0
    snapResolution = max(1, timeTableDelegate?.midiTimeTableViewSnapResolution(self) ?? snapResolution)

    // Cell views aren't created here anymore — the next layout pass's windowing logic (see
    // `layoutSubviews`) realizes only the cells within the viewport on demand, instead of
    // eagerly instantiating one for every cell in every row regardless of what's on screen.
    // Forced synchronously so callers see up-to-date `visibleCells` immediately, matching the
    // old eager behavior's guarantee.
    setNeedsLayout()
    layoutIfNeeded()

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
    // A removed cell no longer belongs to any row, so its view is dropped outright — removed
    // from the hierarchy and not pooled, since there's nothing left to dequeue it for.
    for id in result.removals {
      if let view = realizedCellViewsByID.removeValue(forKey: id) {
        view.isSelected = false
        view.removeFromSuperview()
      }
    }

    rowData.apply(result)

    // Everything else — updates (including moves across rows) and insertions — is picked up by
    // the next layout pass's windowing logic (see `layoutSubviews`): a cell untouched by this
    // edit keeps its existing view instance exactly as it was; a moved/resized cell's view (same
    // instance, found by id) is simply repositioned; a brand new cell (e.g. a split-off
    // remainder) gets a view dequeued from its row's reuse pool or created fresh. Forced
    // synchronously so callers see up-to-date `visibleCells` immediately after this call returns.
    setNeedsLayout()
    layoutIfNeeded()

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

  /// Returns a cell's currently realized view, if any. `nil` if the cell exists in the data but
  /// isn't currently realized — off-screen and unselected, see `visibleCells`.
  ///
  /// - Parameter id: Stable id of the cell to look up.
  /// - Returns: The cell's realized view, or `nil`.
  public func cellView(for id: MIDITimeTableCellID) -> MIDITimeTableCellView? {
    return realizedCellViewsByID[id]
  }

  /// Gets the row and column index of the cell view in the data source.
  ///
  /// - Parameter cell: The cell you want to get row and column info.
  /// - Returns: Returns a row and column index Int pair in a tuple.
  public func cellIndex(of cell: MIDITimeTableCellView) -> MIDITimeTableCellIndex? {
    guard let id = cell.cellID else { return nil }
    return rowData.index(ofCellID: id)
  }

  /// Returns a view for `cell` in row `rowIndex`: a view dequeued from that row's reuse pool and
  /// reconfigured via `owningRow.configureCellView` when one's available, otherwise a freshly
  /// created instance via `owningRow.cellView`. Pools are kept per-row, so a dequeued instance is
  /// always the exact subclass `owningRow.cellView` would have produced.
  private func dequeueCellView(for cell: MIDITimeTableCellData, rowIndex: Int, owningRow: MIDITimeTableRowData) -> MIDITimeTableCellView {
    let cellView: MIDITimeTableCellView
    if var pool = cellViewReusePools[rowIndex], let reused = pool.popLast() {
      cellViewReusePools[rowIndex] = pool
      owningRow.configureCellView?(reused, cell)
      cellView = reused
    } else {
      cellView = owningRow.cellView(cell)
    }
    cellView.delegate = self
    addSubview(cellView)
    return cellView
  }

  /// Frees a realized cell view no longer needed this layout pass: clears its selection, removes
  /// it from the hierarchy, and — only if the cell it represented still exists in `rowData` and
  /// that row opted into `configureCellView` — returns it to that row's reuse pool for a future
  /// dequeue. Otherwise the view is simply discarded.
  private func recycleCellView(_ view: MIDITimeTableCellView, id: MIDITimeTableCellID) {
    view.isSelected = false
    view.removeFromSuperview()
    guard let owningRowIndex = rowData.index(ofCellID: id)?.row, rowData[owningRowIndex].configureCellView != nil else { return }
    cellViewReusePools[owningRowIndex, default: []].append(view)
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
      updateAutoScrolling(touchLocation: touchLocation, mode: .dragSelection, allowsVertical: true)
    case .ended, .cancelled, .failed:
      endDragging()
    default:
      break
    }
  }

  private func createDragView() {
    isScrollEnabled = false

    unselectAllCells()

    dragView = UIView(frame: displayFrame(forDragSelectionRect: CGRect(origin: dragStartPosition, size: .zero), touchLocation: dragStartPosition))
    dragView?.layer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor
    dragView?.layer.borderColor = UIColor.white.cgColor
    dragView?.layer.borderWidth = 1
    addSubview(dragView!)
  }

  private func updateDragView(touchLocation: CGPoint) {
    guard let dragView = dragView else { return }

    let selectionRect = CGRect(
      x: min(dragStartPosition.x, touchLocation.x),
      y: min(dragStartPosition.y, touchLocation.y),
      width: abs(touchLocation.x - dragStartPosition.x),
      height: abs(touchLocation.y - dragStartPosition.y))
    dragView.frame = displayFrame(forDragSelectionRect: selectionRect, touchLocation: touchLocation)

    // Make cells selected. Only cells currently realized can possibly intersect a marquee that's
    // itself bounded to the (auto-)scrollable viewport, so `visibleCells` — not the full data
    // source — is exactly the right set to check.
    visibleCells
      .forEach({ $0.isSelected = selectionRect.intersects($0.frame) })
  }

  private func displayFrame(forDragSelectionRect selectionRect: CGRect, touchLocation: CGPoint) -> CGRect {
    let width = max(selectionRect.width, minimumDragViewDisplaySize)
    let height = max(selectionRect.height, minimumDragViewDisplaySize)
    let x = touchLocation.x < dragStartPosition.x ? dragStartPosition.x - width : dragStartPosition.x
    let y = touchLocation.y < dragStartPosition.y ? dragStartPosition.y - height : dragStartPosition.y
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private func updateAutoScrolling(touchLocation: CGPoint, mode: AutoScrollingMode, allowsVertical: Bool) {
    endAutoScrolling()

    var autoScrollDirection = autoScrollDirection(for: touchLocation, allowsVertical: allowsVertical)
    if autoScrollDirection.isEmpty {
      return
    }

    autoScrollDirection.formIntersection(allowedAutoScrollDirections(for: mode))
    if autoScrollDirection.isEmpty {
      return
    }

    dragCurrentPosition = touchLocation
    startAutoScrollTimer(with: autoScrollDirection, mode: mode)
  }

  private func autoScrollDirection(for touchLocation: CGPoint, allowsVertical: Bool) -> MIDITimeTableViewAutoScrollDirection {
    var autoScrollDirection = MIDITimeTableViewAutoScrollDirection()
    let visibleRect = CGRect(origin: contentOffset, size: bounds.size)

    if allowsVertical {
      if touchLocation.y < visibleRect.minY + dragViewAutoScrollingThreshold, contentOffset.y > 0 {
        autoScrollDirection.insert(.up)
      } else if touchLocation.y > visibleRect.maxY - dragViewAutoScrollingThreshold, contentOffset.y + bounds.height < contentSize.height {
        autoScrollDirection.insert(.down)
      }
    }

    if touchLocation.x < visibleRect.minX + dragViewAutoScrollingThreshold, contentOffset.x > 0 {
      autoScrollDirection.insert(.left)
    } else if touchLocation.x > visibleRect.maxX - dragViewAutoScrollingThreshold, contentOffset.x + bounds.width < contentSize.width {
      autoScrollDirection.insert(.right)
    }

    return autoScrollDirection
  }

  private func allowedAutoScrollDirections(for mode: AutoScrollingMode) -> MIDITimeTableViewAutoScrollDirection {
    switch mode {
    case .dragSelection:
      return [.left, .right, .up, .down]
    case .cellMove:
      return allowedMoveAutoScrollDirections()
    case .cellResize:
      return allowedResizeAutoScrollDirections()
    }
  }

  private func allowedMoveAutoScrollDirections() -> MIDITimeTableViewAutoScrollDirection {
    let selectedCells = visibleCells.filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return [] }

    let groupMinX = selectedCells.map({ $0.frame.minX }).min() ?? headerCellWidth
    let groupMaxX = selectedCells.map({ $0.frame.maxX }).max() ?? headerCellWidth
    let groupMinY = selectedCells.map({ $0.frame.minY }).min() ?? measureHeight
    let groupMaxY = selectedCells.map({ $0.frame.maxY }).max() ?? measureHeight
    let rowsBottom = measureHeight + (rowHeight * CGFloat(rowData.count))

    var directions = MIDITimeTableViewAutoScrollDirection()
    if groupMinX - headerCellWidth >= subbeatWidth {
      directions.insert(.left)
    }
    if contentSize.width - groupMaxX >= subbeatWidth {
      directions.insert(.right)
    }
    if groupMinY - measureHeight >= rowHeight {
      directions.insert(.up)
    }
    if rowsBottom - groupMaxY >= rowHeight {
      directions.insert(.down)
    }
    return directions
  }

  private func allowedResizeAutoScrollDirections() -> MIDITimeTableViewAutoScrollDirection {
    let selectedCells = visibleCells.filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return [] }

    let canShrink = selectedCells.allSatisfy({ $0.frame.width - subbeatWidth >= subbeatWidth })
    let canGrow = selectedCells.allSatisfy({ contentSize.width - subbeatWidth - $0.frame.maxX >= subbeatWidth })

    var directions = MIDITimeTableViewAutoScrollDirection()
    if canShrink {
      directions.insert(.left)
    }
    if canGrow {
      directions.insert(.right)
    }
    return directions
  }

  private func startAutoScrollTimer(with direction: MIDITimeTableViewAutoScrollDirection, mode: AutoScrollingMode) {
    autoScrollingMode = mode
    // Block-based, with the direction captured directly — no `userInfo` dictionary/`Any`
    // round-trip to unpack on every tick.
    autoScrollingTimer = Timer.scheduledTimer(withTimeInterval: autoScrollingTimerInterval, repeats: true) { [weak self] _ in
      self?.autoScrollTimerTick(direction: direction)
    }
  }

  private func autoScrollTimerTick(direction: MIDITimeTableViewAutoScrollDirection) {
    guard let dragCurrentPosition = dragCurrentPosition, let autoScrollingMode = autoScrollingMode else { return }
    let currentDirection = direction.intersection(allowedAutoScrollDirections(for: autoScrollingMode))
    if currentDirection.isEmpty {
      endAutoScrolling()
      return
    }

    var scrollDirection = CGPoint.zero
    if currentDirection.contains(.left) {
      scrollDirection.x -= 1
    }
    if currentDirection.contains(.right) {
      scrollDirection.x += 1
    }
    if currentDirection.contains(.up) {
      scrollDirection.y -= 1
    }
    if currentDirection.contains(.down) {
      scrollDirection.y += 1
    }

    // Calculate and auto scroll

    let scrollAmount = CGSize(
      width: scrollDirection.x * dragViewAutoScrollingThreshold,
      height: scrollDirection.y * dragViewAutoScrollingThreshold)

    let targetContentOffset = CGPoint(
      x: min(max(0, contentOffset.x + scrollAmount.width), max(0, contentSize.width - bounds.width)),
      y: min(max(0, contentOffset.y + scrollAmount.height), max(0, contentSize.height - bounds.height)))
    if targetContentOffset == contentOffset {
      endAutoScrolling()
      return
    }

    UIView.animate(
      withDuration: autoScrollingTimerInterval,
      animations: {
        let previousContentOffset = self.contentOffset
        self.setContentOffset(targetContentOffset, animated: false)
        let actualScrollDelta = CGPoint(
          x: self.contentOffset.x - previousContentOffset.x,
          y: self.contentOffset.y - previousContentOffset.y)

        switch autoScrollingMode {
        case .dragSelection:
          let position = CGPoint(
            x: dragCurrentPosition.x + actualScrollDelta.x,
            y: dragCurrentPosition.y + actualScrollDelta.y)
          self.dragCurrentPosition = position
          self.updateDragView(touchLocation: position)
        case .cellMove:
          self.autoScrollAccumulatedTranslation.x += actualScrollDelta.x
          self.autoScrollAccumulatedTranslation.y += actualScrollDelta.y
          let consumedTranslation = self.applyMoveTranslation(self.autoScrollAccumulatedTranslation)
          self.autoScrollAccumulatedTranslation.x -= consumedTranslation.x
          self.autoScrollAccumulatedTranslation.y -= consumedTranslation.y
        case .cellResize:
          self.autoScrollAccumulatedTranslation.x += actualScrollDelta.x
          let consumedTranslation = self.applyResizeTranslation(CGPoint(x: self.autoScrollAccumulatedTranslation.x, y: 0))
          self.autoScrollAccumulatedTranslation.x -= consumedTranslation.x
        }
      })
  }

  private func endAutoScrolling() {
    autoScrollingTimer?.invalidate()
    autoScrollingTimer = nil
    autoScrollingMode = nil
    autoScrollAccumulatedTranslation = .zero
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

  /// Makes all cells unselected. A selected cell is always realized (see `visibleCells`), so
  /// this reaches every selected cell in the whole document, not just the ones on screen.
  public func unselectAllCells() {
    visibleCells.forEach({ $0.isSelected = false })
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
      if !midiTimeTableCellView.isSelected {
        unselectAllCells()
      }
      midiTimeTableCellView.isSelected = true
      editingCellIndices = visibleCells
        .filter({ $0.isSelected })
        .compactMap({ cellIndex(of: $0) })
    }

    isMoving = true

    let consumedTranslation = applyMoveTranslation(translation)
    if consumedTranslation != .zero {
      pan.setTranslation(
        CGPoint(
          x: translation.x - consumedTranslation.x,
          y: translation.y - consumedTranslation.y),
        in: self)
    }

    switch pan.state {
    case .began, .changed:
      updateAutoScrolling(touchLocation: pan.location(in: self), mode: .cellMove, allowsVertical: true)
    case .ended, .cancelled, .failed:
      endAutoScrolling()
      isMoving = false
      didEditCells(editingCellIndices)
    default:
      break
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(midiTimeTableCellView)

    if case .began = pan.state {
      isResizing = true
      if !midiTimeTableCellView.isSelected {
        unselectAllCells()
      }
      midiTimeTableCellView.isSelected = true
      editingCellIndices = visibleCells
        .filter({ $0.isSelected })
        .compactMap({ cellIndex(of: $0) })
    }

    let consumedTranslation = applyResizeTranslation(translation)
    if consumedTranslation != .zero {
      pan.setTranslation(
        CGPoint(
          x: translation.x - consumedTranslation.x,
          y: translation.y),
        in: self)
    }

    switch pan.state {
    case .began, .changed:
      updateAutoScrolling(touchLocation: pan.location(in: self), mode: .cellResize, allowsVertical: false)
    case .ended, .cancelled, .failed:
      endAutoScrolling()
      isResizing = false
      didEditCells(editingCellIndices)
    default:
      break
    }
  }

  private func applyMoveTranslation(_ translation: CGPoint) -> CGPoint {
    // A selected cell is always realized (see `visibleCells`), so this is the complete selection
    // regardless of how much of it is currently on screen.
    let selectedCells = visibleCells.filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return .zero }

    // Bounding box of the whole selection so the group moves as one unit
    // and no member overshoots the table's edges.
    let groupMinX = selectedCells.map({ $0.frame.minX }).min() ?? headerCellWidth
    let groupMaxX = selectedCells.map({ $0.frame.maxX }).max() ?? headerCellWidth
    let groupMinY = selectedCells.map({ $0.frame.minY }).min() ?? measureHeight
    let groupMaxY = selectedCells.map({ $0.frame.maxY }).max() ?? measureHeight
    let rowsBottom = measureHeight + (rowHeight * CGFloat(rowData.count))

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

    guard xSteps != 0 || ySteps != 0 else { return .zero }

    let dx = CGFloat(xSteps) * subbeatWidth
    let dy = CGFloat(ySteps) * rowHeight
    for cell in selectedCells {
      cell.frame.origin.x += dx
      cell.frame.origin.y += dy
    }

    return CGPoint(x: dx, y: dy)
  }

  private func applyResizeTranslation(_ translation: CGPoint) -> CGPoint {
    let selectedCells = visibleCells.filter({ $0.isSelected })
    guard !selectedCells.isEmpty else { return .zero }

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

    guard widthSteps != 0 else { return .zero }

    let dw = CGFloat(widthSteps) * subbeatWidth
    for cell in selectedCells {
      cell.frame.size.width += dw
    }

    return CGPoint(x: dw, y: 0)
  }

  private func didEditCells(_ cells: [MIDITimeTableCellIndex]) {
    var editedCells = [MIDITimeTableViewEditedCellData]()

    for cell in cells {
      // `cells` is a snapshot of (row, array-position) taken when the gesture began; `rowData`
      // hasn't been mutated since (only view frames were, mid-gesture), so it's still valid here.
      guard cell.row >= 0, cell.row < rowData.count,
        cell.index >= 0, cell.index < rowData[cell.row].cells.count
        else { continue }
      let id = rowData[cell.row].cells[cell.index].id
      // Edited cells are selected, and a selected cell is always realized (see `visibleCells`),
      // so this lookup is guaranteed to succeed barring a caller-side inconsistency.
      guard let cellView = realizedCellViewsByID[id] else { continue }

      let newCellPosition = Double(cellView.frame.minX - headerCellWidth) / Double(beatWidth)
      let newCellDuration = Double(cellView.frame.size.width / beatWidth)
      let newCellRow = Int(((cellView.frame.minY - measureHeight) / rowHeight).rounded())

      editedCells.append((id, cell, newCellRow, newCellPosition, newCellDuration))
    }

    editingCellIndices = []

    // The resolver only computes what happens to the OTHER cells the edit now overlaps; fold
    // the edited cells' own new geometry in so `result` is a complete, self-sufficient set that
    // both `applyEditResult` below and a host's `rowData.apply(result)` can act on alone.
    let editedOverlapResult = MIDITimeTableCellOverlapResolver.resolveOverlapsAmongEditedCells(editedCells)
    var result = MIDITimeTableCellOverlapResolver.resolve(
      editedCells: editedOverlapResult.updates,
      in: rowData,
      skippingCellIDs: Set(editedCells.map({ $0.id })))
    result.updates = editedOverlapResult.updates + result.updates
    result.removals = editedOverlapResult.removals + result.removals

    // Keep the time table's own state correct incrementally before telling anyone about it, so
    // a delegate inspecting the time table during these callbacks already sees the new state.
    applyEditResult(result)

    timeTableDelegate?.midiTimeTableView(self, didEdit: result)
  }

  public func midiTimeTableCellViewDidTap(_ midiTimeTableCellView: MIDITimeTableCellView) {
    // A selected cell is always realized (see `visibleCells`), so this correctly deselects every
    // previously-selected cell, on screen or not.
    for cell in visibleCells {
      cell.isSelected = cell == midiTimeTableCellView
    }
  }

  public func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView) {
    let deletingCellIndices = visibleCells
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
