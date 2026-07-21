//
//  MIDITimeTableVirtualizationTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

private struct TestCell {
  let id: MIDITimeTableCellID
  var position: Double
  var duration: Double

  init(id: MIDITimeTableCellID = MIDITimeTableCellID(), position: Double, duration: Double) {
    self.id = id
    self.position = position
    self.duration = duration
  }
}

private final class VirtualizationStubDataSource: MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
  var rows: [[TestCell]]
  var didConfigureCell: ((MIDITimeTableCellView, TestCell) -> Void)?

  init(rows: [[TestCell]]) {
    self.rows = rows
  }

  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int { rows.count }
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
    MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, numberOfCellsInRow row: Int) -> Int {
    rows[row].count
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, idForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellID {
    rows[index.row][index.index].id
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, positionForCellAt index: MIDITimeTableCellIndex) -> Double {
    rows[index.row][index.index].position
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, durationForCellAt index: MIDITimeTableCellIndex) -> Double {
    rows[index.row][index.index].duration
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForHeaderInRow row: Int) -> MIDITimeTableHeaderCellView {
    MIDITimeTableHeaderCellView()
  }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellView {
    let cellData = rows[index.row][index.index]
    let view = midiTimeTableView.dequeueReusableCellView(withIdentifier: "Cell") ?? MIDITimeTableCellView(reuseIdentifier: "Cell")
    didConfigureCell?(view, cellData)
    return view
  }

  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 20 }
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 60 }
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 100 }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double) {}
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double) {}
}

final class MIDITimeTableVirtualizationTests: XCTestCase {

  private func makeLoadedTimeTable(rows: [[TestCell]]) -> (MIDITimeTableView, VirtualizationStubDataSource) {
    let stub = VirtualizationStubDataSource(rows: rows)
    let view = MIDITimeTableView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    view.dataSource = stub
    view.timeTableDelegate = stub
    view.reloadData()
    return (view, stub)
  }

  private func scroll(_ timeTable: MIDITimeTableView, to x: CGFloat) {
    timeTable.contentOffset = CGPoint(x: x, y: 0)
    timeTable.setNeedsLayout()
    timeTable.layoutIfNeeded()
  }

  func testFarCellIsNotRealizedUntilScrolledIntoView() {
    let nearCell = TestCell(position: 0, duration: 1)
    let farCell = TestCell(position: 60, duration: 1)
    let (timeTable, stub) = makeLoadedTimeTable(rows: [[nearCell, farCell]])
    _ = stub

    XCTAssertNotNil(timeTable.cellView(for: nearCell.id), "the near cell should be realized right after reloadData()")
    XCTAssertNil(timeTable.cellView(for: farCell.id), "the far cell should not be realized while off-screen")
    XCTAssertEqual(timeTable.visibleCells.count, 1, "only the on-screen cell should have a live view")

    scroll(timeTable, to: 2800)

    XCTAssertNotNil(timeTable.cellView(for: farCell.id), "the far cell should realize once scrolled into view")
    XCTAssertNil(timeTable.cellView(for: nearCell.id), "the near cell should free once scrolled far out of view")
  }

  func testFreedViewIsDequeuedAndReconfiguredForANewCellInTheSameRow() {
    var configuredIDs = [MIDITimeTableCellID]()
    let nearCell = TestCell(position: 0, duration: 1)
    let farCell = TestCell(position: 60, duration: 1)
    let (timeTable, stub) = makeLoadedTimeTable(rows: [[nearCell, farCell]])
    stub.didConfigureCell = { _, cell in configuredIDs.append(cell.id) }

    guard let nearView = timeTable.cellView(for: nearCell.id) else {
      return XCTFail("expected the near cell to be realized right after reloadData()")
    }

    scroll(timeTable, to: 2800)

    XCTAssertTrue(timeTable.cellView(for: farCell.id) === nearView, "the dequeued view should be the exact instance freed from the same row")
    XCTAssertTrue(configuredIDs.contains(farCell.id), "viewForCellAt should have configured the reused view's new cell")
  }

  func testSelectedOffscreenCellStaysRealizedAndFreesOnceDeselected() {
    let nearCell = TestCell(position: 0, duration: 1)
    let farCell = TestCell(position: 60, duration: 1)
    let (timeTable, stub) = makeLoadedTimeTable(rows: [[nearCell, farCell]])
    _ = stub

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
    let cells = (0..<500).map { TestCell(position: Double($0) * 4, duration: 1) }
    let (timeTable, stub) = makeLoadedTimeTable(rows: [cells])
    _ = stub

    XCTAssertGreaterThan(timeTable.visibleCells.count, 0)
    XCTAssertLessThan(timeTable.visibleCells.count, cells.count, "only a small on-screen slice should be realized, not all 500 cells")
  }
}
