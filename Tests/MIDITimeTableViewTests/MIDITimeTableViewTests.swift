//
//  MIDITimeTableViewTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

final class MIDITimeTableViewTests: XCTestCase {

    func testTimeSignatureBeatsPerMeasure() {
        let signature = MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
        XCTAssertEqual(signature.beats, 4)
        XCTAssertEqual(signature.noteValue, .quarter)
    }

    func testCellDataStoresPositionAndDuration() {
        let cell = MIDITimeTableCellData(data: "C7", position: 0, duration: 4)
        XCTAssertEqual(cell.position, 0)
        XCTAssertEqual(cell.duration, 4)
    }

    func testRowDataHoldsCells() {
        let row = MIDITimeTableRowData(
            cells: [MIDITimeTableCellData(data: "Dm7", position: 4, duration: 4)])
        XCTAssertEqual(row.cells.count, 1)
        XCTAssertEqual(row.cells.first?.position, 4)
    }
}
