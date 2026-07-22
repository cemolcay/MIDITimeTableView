//
//  MIDITimeTableApplyEditResultTests.swift
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

private final class StubDataSource: MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
  var rows: [[TestCell]]
  var changeResults = [MIDITimeTableCellEditResult]()
  var selectedIndices = [MIDITimeTableCellIndex]()
  var unselectAllCallCount = 0

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
    MIDITimeTableCellView()
  }

  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didChange result: MIDITimeTableCellEditResult) {
    changeResults.append(result)
  }
  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 20 }
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 60 }
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat { 100 }
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double) {}
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double) {}
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didSelectCellAt index: MIDITimeTableCellIndex) {
    selectedIndices.append(index)
  }
  func midiTimeTableViewDidUnselectAllCells(_ midiTimeTableView: MIDITimeTableView) {
    unselectAllCallCount += 1
  }
}

final class MIDITimeTableApplyEditResultTests: XCTestCase {

  private func makeRow(_ cells: [(position: Double, duration: Double)]) -> [TestCell] {
    return cells.map({ TestCell(position: $0.position, duration: $0.duration) })
  }

  private func makeLoadedTimeTable(_ rows: [[TestCell]]) -> (MIDITimeTableView, StubDataSource) {
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
    _ = stub
    let untouchedID = row[1].id
    let untouchedView = timeTable.cellView(for: untouchedID)
    XCTAssertNotNil(untouchedView)
    let movedID = row[0].id

    let result = MIDITimeTableCellEditResult(
      updates: [MIDITimeTableViewEditedCellData(id: movedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)])
    timeTable.applyEditResult(result)

    XCTAssertTrue(timeTable.cellView(for: untouchedID) === untouchedView)
  }

