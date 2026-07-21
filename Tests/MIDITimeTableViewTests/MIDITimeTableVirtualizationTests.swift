//
//  MIDITimeTableVirtualizationTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

/// Minimal data source/delegate double, mirroring the one in
/// `MIDITimeTableApplyEditResultTests.swift`, so `MIDITimeTableView.reloadData()` can populate
/// real cell views to exercise viewport windowing and reuse pooling against.
private final class VirtualizationStubDataSource: MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
  var rows: [MIDITimeTableRowData]

  init(rows: [MIDITimeTableRowData]) {
    self.rows = rows
  }

  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int { rows.count }
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
    MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowAt index: Int) -> MIDITimeTableRowData { rows[index] }

  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDelete cells: [MIDITimeTableCellIndex]) {}
  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 20 }
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 60 }
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 100 }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double) {}
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double) {}
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, historyDidChange history: MIDITimeTableHistory) {}
}

final class MIDITimeTableVirtualizationTests: XCTestCase {

  /// A time table 400pt wide/tall, with beats 50pt apart (measureWidth 200 / 4 beats) and a
  /// header column 100pt wide, so a cell's on-screen x is `100 + position * 50`. With the
  /// default `virtualizationOverscanMultiplier` of 1, the realized window when scrolled to
  /// `contentOffset.x` spans roughly `[contentOffset.x - 400, contentOffset.x + 800]` in that
  /// coordinate space — comfortably separating "near" positions (realized) from "far" ones (not)
  /// in the tests below.
  private func makeLoadedTimeTable(rows: [MIDITimeTableRowData]) -> (MIDITimeTableView, VirtualizationStubDataSource) {
    let stub = VirtualizationStubDataSource(rows: rows)
    let view = MIDITimeTableView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    view.dataSource = stub
    view.timeTableDelegate = stub
    view.reloadData()
    return (view, stub)
  }

  private func makeRow(
    _ cells: [MIDITimeTableCellData],
    configureCellView: ((MIDITimeTableCellView, MIDITimeTableCellData) -> Void)? = nil
  ) -> MIDITimeTableRowData {
    return MIDITimeTableRowData(
      cells: cells,
      headerCellView: MIDITimeTableHeaderCellView(),
      cellView: { _ in MIDITimeTableCellView() },
      configureCellView: configureCellView)
  }

  /// Scrolls the time table and forces a synchronous re-layout, since XCTest doesn't pump a run
  /// loop that would otherwise pick up a deferred `setNeedsLayout()`.
  private func scroll(_ timeTable: MIDITimeTableView, to x: CGFloat) {
    timeTable.contentOffset = CGPoint(x: x, y: 0)
    timeTable.setNeedsLayout()
    timeTable.layoutIfNeeded()
  }

  func testFarCellIsNotRealizedUntilScrolledIntoView() {
    let nearCell = MIDITimeTableCellData(data: 0, position: 0, duration: 1)
    let farCell = MIDITimeTableCellData(data: 0, position: 60, duration: 1) // x ≈ 3100pt
    let (timeTable, stub) = makeLoadedTimeTable(rows: [makeRow([nearCell, farCell])])
    _ = stub // keep alive

    XCTAssertNotNil(timeTable.cellView(for: nearCell.id), "the near cell should be realized right after reloadData()")
    XCTAssertNil(timeTable.cellView(for: farCell.id), "the far cell should not be realized while off-screen")
    XCTAssertEqual(timeTable.visibleCells.count, 1, "only the on-screen cell should have a live view")

    scroll(timeTable, to: 2800) // brings the far cell's x (≈3100) into the overscan window

    XCTAssertNotNil(timeTable.cellView(for: farCell.id), "the far cell should realize once scrolled into view")
    XCTAssertNil(timeTable.cellView(for: nearCell.id), "the near cell should free once scrolled far out of view")
  }

  func testFreedViewIsDequeuedAndReconfiguredForANewCellInTheSameRow() {
    var configuredIDs = [MIDITimeTableCellID]()
    let nearCell = MIDITimeTableCellData(data: 0, position: 0, duration: 1)
    let farCell = MIDITimeTableCellData(data: 0, position: 60, duration: 1)
    let row = makeRow([nearCell, farCell], configureCellView: { _, cell in configuredIDs.append(cell.id) })
    let (timeTable, stub) = makeLoadedTimeTable(rows: [row])
    _ = stub

    guard let nearView = timeTable.cellView(for: nearCell.id) else {
      return XCTFail("expected the near cell to be realized right after reloadData()")
    }

    // Scrolls the near cell out of view and the far cell into view in the same pass, so the
    // near cell's freed view is available in that very pass for the far cell to dequeue.
    scroll(timeTable, to: 2800)

    XCTAssertTrue(timeTable.cellView(for: farCell.id) === nearView, "the dequeued view should be the exact instance freed from the same row")
    XCTAssertTrue(configuredIDs.contains(farCell.id), "configureCellView should have been invoked for the reused view's new cell")
  }

  func testSelectedOffscreenCellStaysRealizedAndFreesOnceDeselected() {
    let nearCell = MIDITimeTableCellData(data: 0, position: 0, duration: 1)
    let farCell = MIDITimeTableCellData(data: 0, position: 60, duration: 1)
    let (timeTable, stub) = makeLoadedTimeTable(rows: [makeRow([nearCell, farCell])])
    _ = stub

    // Realize the far cell by scrolling to it, select it, then scroll back away.
    scroll(timeTable, to: 2800)
    guard let farView = timeTable.cellView(for: farCell.id) else {
      return XCTFail("expected the far cell to realize once scrolled into view")
    }
    farView.isSelected = true

    scroll(timeTable, to: 0)
    XCTAssertTrue(timeTable.cellView(for: farCell.id) === farView, "a selected cell should stay realized even after scrolling away from it")

    farView.isSelected = false
    timeTable.setNeedsLayout()
    timeTable.layoutIfNeeded()
    XCTAssertNil(timeTable.cellView(for: farCell.id), "deselecting should let an off-screen cell free again")
  }

  func testReloadDataOnALargeTimelineRealizesOnlyTheOnscreenSlice() {
    let cells = (0..<500).map { MIDITimeTableCellData(data: 0, position: Double($0) * 4, duration: 1) }
    let (timeTable, stub) = makeLoadedTimeTable(rows: [makeRow(cells)])
    _ = stub

    XCTAssertGreaterThan(timeTable.visibleCells.count, 0)
    XCTAssertLessThan(timeTable.visibleCells.count, cells.count, "only a small on-screen slice should be realized, not all 500 cells")
  }
}
