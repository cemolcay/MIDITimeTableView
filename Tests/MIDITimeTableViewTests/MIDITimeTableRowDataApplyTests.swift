//
//  MIDITimeTableRowDataApplyTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

final class MIDITimeTableRowDataApplyTests: XCTestCase {

  private func makeRow(_ cells: [(position: Double, duration: Double)]) -> MIDITimeTableRowData {
    return MIDITimeTableRowData(
      cells: cells.map({ MIDITimeTableCellData(data: 0, position: $0.position, duration: $0.duration) }))
  }

  func testApplyUpdatesCellInPlaceWithinSameRow() {
    var rows = [makeRow([(position: 0, duration: 4), (position: 10, duration: 2)])]
    let cellID = rows[0, 0].id
    let result = MIDITimeTableCellEditResult(
      updates: [(id: cellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)])

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 2)
    XCTAssertEqual(rows[0].cells[0].position, 2)
    XCTAssertEqual(rows[0].cells[0].duration, 4)
    // The other cell in the row should be untouched.
    XCTAssertEqual(rows[0].cells[1].position, 10)
  }

  func testApplyMovesCellToAnotherRow() {
    var rows = [makeRow([(position: 0, duration: 4)]), makeRow([])]
    let cellID = rows[0, 0].id
    let result = MIDITimeTableCellEditResult(
      updates: [(id: cellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 1, newPosition: 6, newDuration: 4)])

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 0)
    XCTAssertEqual(rows[1].cells.count, 1)
    XCTAssertEqual(rows[1].cells[0].position, 6)
    XCTAssertEqual(rows[1].cells[0].duration, 4)
    // Identity survives the cross-row move.
    XCTAssertEqual(rows[1].cells[0].id, cellID)
  }

  func testApplyRemovesFullyCoveredCells() {
    var rows = [makeRow([(position: 0, duration: 4), (position: 4, duration: 2)])]
    let removedID = rows[0, 1].id
    let result = MIDITimeTableCellEditResult(removals: [removedID])

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 1)
    XCTAssertEqual(rows[0].cells[0].position, 0)
  }

  func testApplyInsertsSplitRemainder() {
    var rows = [makeRow([(position: 0, duration: 4)])]
    let result = MIDITimeTableCellEditResult(insertions: [(row: 0, cell: MIDITimeTableCellData(data: 0, position: 8, duration: 2))])

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 2)
    XCTAssertTrue(rows[0].cells.contains(where: { $0.position == 8 && $0.duration == 2 }))
  }

  func testApplyIgnoresUpdateForUnknownID() {
    // An update whose id no longer exists in the array (e.g. already removed by another change
    // in the same batch) should be skipped rather than crashing or inserting anything.
    var rows = [makeRow([(position: 0, duration: 4)])]
    let result = MIDITimeTableCellEditResult(
      updates: [(id: MIDITimeTableCellID(), index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)])

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 1)
    XCTAssertEqual(rows[0].cells[0].position, 0)
  }

  func testResolveThenApplyEndToEndTrimsOverlappedCell() {
    // Two adjacent cells: A occupies [0, 4), B occupies [4, 8).
    var rows = [makeRow([(position: 0, duration: 4), (position: 4, duration: 4)])]
    let cellAID = rows[0, 0].id

    // Move A onto B's territory: A's new geometry is [2, 6).
    let edited: [MIDITimeTableViewEditedCellData] = [
      (id: cellAID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    // This mirrors MIDITimeTableView.didEditCells: fold the edited cells' own new geometry into
    // the resolver's result before applying, so a single `apply(_:)` captures everything.
    var result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rows)
    result.updates = edited + result.updates

    rows.apply(result)

    XCTAssertEqual(rows[0].cells.count, 2)
    XCTAssertTrue(rows[0].cells.contains(where: { $0.position == 2 && $0.duration == 4 }), "moved cell A should land at [2, 6)")
    XCTAssertTrue(rows[0].cells.contains(where: { $0.position == 6 && $0.duration == 2 }), "cell B should be trimmed to [6, 8)")
  }
}
