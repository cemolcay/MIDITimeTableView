//
//  MIDITimeTableHistoryStackTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

private struct TestHistory: MIDITimeTableHistoryRepresentable {
  var history = MIDITimeTableHistoryStack<[Int]>(limit: 3)
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
}
