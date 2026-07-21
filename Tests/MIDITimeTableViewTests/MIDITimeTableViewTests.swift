//
//  MIDITimeTableViewTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

private final class LongPressSelectionDelegate: MIDITimeTableCellViewDelegate {
    var tappedCell: MIDITimeTableCellView?

    func midiTimeTableCellViewDidMove(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {}
    func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {}
    func midiTimeTableCellViewDidTap(_ midiTimeTableCellView: MIDITimeTableCellView) {
        tappedCell = midiTimeTableCellView
    }
    func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView) {}
}

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

    func testLongPressSelectsCellThroughDelegate() {
        let cell = MIDITimeTableCellView(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        let delegate = LongPressSelectionDelegate()
        cell.delegate = delegate

        cell.prepareForMenuPresentation()

        XCTAssertTrue(delegate.tappedCell === cell)
        XCTAssertTrue(cell.isSelected)
    }
}
