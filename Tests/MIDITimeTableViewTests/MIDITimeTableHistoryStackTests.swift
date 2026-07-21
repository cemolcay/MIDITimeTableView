//
//  MIDITimeTableHistoryStackTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

private struct TestHistory: MIDITimeTableHistoryRepresentable {
  var history = MIDITimeTableHistoryStack<[Int]>(limit: 3)
}

private struct TestRepresentableCell: MIDITimeTableCellRepresentable {
  let id: MIDITimeTableCellID
  var position: Double
  var duration: Double
}

private struct TestRepresentableRow: MIDITimeTableRowRepresentable {
  var cells: [TestRepresentableCell]
}

final class MIDITimeTableHistoryStackTests: XCTestCase {

  func testAppendTracksCurrentItemAndUndoRedoAvailability() {
    var history = MIDITimeTableHistoryStack<Int>()

    XCTAssertNil(history.currentItem)
    XCTAssertFalse(history.hasPreviousItem)
    XCTAssertFalse(history.hasNextItem)

    history.append(1)
    history.append(2)

    XCTAssertEqual(history.currentItem, 2)
    XCTAssertTrue(history.hasPreviousItem)
    XCTAssertFalse(history.hasNextItem)
  }

  func testUndoRedoMovesThroughSnapshots() {
    var history = MIDITimeTableHistoryStack<String>()
    history.append("initial")
    history.append("edited")

    XCTAssertEqual(history.undo(), "initial")
    XCTAssertEqual(history.currentItem, "initial")
    XCTAssertFalse(history.hasPreviousItem)
    XCTAssertTrue(history.hasNextItem)

    XCTAssertEqual(history.redo(), "edited")
    XCTAssertEqual(history.currentItem, "edited")
    XCTAssertTrue(history.hasPreviousItem)
    XCTAssertFalse(history.hasNextItem)
  }

  func testAppendingAfterUndoDropsRedoBranch() {
    var history = MIDITimeTableHistoryStack<Int>()
    history.append(1)
    history.append(2)
    history.append(3)

    XCTAssertEqual(history.undo(), 2)
    history.append(4)

    XCTAssertEqual(history.currentItem, 4)
    XCTAssertEqual(history.items, [1, 2, 4])
    XCTAssertFalse(history.hasNextItem)
  }

  func testLimitKeepsMostRecentSnapshots() {
    var history = MIDITimeTableHistoryStack<Int>(limit: 2)
    history.append(1)
    history.append(2)
    history.append(3)

    XCTAssertEqual(history.items, [2, 3])
    XCTAssertEqual(history.currentIndex, 1)
    XCTAssertEqual(history.currentItem, 3)
  }

  func testHistoryRepresentableExtensionDelegatesToStorage() {
    var history = TestHistory()
    history.append([1])
    history.append([1, 2])

    XCTAssertTrue(history.hasPreviousHistoryItem)
    XCTAssertFalse(history.hasNextHistoryItem)
    XCTAssertEqual(history.currentHistoryItem, [1, 2])

    XCTAssertEqual(history.undo(), [1])
    XCTAssertFalse(history.hasPreviousHistoryItem)
    XCTAssertTrue(history.hasNextHistoryItem)
  }

  func testRepresentableRowHelpersExposeCellData() {
    let id = MIDITimeTableCellID()
    let row = TestRepresentableRow(cells: [
      TestRepresentableCell(id: id, position: 2, duration: 4)
    ])

    XCTAssertEqual(row.cellCount, 1)
    XCTAssertEqual(row.cell(at: 0).id, id)
    XCTAssertEqual(row.cellID(at: 0), id)
    XCTAssertEqual(row.cellPosition(at: 0), 2)
    XCTAssertEqual(row.cellDuration(at: 0), 4)
  }

  func testRepresentableRowArrayHelpersExposeDataSourceValues() {
    let firstID = MIDITimeTableCellID()
    let secondID = MIDITimeTableCellID()
    let rows = [
      TestRepresentableRow(cells: [
        TestRepresentableCell(id: firstID, position: 0, duration: 1)
      ]),
      TestRepresentableRow(cells: [
        TestRepresentableCell(id: secondID, position: 4, duration: 2)
      ])
    ]
    let secondIndex = MIDITimeTableCellIndex(row: 1, index: 0)

    XCTAssertEqual(rows.rowCount, 2)
    XCTAssertEqual(rows.cellCount(inRow: 0), 1)
    XCTAssertEqual(rows.cellID(at: secondIndex), secondID)
    XCTAssertEqual(rows.cellPosition(at: secondIndex), 4)
    XCTAssertEqual(rows.cellDuration(at: secondIndex), 2)
    XCTAssertEqual(rows.index(ofCellID: secondID), secondIndex)
    XCTAssertNil(rows.index(ofCellID: MIDITimeTableCellID()))
  }
}
