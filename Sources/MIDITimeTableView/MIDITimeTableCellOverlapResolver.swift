//
//  MIDITimeTableCellOverlapResolver.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 21.07.2026.
//  Copyright © 2026 cemolcay. All rights reserved.
//

import Foundation

/// Pure overlap-resolution algorithm used by `MIDITimeTableView` after a cell is moved or
/// resized. Kept independent of the view so it can be reasoned about and tested without any
/// UIKit state: it only needs the edited cells' new geometry and a snapshot of the row data as it
/// was immediately before the edit.
public enum MIDITimeTableCellOverlapResolver {
  /// Resolves the cells an edit (move or resize) now overlaps against `rowData`, a snapshot that
  /// reflects the pre-edit layout for every cell other than the ones being edited: cells fully
  /// covered by an edited cell are removed, cells partially covered are trimmed, and cells an
  /// edited cell lands strictly inside are split into a trimmed piece and an inserted remainder.
  ///
  /// - Parameters:
  ///   - editedCells: The cells that were just moved or resized, with their new geometry.
  ///   - rowData: Snapshot of all rows as they were immediately before the edit.
  /// - Returns: The resolved updates, removals and insertions for the affected OTHER cells.
  public static func resolve(editedCells: [MIDITimeTableViewEditedCellData], in rowData: [MIDITimeTableRowData]) -> MIDITimeTableCellEditResult {
    let editedIDSet = Set(editedCells.map({ $0.id }))
    // Cells fully covered by an edit, tracked both by id (the output) and by their position in
    // the immutable `rowData` snapshot (so the scan below can skip them without needing to look
    // them up again).
    var removedIndices = Set<MIDITimeTableCellIndex>()
    var removals = [MIDITimeTableCellID]()
    var insertions = [MIDITimeTableCellInsertion]()
    // Working state of non-edited cells touched so far, keyed by their position in the immutable
    // `rowData` snapshot, so that multiple edited cells landing on the same underlying cell
    // resolve against each other in sequence rather than clobbering one another's changes. `id`
    // is preserved on every value here since we only ever mutate `position`/`duration` in place.
    var working = [MIDITimeTableCellIndex: MIDITimeTableCellData]()

    func currentCell(at index: MIDITimeTableCellIndex) -> MIDITimeTableCellData? {
      if let cell = working[index] { return cell }
      guard index.row >= 0, index.row < rowData.count,
        index.index >= 0, index.index < rowData[index.row].cells.count
        else { return nil }
      return rowData[index]
    }

    for edited in editedCells {
      let editedData = MIDITimeTableCellData(data: 0, position: edited.newPosition, duration: edited.newDuration)
      let targetRow = edited.newRowIndex
      guard targetRow >= 0, targetRow < rowData.count else { continue }

      for otherIndexInRow in rowData[targetRow].cells.indices {
        let otherCellIndex = MIDITimeTableCellIndex(row: targetRow, index: otherIndexInRow)
        if removedIndices.contains(otherCellIndex) { continue }
        guard var otherCell = currentCell(at: otherCellIndex) else { continue }
        if editedIDSet.contains(otherCell.id) { continue }
        guard editedData.overlaps(otherCell) else { continue }

        if editedData.position <= otherCell.position && editedData.endPosition >= otherCell.endPosition {
          // Fully covered by the edit -> remove.
          removedIndices.insert(otherCellIndex)
          removals.append(otherCell.id)
          working.removeValue(forKey: otherCellIndex)
        } else if editedData.position > otherCell.position && editedData.endPosition < otherCell.endPosition {
          // Edit lands strictly inside -> trim the left piece in place (keeps its original id),
          // insert the right remainder as a brand new cell with a fresh id.
          let rightPiece = MIDITimeTableCellData(
            data: otherCell.data,
            position: editedData.endPosition,
            duration: otherCell.endPosition - editedData.endPosition)
          otherCell.duration = editedData.position - otherCell.position
          working[otherCellIndex] = otherCell
          insertions.append((targetRow, rightPiece))
        } else if editedData.position <= otherCell.position {
          // Overlaps the other cell's start -> trim it from the left.
          otherCell.duration = otherCell.endPosition - editedData.endPosition
          otherCell.position = editedData.endPosition
          working[otherCellIndex] = otherCell
        } else {
          // Overlaps the other cell's end -> trim it from the right.
          otherCell.duration = editedData.position - otherCell.position
          working[otherCellIndex] = otherCell
        }
      }
    }

    let updates: [MIDITimeTableViewEditedCellData] = working.map { index, cell in
      (cell.id, index, index.row, cell.position, cell.duration)
    }
    return MIDITimeTableCellEditResult(updates: updates, removals: removals, insertions: insertions)
  }
}
