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
  /// (dataSource/delegate are weak).
  private func makeLoadedTimeTable(_ rows: [MIDITimeTableRowData]) -> (MIDITimeTableView, StubDataSource) {
    let stub = StubDataSource(rows: rows)
    let view = MIDITimeTableView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    view.dataSource = stub
    view.timeTableDelegate = stub
    view.reloadData()
    return (view, stub)
  }

  func testApplyEditResultReusesExistingViewInstanceForUnrelatedCell() {
    let (timeTable, stub) = makeLoadedTimeTable([makeRow([(position: 0, duration: 4), (position: 10, duration: 2)])])
    _ = stub // keep alive
    let untouchedID = timeTable.cellViews[0][1].cellID!
    let untouchedView = timeTable.cellViews[0][1]
    let movedID = timeTable.cellViews[0][0].cellID!

    let result = MIDITimeTableCellEditResult(
      updates: [(id: movedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)])
    timeTable.applyEditResult(result)

    XCTAssertEqual(timeTable.cellViews[0].count, 2)
    // The untouched cell keeps its exact same view instance — no teardown/recreate.
    XCTAssertTrue(timeTable.cellViews[0].contains(where: { $0 === untouchedView && $0.cellID == untouchedID }))
  }

  func testApplyEditResultMovesViewToNewRowKeepingIdentity() {
    let (timeTable, stub) = makeLoadedTimeTable([makeRow([(position: 0, duration: 4)]), makeRow([])])
    _ = stub
    let cellView = timeTable.cellViews[0][0]
    let id = cellView.cellID!

    let result = MIDITimeTableCellEditResult(
      updates: [(id: id, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 1, newPosition: 6, newDuration: 4)])
    timeTable.applyEditResult(result)

    XCTAssertEqual(timeTable.cellViews[0].count, 0)
    XCTAssertEqual(timeTable.cellViews[1].count, 1)
    // Same view instance moved to the new row, not a freshly created one.
    XCTAssertTrue(timeTable.cellViews[1][0] === cellView)
    XCTAssertEqual(timeTable.cellViews[1][0].cellID, id)
  }

  func testApplyEditResultRemovesCoveredCellView() {
    let (timeTable, stub) = makeLoadedTimeTable([makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])])
    _ = stub
    let removedID = timeTable.cellViews[0][1].cellID!
    let removedView = timeTable.cellViews[0][1]

    timeTable.applyEditResult(MIDITimeTableCellEditResult(removals: [removedID]))

    XCTAssertEqual(timeTable.cellViews[0].count, 1)
    XCTAssertNil(removedView.superview, "removed cell's view should be taken out of the hierarchy")
  }

  func testApplyEditResultInsertsNewViewForSplitRemainder() {
    let (timeTable, stub) = makeLoadedTimeTable([makeRow([(position: 0, duration: 4)])])
    _ = stub

    let newCell = MIDITimeTableCellData(data: 0, position: 8, duration: 2)
    timeTable.applyEditResult(MIDITimeTableCellEditResult(insertions: [(row: 0, cell: newCell)]))

    XCTAssertEqual(timeTable.cellViews[0].count, 2)
    XCTAssertTrue(timeTable.cellViews[0].contains(where: { $0.cellID == newCell.id }))
  }

  func testRemoveCellsAtIndicesRemovesIncrementally() {
    let (timeTable, stub) = makeLoadedTimeTable([makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])])
    _ = stub
    let keptView = timeTable.cellViews[0][0]

    timeTable.removeCells(at: [MIDITimeTableCellIndex(row: 0, index: 1)])

    XCTAssertEqual(timeTable.cellViews[0].count, 1)
    XCTAssertTrue(timeTable.cellViews[0][0] === keptView)
  }
}
