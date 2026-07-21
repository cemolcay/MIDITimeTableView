//
//  MIDITimeTableApplyEditResultTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

/// Minimal data source/delegate double so `MIDITimeTableView.reloadData()` can populate real
/// cell views to exercise `applyEditResult`/`removeCells` against.
private final class StubDataSource: MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
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

final class MIDITimeTableApplyEditResultTests: XCTestCase {

  private func makeRow(_ cells: [(position: Double, duration: Double)]) -> MIDITimeTableRowData {
    return MIDITimeTableRowData(
      cells: cells.map({ MIDITimeTableCellData(data: 0, position: $0.position, duration: $0.duration) }),
      headerCellView: MIDITimeTableHeaderCellView(),
      cellView: { _ in MIDITimeTableCellView() })
  }

  /// Builds a time table with the given rows already loaded, plus the stub keeping it alive
  /// (dataSource/delegate are weak). All the cells used across this file sit well within the
  /// small test frame, so they're realized (see `MIDITimeTableView.visibleCells`) right after
  /// `reloadData()` and stay that way — none of these tests are about virtualization itself.
  private func makeLoadedTimeTable(_ rows: [MIDITimeTableRowData]) -> (MIDITimeTableView, StubDataSource) {
    let stub = StubDataSource(rows: rows)
    let view = MIDITimeTableView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    view.dataSource = stub
    view.timeTableDelegate = stub
    view.reloadData()
    return (view, stub)
  }

  func testApplyEditResultReusesExistingViewInstanceForUnrelatedCell() {
    let row = makeRow([(position: 0, duration: 4), (position: 10, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub // keep alive
    let untouchedID = row.cells[1].id
    let untouchedView = timeTable.cellView(for: untouchedID)
    XCTAssertNotNil(untouchedView)
    let movedID = row.cells[0].id

    let result = MIDITimeTableCellEditResult(
      updates: [(id: movedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)])
    timeTable.applyEditResult(result)

    // The untouched cell keeps its exact same view instance — no teardown/recreate.
    XCTAssertTrue(timeTable.cellView(for: untouchedID) === untouchedView)
  }

  func testApplyEditResultMovesViewToNewRowKeepingIdentity() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row, makeRow([])])
    _ = stub
    let id = row.cells[0].id
    guard let cellView = timeTable.cellView(for: id) else {
      return XCTFail("expected the cell to be realized right after reloadData()")
    }

    let result = MIDITimeTableCellEditResult(
      updates: [(id: id, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 1, newPosition: 6, newDuration: 4)])
    timeTable.applyEditResult(result)

    // Same view instance moved to the new row, not a freshly created one.
    XCTAssertTrue(timeTable.cellView(for: id) === cellView)
    XCTAssertEqual(timeTable.cellIndex(of: cellView)?.row, 1)
  }

  func testApplyEditResultRemovesCoveredCellView() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub
    let removedID = row.cells[1].id
    let removedView = timeTable.cellView(for: removedID)
    XCTAssertNotNil(removedView)

    timeTable.applyEditResult(MIDITimeTableCellEditResult(removals: [removedID]))

    XCTAssertNil(timeTable.cellView(for: removedID))
    XCTAssertNil(removedView?.superview, "removed cell's view should be taken out of the hierarchy")
  }

  func testApplyEditResultInsertsNewViewForSplitRemainder() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub

    let newCell = MIDITimeTableCellData(data: 0, position: 8, duration: 2)
    timeTable.applyEditResult(MIDITimeTableCellEditResult(insertions: [(row: 0, cell: newCell)]))

    XCTAssertNotNil(timeTable.cellView(for: newCell.id))
  }

  func testRemoveCellsAtIndicesRemovesIncrementally() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub
    let keptID = row.cells[0].id
    let keptView = timeTable.cellView(for: keptID)
    XCTAssertNotNil(keptView)

    timeTable.removeCells(at: [MIDITimeTableCellIndex(row: 0, index: 1)])

    XCTAssertTrue(timeTable.cellView(for: keptID) === keptView)
  }
}
