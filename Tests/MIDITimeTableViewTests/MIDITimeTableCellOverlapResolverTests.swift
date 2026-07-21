//
//  MIDITimeTableCellOverlapResolverTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

final class MIDITimeTableCellOverlapResolverTests: XCTestCase {

  /// Builds a single row with cells at the given (position, duration) pairs.
  private func makeRow(_ cells: [(position: Double, duration: Double)]) -> MIDITimeTableRowLayoutData {
    return MIDITimeTableRowLayoutData(
      cells: cells.map({ MIDITimeTableCellLayoutData(id: MIDITimeTableCellID(), position: $0.position, duration: $0.duration) }))
  }

  func testPartialLeftTrim() {
    // Other cell occupies [4, 8). Edited cell moves to [2, 6), overlapping its start.
    let rowData = [makeRow([(position: 0, duration: 4), (position: 4, duration: 4)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let trim = result.updates[0]
    XCTAssertEqual(trim.id, otherCellID)
    XCTAssertEqual(trim.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(trim.newPosition, 6, accuracy: 0.0001)
    XCTAssertEqual(trim.newDuration, 2, accuracy: 0.0001)
  }

  func testPartialRightTrim() {
    // Other cell occupies [0, 4). Edited cell moves to [2, 6), overlapping its end.
    let rowData = [makeRow([(position: 8, duration: 4), (position: 0, duration: 4)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let trim = result.updates[0]
    XCTAssertEqual(trim.id, otherCellID)
    XCTAssertEqual(trim.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(trim.newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(trim.newDuration, 2, accuracy: 0.0001)
  }

  func testFullyCoveredCellIsRemoved() {
    // Other cell occupies [2, 4). Edited cell moves to [0, 6), fully covering it.
    let rowData = [makeRow([(position: 8, duration: 4), (position: 2, duration: 2)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 6)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.updates.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.removals, [otherCellID])
  }

  func testEditedCellLandingInsideSplitsTheOtherCell() {
    // Other cell occupies [0, 10). Edited cell moves to [3, 5), landing strictly inside it.
    let rowData = [makeRow([(position: 20, duration: 4), (position: 0, duration: 10)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 3, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    let leftPiece = result.updates[0]
    // The left piece keeps the original cell's identity — it's the same cell, just trimmed.
    XCTAssertEqual(leftPiece.id, otherCellID)
    XCTAssertEqual(leftPiece.index, MIDITimeTableCellIndex(row: 0, index: 1))
    XCTAssertEqual(leftPiece.newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(leftPiece.newDuration, 3, accuracy: 0.0001)

    XCTAssertEqual(result.insertions.count, 1)
    let rightPiece = result.insertions[0]
    XCTAssertEqual(rightPiece.row, 0)
    // The right piece is a brand new cell: a fresh id, distinct from the original.
    XCTAssertNotEqual(rightPiece.id, otherCellID)
    XCTAssertEqual(rightPiece.sourceID, otherCellID)
    XCTAssertEqual(rightPiece.position, 5, accuracy: 0.0001)
    XCTAssertEqual(rightPiece.duration, 5, accuracy: 0.0001)
  }

  func testNoOverlapProducesNoChanges() {
    // Other cell occupies [10, 12). Edited cell moves to [0, 2) — no overlap.
    let rowData = [makeRow([(position: 0, duration: 2), (position: 10, duration: 2)])]
    let editedCellID = rowData[0, 0].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.updates.isEmpty)
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }

  func testEditedCellOverlapTrimsLaterSelectedCell() {
    let firstID = MIDITimeTableCellID()
    let secondID = MIDITimeTableCellID()
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 6),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 4, newDuration: 6)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolveOverlapsAmongEditedCells(edited)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertEqual(result.updates.count, 2)
    guard let trimmed = result.updates.first(where: { $0.id == secondID }) else {
      return XCTFail("expected the later selected cell to be trimmed")
    }
    XCTAssertEqual(trimmed.newPosition, 6, accuracy: 0.0001)
    XCTAssertEqual(trimmed.newDuration, 4, accuracy: 0.0001)
  }

  func testEditedCellOverlapRemovesFullyCoveredSelectedCell() {
    let firstID = MIDITimeTableCellID()
    let secondID = MIDITimeTableCellID()
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 8),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 2, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolveOverlapsAmongEditedCells(edited)

    XCTAssertEqual(result.removals, [secondID])
    XCTAssertFalse(result.updates.contains(where: { $0.id == secondID }))
  }

  func testSecondEditReTrimsTheSplitRemainderOfTheFirst() {
    // A wide "other" cell occupies [0, 10). The first edited cell lands at [3, 4) strictly inside
    // it, splitting off a right remainder [4, 10). The second edited cell lands at [5, 8) — inside
    // that fresh remainder. Before the batch re-check, the remainder was emitted untouched and
    // overlapped the second edit; now it must be trimmed/split against it too.
    let rowData = [makeRow([(position: 0, duration: 10), (position: 100, duration: 1), (position: 101, duration: 1)])]
    let otherID = rowData[0, 0].id
    let firstID = rowData[0, 1].id
    let secondID = rowData[0, 2].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 3, newDuration: 1),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 2), newRowIndex: 0, newPosition: 5, newDuration: 3)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    // The original cell is trimmed down to its left piece [0, 3).
    XCTAssertEqual(result.updates.count, 1)
    XCTAssertEqual(result.updates[0].id, otherID)
    XCTAssertEqual(result.updates[0].newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(result.updates[0].newDuration, 3, accuracy: 0.0001)

    // The remainder became two fragments: [4, 5) between the two edits, and [8, 10) after the
    // second edit — never a single [4, 10) overlapping the second edit.
    let insertions = result.insertions.sorted { $0.position < $1.position }
    XCTAssertEqual(insertions.count, 2)
    XCTAssertTrue(insertions.allSatisfy { $0.sourceID == otherID && $0.row == 0 })
    XCTAssertEqual(insertions[0].position, 4, accuracy: 0.0001)
    XCTAssertEqual(insertions[0].duration, 1, accuracy: 0.0001)
    XCTAssertEqual(insertions[1].position, 8, accuracy: 0.0001)
    XCTAssertEqual(insertions[1].duration, 2, accuracy: 0.0001)

    // Nothing the resolver emits overlaps either edited region [3, 4) or [5, 8).
    let editedSpans = [(3.0, 4.0), (5.0, 8.0)]
    let emittedSpans = result.updates.map { ($0.newPosition, $0.newPosition + $0.newDuration) }
      + insertions.map { ($0.position, $0.position + $0.duration) }
    for (start, end) in emittedSpans {
      for (editedStart, editedEnd) in editedSpans {
        XCTAssertFalse(start < editedEnd && end > editedStart, "emitted span [\(start), \(end)) overlaps edited [\(editedStart), \(editedEnd))")
      }
    }
  }
}
