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

    func testCellIndexStoresRowAndIndex() {
        let index = MIDITimeTableCellIndex(row: 2, index: 4)
        XCTAssertEqual(index.row, 2)
        XCTAssertEqual(index.index, 4)
    }
}
