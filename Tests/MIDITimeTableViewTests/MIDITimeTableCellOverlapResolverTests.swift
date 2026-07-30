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

  private func makePublicCells(_ cells: [(position: Double, duration: Double)], row: Int = 0) -> [MIDITimeTableViewEditedCellData] {
    return cells.enumerated().map { offset, cell in
      MIDITimeTableViewEditedCellData(
        id: MIDITimeTableCellID(),
        index: MIDITimeTableCellIndex(row: row, index: offset),
        newRowIndex: row,
        newPosition: cell.position,
        newDuration: cell.duration)
    }
  }

  private func resolveByShifting(
    editedCells: [MIDITimeTableViewEditedCellData],
    in rowData: [MIDITimeTableRowLayoutData],
    tolerance: Double = 0.000001
  ) -> MIDITimeTableCellEditResult {
    return MIDITimeTableCellOverlapResolver.resolve(
      editedCells: editedCells, in: rowData,
      using: MIDITimeTableCellOverlapResolver.Options(mode: .shiftLaterCells, tolerance: tolerance, minimumPosition: nil))
  }

  private func resolveByTrimming(
    editedCells: [MIDITimeTableViewEditedCellData],
    in rowData: [MIDITimeTableRowLayoutData],
    minimumDuration: Double = 0.000000001
  ) -> MIDITimeTableCellEditResult {
    return MIDITimeTableCellOverlapResolver.resolve(
      editedCells: editedCells, in: rowData,
      using: MIDITimeTableCellOverlapResolver.Options(mode: .trimEarlierCells, minimumDuration: minimumDuration, minimumPosition: nil))
  }

  // MARK: - Public batch API: resolveOverlaps(in:using:priorityCellIDs:)

  func testPublicResolveOverlapsTrimsEarlierCells() {
    let cells = makePublicCells([
      (position: 0, duration: 2),
      (position: 1.5, duration: 1),
      (position: 2, duration: 1)
    ])

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(
      in: cells,
      mode: .trimEarlierCells,
      minimumDuration: 0.03)

    XCTAssertEqual(resolved.updates.count, 3)
    XCTAssertEqual(resolved.updates.map(\.newPosition), [0, 1.5, 2])
    XCTAssertEqual(resolved.updates.map(\.newDuration), [1.5, 0.5, 1])
    XCTAssertTrue(resolved.removals.isEmpty)
    XCTAssertTrue(resolved.insertions.isEmpty)
  }

  func testPublicResolveOverlapsShiftsLaterCells() {
    let cells = makePublicCells([
      (position: 0, duration: 1),
      (position: 1, duration: 1),
      (position: 1, duration: 1),
      (position: 2, duration: 1)
    ])

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(in: cells, mode: .shiftLaterCells)

    XCTAssertEqual(resolved.updates.count, 4)
    XCTAssertEqual(resolved.updates.map(\.newPosition), [0, 1, 2, 3])
    XCTAssertEqual(resolved.updates.map(\.newDuration), [1, 1, 1, 1])
    XCTAssertTrue(resolved.removals.isEmpty)
    XCTAssertTrue(resolved.insertions.isEmpty)
  }

  func testPublicResolveOverlapsShiftsLaterRestsWithMovedCells() {
    let cells = makePublicCells([
      (position: 0, duration: 2),
      (position: 1, duration: 1),
      (position: 4, duration: 1)
    ])

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(in: cells, mode: .shiftLaterCells)

    XCTAssertEqual(resolved.updates.count, 3)
    XCTAssertEqual(resolved.updates.map(\.newPosition), [0, 2, 5])
    XCTAssertEqual(resolved.updates.map(\.newDuration), [2, 1, 1])
  }

  func testPublicResolveOverlapsDoesNotShiftAdjacentCells() {
    let cells = makePublicCells([
      (position: 0, duration: 1),
      (position: 1.0000000001, duration: 1),
      (position: 2, duration: 1)
    ])

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(in: cells, mode: .shiftLaterCells)

    XCTAssertEqual(resolved.updates.count, 3)
    XCTAssertEqual(resolved.updates.map(\.newPosition), [0, 1.0000000001, 2])
    XCTAssertEqual(resolved.updates.map(\.newDuration), [1, 1, 1])
  }

  func testPublicResolveOverlapsAcceptsUnsortedInput() {
    // Same fixture as testPublicResolveOverlapsTrimsEarlierCells, but supplied out of order.
    let inOrder = makePublicCells([
      (position: 0, duration: 2),
      (position: 1.5, duration: 1),
      (position: 2, duration: 1)
    ])
    let shuffled = [inOrder[2], inOrder[0], inOrder[1]]

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(in: shuffled, mode: .trimEarlierCells, minimumDuration: 0.03)
    let byPosition = resolved.updates.sorted { $0.newPosition < $1.newPosition }

    XCTAssertEqual(byPosition.map(\.newPosition), [0, 1.5, 2])
    XCTAssertEqual(byPosition.map(\.newDuration), [1.5, 0.5, 1])
  }

  func testPublicResolveOverlapsPriorityCellWinsInTrimMode() {
    // A wide cell [0, 10) already occupies the row; a newly inserted cell at [4, 5) should win
    // and carve a hole out of it, exactly like an interactive edit would.
    let host = makePublicCells([(position: 0, duration: 10)])[0]
    let inserted = makePublicCells([(position: 4, duration: 1)], row: 0)[0]

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(
      in: [host, inserted],
      using: MIDITimeTableCellOverlapResolver.Options(mode: .trimEarlierCells),
      priorityCellIDs: [inserted.id])

    XCTAssertTrue(resolved.removals.isEmpty)
    let insertedUpdate = resolved.updates.first { $0.id == inserted.id }
    XCTAssertEqual(insertedUpdate?.newPosition, 4)
    XCTAssertEqual(insertedUpdate?.newDuration, 1)
    let hostUpdate = resolved.updates.first { $0.id == host.id }
    XCTAssertEqual(hostUpdate?.newPosition, 0)
    XCTAssertEqual(hostUpdate?.newDuration, 4)
    XCTAssertEqual(resolved.insertions.count, 1)
    XCTAssertEqual(resolved.insertions[0].position, 5)
    XCTAssertEqual(resolved.insertions[0].duration, 5)
    XCTAssertEqual(resolved.insertions[0].sourceID, host.id)
  }

  func testPublicResolveOverlapsPriorityCellStaysPutInShiftMode() {
    // `overlapping` collides with the priority cell and must be pushed clear of it;
    // `untouched`, positioned well before either, must be left exactly where it was.
    let untouched = makePublicCells([(position: 0, duration: 1)])[0]
    let overlapping = makePublicCells([(position: 5, duration: 3)])[0]
    let inserted = makePublicCells([(position: 6, duration: 1)])[0]

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(
      in: [untouched, overlapping, inserted],
      using: MIDITimeTableCellOverlapResolver.Options(mode: .shiftLaterCells),
      priorityCellIDs: [inserted.id])

    let insertedUpdate = resolved.updates.first { $0.id == inserted.id }
    XCTAssertEqual(insertedUpdate?.newPosition, 6, "the priority cell must never move")
    let overlappingUpdate = resolved.updates.first { $0.id == overlapping.id }
    XCTAssertEqual(overlappingUpdate?.newPosition, 7, "pushed clear of the priority cell's end")
    let untouchedUpdate = resolved.updates.first { $0.id == untouched.id }
    XCTAssertEqual(untouchedUpdate?.newPosition, 0, "far from the priority cell, must be left exactly as given")
  }

  func testPublicResolveOverlapsEqualPositionTieKeepsLongerCell() {
    let cells = makePublicCells([(position: 0, duration: 4), (position: 0, duration: 1)])
    let longID = cells[0].id
    let shortID = cells[1].id

    let resolved = MIDITimeTableCellOverlapResolver.resolveOverlaps(in: cells, mode: .trimEarlierCells)

    XCTAssertEqual(resolved.removals, [shortID])
    XCTAssertEqual(resolved.updates.count, 1)
    XCTAssertEqual(resolved.updates[0].id, longID)
    XCTAssertEqual(resolved.updates[0].newDuration, 4)
  }

  // MARK: - Interactive shift funnel: resolve(editedCells:in:using: .shiftLaterCells)

  func testResolveByShiftingLaterCellsDoesNotTrimOverlappedCell() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 1, duration: 1)])]
    let editedID = rowData[0, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: editedID,
        index: MIDITimeTableCellIndex(row: 0, index: 0),
        newRowIndex: 0,
        newPosition: 0,
        newDuration: 2)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [0, 2])
    XCTAssertEqual(result.updates.map(\.newDuration), [2, 1])
  }

  func testResolveByShiftingLaterCellsPreservesRestAfterResize() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 2, duration: 1)])]
    let editedID = rowData[0, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: editedID,
        index: MIDITimeTableCellIndex(row: 0, index: 0),
        newRowIndex: 0,
        newPosition: 0,
        newDuration: 2)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [0, 3])
    XCTAssertEqual(result.updates.map(\.newDuration), [2, 1])
  }

  func testResolveByShiftingLaterCellsTreatsMultipleEditedCellsAsSingleBlock() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 1, duration: 1), (position: 2, duration: 1)])]
    let firstID = rowData[0, 0].id
    let secondID = rowData[0, 1].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: firstID,
        index: MIDITimeTableCellIndex(row: 0, index: 0),
        newRowIndex: 0,
        newPosition: 0,
        newDuration: 1),
      MIDITimeTableViewEditedCellData(
        id: secondID,
        index: MIDITimeTableCellIndex(row: 0, index: 1),
        newRowIndex: 0,
        newPosition: 1,
        newDuration: 2)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [0, 1, 3])
    XCTAssertEqual(result.updates.map(\.newDuration), [1, 2, 1])
  }

  func testResolveByShiftingLaterCellsMovesOverlappedAndFollowingCellsOnly() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 1, duration: 1), (position: 2, duration: 1)])]
    let firstID = rowData[0, 0].id
    let secondID = rowData[0, 1].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: firstID,
        index: MIDITimeTableCellIndex(row: 0, index: 0),
        newRowIndex: 0,
        newPosition: 1,
        newDuration: 1),
      MIDITimeTableViewEditedCellData(
        id: secondID,
        index: MIDITimeTableCellIndex(row: 0, index: 1),
        newRowIndex: 0,
        newPosition: 2,
        newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [1, 2, 3])
    XCTAssertEqual(result.updates.map(\.newDuration), [1, 1, 1])
  }

  func testResolveByShiftingLaterCellsDoesNotShiftCellsLeftBehindBlock() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 2, duration: 1), (position: 3, duration: 1), (position: 5, duration: 1)])]
    let firstID = rowData[0, 1].id
    let secondID = rowData[0, 2].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: firstID,
        index: MIDITimeTableCellIndex(row: 0, index: 1),
        newRowIndex: 0,
        newPosition: 1,
        newDuration: 1),
      MIDITimeTableViewEditedCellData(
        id: secondID,
        index: MIDITimeTableCellIndex(row: 0, index: 2),
        newRowIndex: 0,
        newPosition: 2,
        newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [1, 2])
    XCTAssertEqual(result.updates.map(\.newDuration), [1, 1])
  }

  func testResolveByShiftingLaterCellsMovesCellOverlappedInMiddleAndCarriesShiftForward() {
    // A[0,4) straddles the drop point of the edited cell and must be pushed clear of it; once
    // A absorbs that displacement, the accumulated shift carries forward to C even though C's
    // own original position never collided with anything directly (decision: "accumulate, never
    // move left" — a rest after a pushed cell keeps its width instead of collapsing).
    let rowData = [makeRow([(position: 0, duration: 4), (position: 5, duration: 1), (position: 6, duration: 1)])]
    let editedID = rowData[0, 1].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: editedID,
        index: MIDITimeTableCellIndex(row: 0, index: 1),
        newRowIndex: 0,
        newPosition: 2,
        newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.map(\.newPosition), [2, 3, 9])
    XCTAssertEqual(result.updates.map(\.newDuration), [1, 4, 1])
  }

  func testResolveByShiftingLaterCellsDoesNotPushAdjacentCell() {
    let rowData = [makeRow([(position: 0, duration: 1), (position: 3, duration: 1), (position: 4, duration: 1)])]
    let editedID = rowData[0, 1].id
    let edited = [
      MIDITimeTableViewEditedCellData(
        id: editedID,
        index: MIDITimeTableCellIndex(row: 0, index: 1),
        newRowIndex: 0,
        newPosition: 3.0000000001,
        newDuration: 0.9999999999)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    XCTAssertEqual(result.updates.count, 1)
    XCTAssertEqual(result.updates[0].newPosition, 3.0000000001, accuracy: 0.000000001)
    XCTAssertEqual(result.updates[0].newDuration, 0.9999999999, accuracy: 0.000000001)
  }

  func testResolveByShiftingLaterCellsDoesNotSwallowNonSelectedCellBetweenSelectedCells() {
    // Regression for a non-contiguous multi-selection: dragging A and C by +1 must not flush the
    // untouched B sitting between them past C's new position.
    let rowData = [makeRow([(position: 0, duration: 1), (position: 2, duration: 1), (position: 4, duration: 1)])]
    let aID = rowData[0, 0].id
    let bID = rowData[0, 1].id
    let cID = rowData[0, 2].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: aID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 1, newDuration: 1),
      MIDITimeTableViewEditedCellData(id: cID, index: MIDITimeTableCellIndex(row: 0, index: 2), newRowIndex: 0, newPosition: 5, newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    let bUpdate = result.updates.first { $0.id == bID }
    XCTAssertNil(bUpdate, "B never collided with anything and should be left untouched")
  }

  func testResolveByShiftingLaterCellsCrossRowMoveDoesNotUseSourceRowGeometry() {
    // A cell dragged from row 1 into row 0 must not inflate row 0 using its row-1 original span.
    var rowData = [makeRow([(position: 0, duration: 1), (position: 2, duration: 1)]), makeRow([(position: 10, duration: 5)])]
    let movedID = rowData[1, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: movedID, index: MIDITimeTableCellIndex(row: 1, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 5)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    // The arriving cell [0, 5) collides with row 0's first cell like any pinned obstacle would:
    // that cell is pushed clear to position 5, and — decision "accumulate, never move left" —
    // that 5-beat displacement then carries to the second row-0 cell too (2 -> 7), even though it
    // never directly touched the arriving cell. If the bug this guards against were present, the
    // cell's row-1 origin (position 10, duration 5) would leak into this row-0 growth/seeding
    // calculation instead of correctly seeding nothing (this is a cross-row arrival, not a
    // same-row resize) and produce a different, row-1-influenced number here.
    let secondUpdate = result.updates.first { $0.id == rowData[0, 1].id }
    XCTAssertEqual(secondUpdate?.newPosition, 7)
    XCTAssertEqual(secondUpdate?.newDuration, 1)
  }

  func testResolveByShiftingLaterCellsMoveInsertsNoPhantomTime() {
    // A pure move (not a resize) must never seed the growth/insertedDuration rule — only a
    // same-start resize does.
    let rowData = [makeRow([(position: 0, duration: 1), (position: 10, duration: 1)])]
    let movedID = rowData[0, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: movedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 5, newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    let otherUpdate = result.updates.first { $0.id == rowData[0, 1].id }
    XCTAssertNil(otherUpdate, "no collision occurred, and a pure move must not insert time")
  }

  func testResolveByShiftingLaterCellsLeftEdgeResizeInsertsNoPhantomTime() {
    // Growing a cell from its LEFT edge (same end, earlier start) is not the "same start, longer
    // end" growth case and must not push cells after the unchanged original end.
    let rowData = [makeRow([(position: 4, duration: 2), (position: 10, duration: 1)])]
    let resizedID = rowData[0, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: resizedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 6)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    let otherUpdate = result.updates.first { $0.id == rowData[0, 1].id }
    XCTAssertNil(otherUpdate, "left-edge resize does not collide with the far cell and inserts no time")
  }

  func testResolveByShiftingLaterCellsShrinkLeavesGapOpen() {
    // Shrinking (or moving away) never pulls later cells back — decision: shift never closes a
    // gap it didn't create by colliding.
    let rowData = [makeRow([(position: 0, duration: 4), (position: 5, duration: 1)])]
    let resizedID = rowData[0, 0].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: resizedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 1)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    let otherUpdate = result.updates.first { $0.id == rowData[0, 1].id }
    XCTAssertNil(otherUpdate, "shrinking must not pull the later cell backward")
  }

  func testResolveByShiftingLaterCellsSelfOverlapPushesRatherThanDeletes() {
    // A multi-cell resize that makes two SELECTED cells overlap each other must never delete or
    // trim either one in shift mode — it pushes the later-positioned one clear instead.
    let rowData = [makeRow([(position: 0, duration: 1), (position: 5, duration: 1)])]
    let firstID = rowData[0, 0].id
    let secondID = rowData[0, 1].id
    let edited = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 8),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 2, newDuration: 2)
    ]

    let result = resolveByShifting(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    let firstUpdate = result.updates.first { $0.id == firstID }
    let secondUpdate = result.updates.first { $0.id == secondID }
    XCTAssertEqual(firstUpdate?.newPosition, 0)
    XCTAssertEqual(firstUpdate?.newDuration, 8)
    XCTAssertEqual(secondUpdate?.newPosition, 8, "pushed clear of the first cell instead of being deleted")
    XCTAssertEqual(secondUpdate?.newDuration, 2)
  }

  // MARK: - Interactive trim funnel: resolve(editedCells:in:using: .trimEarlierCells)

  func testPartialLeftTrim() {
    // Other cell occupies [4, 8). Edited cell moves to [2, 6), overlapping its start.
    let rowData = [makeRow([(position: 0, duration: 4), (position: 4, duration: 4)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 2, newDuration: 4)
    ]

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    guard let trim = result.updates.first(where: { $0.id == otherCellID }) else {
      return XCTFail("expected the trimmed neighbor in the updates")
    }
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

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
    guard let trim = result.updates.first(where: { $0.id == otherCellID }) else {
      return XCTFail("expected the trimmed neighbor in the updates")
    }
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

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertTrue(result.updates.contains { $0.id == editedCellID })
    XCTAssertFalse(result.updates.contains { $0.id == otherCellID })
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

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    // The left piece keeps the original cell's identity — it's the same cell, just trimmed.
    guard let leftPiece = result.updates.first(where: { $0.id == otherCellID }) else {
      return XCTFail("expected the trimmed left piece in the updates")
    }
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
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 2)
    ]

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertFalse(result.updates.contains { $0.id == otherCellID })
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }

  func testTinyFloatingPointOverhangProducesNoChange() {
    // The edited cell overhangs the neighbor by 1e-12 beats — well inside tolerance — and must
    // not trigger a trim, a split, or a sliver insertion.
    let rowData = [makeRow([(position: 0, duration: 4), (position: 4, duration: 4)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 4.000000000001)
    ]

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertFalse(result.updates.contains { $0.id == otherCellID })
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }

  func testTrimBelowMinimumDurationReportsRemovalInsteadOfSliver() {
    // Other cell occupies [0, 4). Edited cell overlaps all but a 0.0005-beat sliver of it, below
    // the configured minimumDuration floor — the sliver must be removed, not kept.
    let rowData = [makeRow([(position: 10, duration: 4), (position: 0, duration: 4)])]
    let editedCellID = rowData[0, 0].id
    let otherCellID = rowData[0, 1].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedCellID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0.0005, newDuration: 4)
    ]

    let result = resolveByTrimming(editedCells: edited, in: rowData, minimumDuration: 0.01)

    XCTAssertEqual(result.removals, [otherCellID])
    XCTAssertFalse(result.updates.contains { $0.id == otherCellID })
  }

  func testEditedCellOverlapTrimsEarlierSelectedCell() {
    // Two selected cells overlap each other after a resize: the LATER-positioned one wins and
    // keeps its exact geometry (start position preserved); the EARLIER one is truncated at its
    // end instead of having its start pushed forward.
    let firstID = MIDITimeTableCellID()
    let secondID = MIDITimeTableCellID()
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 6),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 4, newDuration: 6)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(
      editedCells: edited, in: [MIDITimeTableRowLayoutData(cells: [])], using: MIDITimeTableCellOverlapResolver.Options(mode: .trimEarlierCells, minimumPosition: nil))

    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertEqual(result.updates.count, 2)
    guard let winner = result.updates.first(where: { $0.id == secondID }) else {
      return XCTFail("expected the later selected cell to survive unchanged")
    }
    XCTAssertEqual(winner.newPosition, 4, accuracy: 0.0001)
    XCTAssertEqual(winner.newDuration, 6, accuracy: 0.0001)
    guard let trimmed = result.updates.first(where: { $0.id == firstID }) else {
      return XCTFail("expected the earlier selected cell to be trimmed")
    }
    XCTAssertEqual(trimmed.newPosition, 0, accuracy: 0.0001, "start position is preserved, not pushed")
    XCTAssertEqual(trimmed.newDuration, 4, accuracy: 0.0001)
  }

  func testEditedCellOverlapRemovesFullyCoveredSelectedCell() {
    // Two selected cells share the exact same start (a resize that left them tied at position 0):
    // the tie-break rule keeps the longer one and removes the shorter, since a later-sorted cell
    // can only ever fully cover an earlier one when they start at the same position.
    let longID = MIDITimeTableCellID()
    let shortID = MIDITimeTableCellID()
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: longID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 8),
      MIDITimeTableViewEditedCellData(id: shortID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 0, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(
      editedCells: edited, in: [MIDITimeTableRowLayoutData(cells: [])], using: MIDITimeTableCellOverlapResolver.Options(mode: .trimEarlierCells, minimumPosition: nil))

    XCTAssertEqual(result.removals, [shortID])
    XCTAssertFalse(result.updates.contains(where: { $0.id == shortID }))
    let survivor = result.updates.first { $0.id == longID }
    XCTAssertEqual(survivor?.newPosition, 0)
    XCTAssertEqual(survivor?.newDuration, 8)
  }

  func testEditedCellOverlapSplitsHostWhenLaterSelectedCellLandsInsideIt() {
    // A later-positioned (and thus higher-priority) selected cell that lands strictly inside an
    // earlier, wider one carves a hole in it — split-everywhere applies within a selection too,
    // not just against untouched host cells.
    let wideID = MIDITimeTableCellID()
    let innerID = MIDITimeTableCellID()
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: wideID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 8),
      MIDITimeTableViewEditedCellData(id: innerID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 2, newDuration: 2)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(
      editedCells: edited, in: [MIDITimeTableRowLayoutData(cells: [])], using: MIDITimeTableCellOverlapResolver.Options(mode: .trimEarlierCells, minimumPosition: nil))

    XCTAssertTrue(result.removals.isEmpty)
    let leftPiece = result.updates.first { $0.id == wideID }
    XCTAssertEqual(leftPiece?.newPosition, 0)
    XCTAssertEqual(leftPiece?.newDuration, 2)
    let inner = result.updates.first { $0.id == innerID }
    XCTAssertEqual(inner?.newPosition, 2)
    XCTAssertEqual(inner?.newDuration, 2)
    XCTAssertEqual(result.insertions.count, 1)
    XCTAssertEqual(result.insertions[0].sourceID, wideID)
    XCTAssertEqual(result.insertions[0].position, 4)
    XCTAssertEqual(result.insertions[0].duration, 4)
  }

  func testSecondEditReTrimsTheSplitRemainderOfTheFirst() {
    // A wide "other" cell occupies [0, 10). The first edited cell lands at [3, 4) strictly inside
    // it, splitting off a right remainder [4, 10). The second edited cell lands at [5, 8) — inside
    // that fresh remainder. The remainder must be trimmed/split against it too, rather than being
    // emitted untouched and left overlapping.
    let rowData = [makeRow([(position: 0, duration: 10), (position: 100, duration: 1), (position: 101, duration: 1)])]
    let otherID = rowData[0, 0].id
    let firstID = rowData[0, 1].id
    let secondID = rowData[0, 2].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: firstID, index: MIDITimeTableCellIndex(row: 0, index: 1), newRowIndex: 0, newPosition: 3, newDuration: 1),
      MIDITimeTableViewEditedCellData(id: secondID, index: MIDITimeTableCellIndex(row: 0, index: 2), newRowIndex: 0, newPosition: 5, newDuration: 3)
    ]

    let result = resolveByTrimming(editedCells: edited, in: rowData)

    XCTAssertTrue(result.removals.isEmpty)
    // The original cell is trimmed down to its left piece [0, 3).
    guard let otherUpdate = result.updates.first(where: { $0.id == otherID }) else {
      return XCTFail("expected the split host cell's left piece in the updates")
    }
    XCTAssertEqual(otherUpdate.newPosition, 0, accuracy: 0.0001)
    XCTAssertEqual(otherUpdate.newDuration, 3, accuracy: 0.0001)

    // The remainder became two fragments: [4, 5) between the two edits, and [8, 10) after the
    // second edit — never a single [4, 10) overlapping the second edit.
    let insertions = result.insertions.sorted { $0.position < $1.position }
    XCTAssertEqual(insertions.count, 2)
    XCTAssertTrue(insertions.allSatisfy { $0.sourceID == otherID && $0.row == 0 })
    XCTAssertEqual(insertions[0].position, 4, accuracy: 0.0001)
    XCTAssertEqual(insertions[0].duration, 1, accuracy: 0.0001)
    XCTAssertEqual(insertions[1].position, 8, accuracy: 0.0001)
    XCTAssertEqual(insertions[1].duration, 2, accuracy: 0.0001)

    // Nothing the resolver emits for OTHER cells overlaps either edited region [3, 4) or [5, 8) —
    // the edited cells' own entries are of course identical to those spans and are excluded here.
    let editedSpans = [(3.0, 4.0), (5.0, 8.0)]
    let emittedSpans = result.updates.filter { $0.id != firstID && $0.id != secondID }.map { ($0.newPosition, $0.newPosition + $0.newDuration) }
      + insertions.map { ($0.position, $0.position + $0.duration) }
    for (start, end) in emittedSpans {
      for (editedStart, editedEnd) in editedSpans {
        XCTAssertFalse(start < editedEnd && end > editedStart, "emitted span [\(start), \(end)) overlaps edited [\(editedStart), \(editedEnd))")
      }
    }
  }

  // MARK: - Mode `.none`

  func testNoneModeLeavesOverlapsUntouched() {
    let rowData = [makeRow([(position: 0, duration: 4), (position: 1, duration: 4)])]
    let editedID = rowData[0, 0].id
    let edited: [MIDITimeTableViewEditedCellData] = [
      MIDITimeTableViewEditedCellData(id: editedID, index: MIDITimeTableCellIndex(row: 0, index: 0), newRowIndex: 0, newPosition: 0, newDuration: 4)
    ]

    let result = MIDITimeTableCellOverlapResolver.resolve(
      editedCells: edited, in: rowData, using: MIDITimeTableCellOverlapResolver.Options(mode: .none))

    XCTAssertEqual(result.updates.count, 1)
    XCTAssertEqual(result.updates[0].id, editedID)
    XCTAssertTrue(result.removals.isEmpty)
    XCTAssertTrue(result.insertions.isEmpty)
  }

  // MARK: - Parity between the batch API and the interactive funnel

  func testBatchAndFunnelAgreeOnShiftGeometry() {
    // The same fixture, resolved once through the batch snapshot API (nothing pinned, all cells
    // self-organize by position) and once through the interactive funnel as a single edit that
    // moves every cell in the row at once (so the funnel's "rest of the row" pass has nothing
    // left to resolve against) — both must produce identical geometry, since a batch call with no
    // priority cells and a funnel call editing 100% of a row exercise the exact same self-resolve
    // shift sweep underneath.
    let rowData = [makeRow([(position: 0, duration: 2), (position: 1, duration: 1), (position: 4, duration: 1)])]
    let cells = rowData[0].cells.enumerated().map { offset, cell in
      MIDITimeTableViewEditedCellData(
        id: cell.id, index: MIDITimeTableCellIndex(row: 0, index: offset), newRowIndex: 0,
        newPosition: cell.position, newDuration: cell.duration)
    }

    let batch = MIDITimeTableCellOverlapResolver.resolveOverlaps(
      in: cells, using: MIDITimeTableCellOverlapResolver.Options(mode: .shiftLaterCells, minimumPosition: nil))
    let funnel = resolveByShifting(editedCells: cells, in: rowData)

    let batchByID = Dictionary(uniqueKeysWithValues: batch.updates.map { ($0.id, $0) })
    XCTAssertEqual(funnel.updates.count, cells.count)
    for update in funnel.updates {
      guard let expected = batchByID[update.id] else { return XCTFail("missing \(update.id) in batch result") }
      XCTAssertEqual(update.newPosition, expected.newPosition, accuracy: 0.000001)
      XCTAssertEqual(update.newDuration, expected.newDuration, accuracy: 0.000001)
    }
  }
}