  func testApplyEditResultMovesViewToNewRowKeepingIdentity() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row, makeRow([])])
    _ = stub
    let id = row[0].id
    guard let cellView = timeTable.cellView(for: id) else {
      return XCTFail("expected the cell to be realized right after reloadData()")
    }

    let result = MIDITimeTableCellEditResult(
      updates: [MIDITimeTableViewEditedCellData(id: id, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 1, newPosition: 6, newDuration: 4)])
    timeTable.applyEditResult(result)

    XCTAssertTrue(timeTable.cellView(for: id) === cellView)
    XCTAssertEqual(timeTable.cellIndex(of: cellView)?.row, 1)
  }

  func testApplyEditResultRemovesCoveredCellView() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub
    let removedID = row[1].id
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

    let newCellID = MIDITimeTableCellID()
    timeTable.applyEditResult(
      MIDITimeTableCellEditResult(
        insertions: [MIDITimeTableCellInsertion(row: 0, sourceID: row[0].id, id: newCellID, position: 8, duration: 2)]))

    XCTAssertNotNil(timeTable.cellView(for: newCellID))
  }

  func testRemoveCellsAtIndicesRemovesIncrementally() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub
    let keptID = row[0].id
    let keptView = timeTable.cellView(for: keptID)
    XCTAssertNotNil(keptView)

    timeTable.removeCells(at: [MIDITimeTableCellIndex(row: 0, index: 1)])

    XCTAssertTrue(timeTable.cellView(for: keptID) === keptView)
    XCTAssertEqual(stub.changeResults.last?.removals, [row[1].id])
  }

  func testRemoveCellsAtInvalidIndicesDoesNotPublishChange() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])

    timeTable.removeCells(at: [MIDITimeTableCellIndex(row: 0, index: 99)])

    XCTAssertTrue(stub.changeResults.isEmpty)
  }

  func testEffectiveChangeResultDropsNoOpUpdate() {
    let row = makeRow([(position: 2, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    _ = stub

    let result = timeTable.effectiveChangeResult(
      from: MIDITimeTableCellEditResult(
        updates: [
          MIDITimeTableViewEditedCellData(
            id: row[0].id,
            index: MIDITimeTableCellIndex(row: 0, index: 0),
            newRowIndex: 0,
            newPosition: 2,
            newDuration: 4)
        ]))

    XCTAssertTrue(result.updates.isEmpty)
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }

  func testTappingACellReportsItsSelectionAndReplacesAnyPriorSelection() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    guard let firstCellView = timeTable.cellView(for: row[0].id),
          let secondCellView = timeTable.cellView(for: row[1].id) else {
      return XCTFail("expected both cells to be realized right after reloadData()")
    }

    timeTable.midiTimeTableCellViewDidTap(firstCellView)
    XCTAssertEqual(stub.selectedIndices, [MIDITimeTableCellIndex(row: 0, index: 0)])
    XCTAssertTrue(firstCellView.isSelected)

    timeTable.midiTimeTableCellViewDidTap(secondCellView)
    XCTAssertEqual(stub.selectedIndices, [MIDITimeTableCellIndex(row: 0, index: 0), MIDITimeTableCellIndex(row: 0, index: 1)])
    XCTAssertFalse(firstCellView.isSelected, "selecting another cell should deselect the previous one")
    XCTAssertTrue(secondCellView.isSelected)
  }

  func testTappingAnAlreadySelectedCellUnselectsIt() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    guard let cellView = timeTable.cellView(for: row[0].id) else {
      return XCTFail("expected the cell to be realized right after reloadData()")
    }

    timeTable.midiTimeTableCellViewDidTap(cellView)
    XCTAssertTrue(cellView.isSelected)

    timeTable.midiTimeTableCellViewDidTap(cellView)
    XCTAssertFalse(cellView.isSelected, "tapping an already-selected cell should toggle it off")
    XCTAssertEqual(stub.unselectAllCallCount, 1)
    XCTAssertEqual(stub.selectedIndices, [MIDITimeTableCellIndex(row: 0, index: 0)], "should not report a second selection for the toggle-off tap")
  }

  func testSelectCellAtIndexRealizesOffscreenCellAndReportsSelection() {
    let farCell = TestCell(position: 2000, duration: 4)
    let row = makeRow([(position: 0, duration: 4)]) + [farCell]
    let (timeTable, stub) = makeLoadedTimeTable([row])
    XCTAssertNil(timeTable.cellView(for: farCell.id), "far cell should not be realized before scrolling or selecting")

    let selected = timeTable.selectCell(at: MIDITimeTableCellIndex(row: 0, index: 1))

    XCTAssertTrue(selected)
    XCTAssertEqual(stub.selectedIndices, [MIDITimeTableCellIndex(row: 0, index: 1)])
    let realizedView = timeTable.cellView(for: farCell.id)
    XCTAssertNotNil(realizedView, "selecting an offscreen cell should realize and pin its view")
    XCTAssertTrue(realizedView?.isSelected == true)
  }

  func testSelectCellAtIndexDeselectsThePreviouslySelectedCell() {
    let row = makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])
    let (timeTable, _) = makeLoadedTimeTable([row])
    guard let firstView = timeTable.cellView(for: row[0].id) else {
      return XCTFail("expected the cell to be realized right after reloadData()")
    }

    XCTAssertTrue(timeTable.selectCell(at: MIDITimeTableCellIndex(row: 0, index: 0)))
    XCTAssertTrue(firstView.isSelected)

    XCTAssertTrue(timeTable.selectCell(at: MIDITimeTableCellIndex(row: 0, index: 1)))
    XCTAssertFalse(firstView.isSelected)
  }

  func testSelectCellAtOutOfBoundsIndexReturnsFalse() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])

    XCTAssertFalse(timeTable.selectCell(at: MIDITimeTableCellIndex(row: 0, index: 99)))
    XCTAssertTrue(stub.selectedIndices.isEmpty)
  }

  func testUnselectAllCellsReportsOnlyWhenThereWasASelection() {
    let row = makeRow([(position: 0, duration: 4)])
    let (timeTable, stub) = makeLoadedTimeTable([row])
    guard let cellView = timeTable.cellView(for: row[0].id) else {
      return XCTFail("expected the cell to be realized right after reloadData()")
    }

    timeTable.unselectAllCells()
    XCTAssertEqual(stub.unselectAllCallCount, 0, "nothing was selected, so no notification should fire")

    timeTable.midiTimeTableCellViewDidTap(cellView)
    timeTable.unselectAllCells()
    XCTAssertEqual(stub.unselectAllCallCount, 1)
    XCTAssertFalse(cellView.isSelected)
  }
}
