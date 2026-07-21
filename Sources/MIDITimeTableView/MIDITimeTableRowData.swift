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
  /// Stable ids of cells fully covered by an edited cell; these should be removed entirely.
  public var removals: [MIDITimeTableCellID]
  /// New cells created by splitting a cell that had an edited cell land inside it.
  public var insertions: [MIDITimeTableCellInsertion]

  public init(updates: [MIDITimeTableViewEditedCellData] = [], removals: [MIDITimeTableCellID] = [], insertions: [MIDITimeTableCellInsertion] = []) {
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

  /// Finds a cell's current `(row, array-position)` by its stable id.
  ///
  /// Unlike a `MIDITimeTableCellIndex` captured earlier, this is always accurate no matter how
  /// many edits have mutated the array since — it searches fresh every call instead of trusting a
  /// snapshot that could have gone stale.
  ///
  /// - Parameter id: Stable id of the cell to find.
  /// - Returns: The cell's current index, or `nil` if no cell with that id exists.
  public func index(ofCellID id: MIDITimeTableCellID) -> MIDITimeTableCellIndex? {
    for (row, rowData) in enumerated() {
      if let i = rowData.cells.firstIndex(where: { $0.id == id }) {
        return MIDITimeTableCellIndex(row: row, index: i)
      }
    }
    return nil
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
  /// Every update and removal is located by the cell's stable `id`, looked up fresh right before
  /// it's used (via `index(ofCellID:)`). That makes this correct regardless of the order the
  /// changes are applied in — unlike addressing by `(row, index)`, an id lookup can never go
  /// stale partway through, even when several of these changes land in the same row.
  ///
  /// - Parameter result: The edit result reported by the time table view.
  public mutating func apply(_ result: MIDITimeTableCellEditResult) {
    guard !isEmpty else { return }

    for update in result.updates {
      guard let currentIndex = index(ofCellID: update.id) else { continue }
      var cell = self[currentIndex]
      cell.position = update.newPosition
      cell.duration = update.newDuration
      if currentIndex.row == update.newRowIndex {
        self[currentIndex] = cell
      } else if update.newRowIndex >= 0 && update.newRowIndex < count {
        removeCell(at: currentIndex)
        appendCell(cell, row: update.newRowIndex)
      }
    }

    for id in result.removals {
      guard let currentIndex = index(ofCellID: id) else { continue }
      removeCell(at: currentIndex)
    }

    for insertion in result.insertions where insertion.row >= 0 && insertion.row < count {
      appendCell(insertion.cell, row: insertion.row)
    }
  }
}

/// Data for each row of `MIDITimeTableView`.
///
/// `MIDITimeTableRowData` is intentionally model-only: it stores timing/cell data and nothing
/// about row header or cell rendering. Subclass it to attach typed domain state for a row.
open class MIDITimeTableRowData {
  /// Cell data that row shows.
  public var cells: [MIDITimeTableCellData]

  /// Calculates the duration of cells in the row.
  open var duration: Double {
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
  public init(cells: [MIDITimeTableCellData]) {
    self.cells = cells
  }

  /// Returns a copy suitable for history snapshots.
  ///
  /// Subclasses that add stored properties should override this and return the same concrete row
  /// type so undo/redo preserves their typed row metadata.
  open func copy() -> MIDITimeTableRowData {
    return MIDITimeTableRowData(cells: cells)
  }
}
