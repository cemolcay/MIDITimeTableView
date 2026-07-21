//
//  MIDITimeTableCellOverlapResolverTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

final class MIDITimeTableCellOverlapResolverTests: XCTestCase {

  /// Builds a single row with cells at the given (position, duration) pairs.
  private func makeRow(_ cells: [(position: Double, duration: Double)]) -> MIDITimeTableRowData {
    return MIDITimeTableRowData(
      cells: cells.map({ MIDITimeTableCellData(data: 0, position: $0.position, duration: $0.duration) }),
      headerCellView: MIDITimeTableHeaderCellView(),
      cellView: { _ in MIDITimeTableCellView() })
  }

  func testPartialLeftTrim() {
    // Other cell occupies [4, 8). Edited cell moves to [2, 6), overlapping its start.
    let rowData = [makeRow([(position: 0, duration: 4), (position: 4, duration: 4)])]
    let edited: [MIDITimeTableViewEditedCellData] = [
      (index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let trim = result.updates[0]
    XCTAssertEqual(trim.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(trim.newPosition, 6, accuracy: 0.0001)
    XCTAssertEqual(trim.newDuration, 2, accuracy: 0.0001)
  }

  func testPartialRightTrim() {
    // Other cell occupies [0, 4). Edited cell moves to [2, 6), overlapping its end.
    let rowData = [makeRow([(position: 8, duration: 4), (position: 0, duration: 4)])]
    let edited: [MIDITimeTableViewEditedCellData] = [
      (index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let trim = result.updates[0]
    XCTAssertEqual(trim.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(trim.newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(trim.newDuration, 2, accuracy: 0.0001)
  }

  func testFullyCoveredCellIsRemoved() {
    // Other cell occupies [2, 4). Edited cell moves to [0, 6), fully covering it.
    let rowData = [makeRow([(position: 8, duration: 4), (position: 2, duration: 2)])]
    let edited: [MIDITimeTableViewEditedCellData] = [
      (index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 6)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.updates.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.removals, [MIDITimeTableCellIndex(row: 0, index: 1)])
  }

  func testEditedCellLandingInsideSplitsTheOtherCell() {
    // Other cell occupies [0, 10). Edited cell moves to [3, 5), landing strictly inside it.
    let rowData = [makeRow([(position: 20, duration: 4), (position: 0, duration: 10)])]
    let edited: [MIDITimeTableViewEditedCellData] = [
      (index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 3, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let leftPiece = result.updates[0]
    XCTAssertEqual(leftPiece.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(leftPiece.newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(leftPiece.newDuration, 3, accuracy: 0.0001)

    XCTAssertEqual(result.insertions.count, 1)
    let rightPiece = result.insertions[0]
    XCTAssertEqual(rightPiece.row, 0)
    XCTAssertEqual(rightPiece.cell.position, 5, accuracy: 0.0001)
    XCTAssertEqual(rightPiece.cell.duration, 5, accuracy: 0.0001)
  }

  func testNoOverlapProducesNoChanges() {
    // Other cell occupies [10, 12). Edited cell moves to [0, 2) — no overlap.
    let rowData = [makeRow([(position: 0, duration: 2), (position: 10, duration: 2)])]
    let edited: [MIDITimeTableViewEditedCellData] = [
      (index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.updates.isEmpty)
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }
}
