//
//  MIDITimeTableLayoutData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 21.07.2026.
//  Copyright © 2026 cemolcay. All rights reserved.
//

import Foundation

/// A new cell layout created by splitting an existing cell that had an edited cell land inside it.
public struct MIDITimeTableCellInsertion: Equatable {
  /// Row the new fragment belongs to.
  public var row: Int
  /// Stable id of the existing cell this fragment was split from. Clone that model when inserting.
  public var sourceID: MIDITimeTableCellID
  /// Stable id assigned to the new fragment.
  public var id: MIDITimeTableCellID
  /// Position, in beats, of the new fragment.
  public var position: Double
  /// Duration, in beats, of the new fragment.
  public var duration: Double

  public init(row: Int, sourceID: MIDITimeTableCellID, id: MIDITimeTableCellID, position: Double, duration: Double) {
    self.row = row
    self.sourceID = sourceID
    self.id = id
    self.position = position
    self.duration = duration
  }
}

/// Result of an edit (move or resize), including its effect on the cells it now overlaps.
public struct MIDITimeTableCellEditResult {
  /// Every cell whose position/duration changed: the cells that were directly moved or resized,
  /// plus any other cells trimmed because one of those edits now overlaps them.
  public var updates: [MIDITimeTableViewEditedCellData]
  /// Stable ids of cells fully covered by an edited cell; these should be removed entirely.
  public var removals: [MIDITimeTableCellID]
  /// New layout fragments created by splitting a cell that had an edited cell land inside it.
  public var insertions: [MIDITimeTableCellInsertion]

  public init(updates: [MIDITimeTableViewEditedCellData] = [], removals: [MIDITimeTableCellID] = [], insertions: [MIDITimeTableCellInsertion] = []) {
    self.updates = updates
    self.removals = removals
    self.insertions = insertions
  }
}

internal struct MIDITimeTableCellLayoutData: Identifiable {
  internal let id: MIDITimeTableCellID
  internal var position: Double
  internal var duration: Double

  internal init(id: MIDITimeTableCellID, position: Double, duration: Double) {
    self.id = id
    self.position = position
    self.duration = duration
  }

  internal var endPosition: Double {
    return position + duration
  }

  internal func overlaps(_ other: MIDITimeTableCellLayoutData) -> Bool {
    return position < other.endPosition && endPosition > other.position
  }
}

internal struct MIDITimeTableRowLayoutData {
  internal var cells: [MIDITimeTableCellLayoutData]

  internal var duration: Double {
    var max = 0.0
    for cell in cells {
      let position = cell.position + cell.duration
      max = position > max ? position : max
    }
    return max
  }
}

extension Array where Element == MIDITimeTableRowLayoutData {

  internal subscript(row: Int, index: Int) -> MIDITimeTableCellLayoutData {
    get { return self[row].cells[index] }
    set { self[row].cells[index] = newValue }
  }

  internal subscript(index: MIDITimeTableCellIndex) -> MIDITimeTableCellLayoutData {
    get {
      return self[index.row, index.index]
    } set {
      self[index.row, index.index] = newValue
    }
  }

  internal func index(ofCellID id: MIDITimeTableCellID) -> MIDITimeTableCellIndex? {
    for (row, rowData) in enumerated() {
      if let i = rowData.cells.firstIndex(where: { $0.id == id }) {
        return MIDITimeTableCellIndex(row: row, index: i)
      }
    }
    return nil
  }

  internal mutating func appendCell(_ cell: MIDITimeTableCellLayoutData, row at: Int) {
    self[at].cells.append(cell)
  }

  @discardableResult
  internal mutating func removeCell(at index: MIDITimeTableCellIndex) -> MIDITimeTableCellLayoutData {
    return self[index.row].cells.remove(at: index.index)
  }

  internal mutating func removeCells(at indicies: [MIDITimeTableCellIndex]) {
    for (row, index) in indicies.ordered {
      self[row].cells = self[row].cells.enumerated().filter({ !index.contains($0.offset) }).map({ $0.element })
    }
  }

  internal mutating func apply(_ result: MIDITimeTableCellEditResult) {
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
      appendCell(
        MIDITimeTableCellLayoutData(
          id: insertion.id,
          position: insertion.position,
          duration: insertion.duration),
        row: insertion.row)
    }
  }
}
