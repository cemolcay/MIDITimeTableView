//
//  MIDITimeTableRowData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// A new cell created by splitting an existing cell that had an edited cell land inside it.
public typealias MIDITimeTableCellInsertion = (row: Int, cell: MIDITimeTableCellData)

/// Result of an edit (move or resize), including its effect on the cells it now overlaps.
/// Self-sufficient: `apply(_:)` is the only call a host needs to keep its data in sync, in
/// place of hand-rolling overlap resolution.
public struct MIDITimeTableCellEditResult {
  /// Every cell whose position/duration changed: the cells that were directly moved or resized,
  /// plus any other cells trimmed because one of those edits now overlaps them.
  public var updates: [MIDITimeTableViewEditedCellData]
  /// Cells fully covered by an edited cell; these should be removed entirely.
  public var removals: [MIDITimeTableCellIndex]
  /// New cells created by splitting a cell that had an edited cell land inside it.
  public var insertions: [MIDITimeTableCellInsertion]

  public init(updates: [MIDITimeTableViewEditedCellData] = [], removals: [MIDITimeTableCellIndex] = [], insertions: [MIDITimeTableCellInsertion] = []) {
    self.updates = updates
    self.removals = removals
    self.insertions = insertions
  }
}

extension Array where Element == MIDITimeTableRowData {

  /// Returns a cell data at the index of a row.
  ///
  /// - Parameters:
  ///   - row: Row index of the cell data.
  ///   - index: Index number in the row of the cell data.
  public subscript(row: Int, index: Int) -> MIDITimeTableCellData {
    get { return self[row].cells[index] }
    set { self[row].cells[index] = newValue }
  }

  /// Returns a cell data with `MIDITimeTableCellIndex`.
  ///
  /// - Parameter index: Cell index of the cell data.
  public subscript(index: MIDITimeTableCellIndex) -> MIDITimeTableCellData {
    get {
      return self[index.row, index.index]
    } set {
      self[index.row, index.index] = newValue
    }
  }

  /// Adds a cell data in a row.
  ///
  /// - Parameters:
  ///   - cell: Cell data to append.
  ///   - at: The row index to append cell data.
  public mutating func appendCell(_ cell: MIDITimeTableCellData, row at: Int) {
    self[at].cells.append(cell)
  }

  /// Removes a cell from an index.
  ///
  /// - Parameter index: Cell index of the cell will be removed.
  /// - Returns: Returns the removed cell.
  @discardableResult
  public mutating func removeCell(at index: MIDITimeTableCellIndex) -> MIDITimeTableCellData {
    return self[index.row].cells.remove(at: index.index)
  }

  /// Removes multiple cells from multiple indices.
  ///
  /// - Parameter indicies: Indices of cells that will be removed.
  public mutating func removeCells(at indicies: [MIDITimeTableCellIndex]) {
    for (row, index) in indicies.ordered {
      self[row].cells = self[row].cells.enumerated().filter({ !index.contains($0.offset) }).map({ $0.element })
    }
  }

  /// Applies an edit result — moved/resized/trimmed cells, cells fully covered by the edit, and
  /// split remainders — coming from `MIDITimeTableView`'s overlap resolution. This is the
  /// single call a host needs in `midiTimeTableView(_:didEdit:)` to keep its data in sync;
  /// see `Example/MIDITimeTableView/ViewController.swift` for the reference usage.
  ///
  /// - Parameter result: The edit result reported by the time table view.
  public mutating func apply(_ result: MIDITimeTableCellEditResult) {
    guard !isEmpty else { return }

    // Resolve every update against its ORIGINAL index first (before any structural change),
    // splitting into "stays in the same row" (safe to update in place) and "moves to another
    // row" (needs a remove + append). Keying by the original index keeps this correct even when
    // multiple cells in the same row are edited at once — nothing shifts until `removeCells`
    // below, which removes a whole row's indices in one pass.
    var sameRowUpdates = [MIDITimeTableCellIndex: MIDITimeTableCellData]()
    var movedAway = [MIDITimeTableCellIndex: (row: Int, cell: MIDITimeTableCellData)]()

    for update in result.updates {
      let index = update.index
      guard index.row >= 0, index.row < count,
        index.index >= 0, index.index < self[index.row].cells.count
        else { continue }
      var cell = self[index]
      cell.position = update.newPosition
      cell.duration = update.newDuration
      if index.row == update.newRowIndex {
        sameRowUpdates[index] = cell
      } else {
        movedAway[index] = (update.newRowIndex, cell)
      }
    }

    var appendedByRow = [Int: [MIDITimeTableCellData]]()
    for (_, moved) in movedAway {
      appendedByRow[moved.row, default: []].append(moved.cell)
    }
    for insertion in result.insertions {
      appendedByRow[insertion.row, default: []].append(insertion.cell)
    }

    // In-place updates don't change row length/order, so they're safe to apply before removal.
    for (index, cell) in sameRowUpdates {
      self[index] = cell
    }

    // Remove fully covered cells and cells that moved to another row in one grouped pass per row.
    var removalIndices = result.removals
    removalIndices.append(contentsOf: movedAway.keys)
    removeCells(at: removalIndices)

    // Append moved and split-off cells to their destination rows.
    for (row, cells) in appendedByRow where row >= 0 && row < count {
      for cell in cells {
        appendCell(cell, row: row)
      }
    }
  }
}

/// Data for each row of `MIDITimeTableView`.
public struct MIDITimeTableRowData {
  /// Cell data that row shows.
  public var cells: [MIDITimeTableCellData]
  /// Header cell reference that optionally shown as the `MIDITimeTableView`'s row header.
  public var headerCellView: MIDITimeTableHeaderCellView
  /// View of each cell in the row.
  public var cellView: (MIDITimeTableCellData) -> MIDITimeTableCellView
  /// Other data for your custom objects. It is useful when moving history related custom data back and forth.
  public var customData: Any?

  /// Calculates the duration of cells in the row.
  public var duration: Double {
    var max = 0.0
    for cell in cells {
      let position = cell.position + cell.duration
      max = position > max ? position : max
    }
    return max
  }

  /// Initilizes the row data.
  ///
  /// - Parameters:
  ///   - cells: Data of the cells.
  ///   - headerCellView: Row header cell view reference.
  ///   - cellView: Each view of cell data in row.
  ///   - customData: Other data for your custom objects. It is useful when moving history related custom data back and forth.
  public init(cells: [MIDITimeTableCellData], headerCellView: MIDITimeTableHeaderCellView, cellView: @escaping (MIDITimeTableCellData) -> MIDITimeTableCellView, customData: Any? = nil) {
    self.cells = cells
    self.headerCellView = headerCellView
    self.cellView = cellView
    self.customData = customData
  }
}
