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
  internal static func resolve(editedCells: [MIDITimeTableViewEditedCellData], in rowData: [MIDITimeTableRowLayoutData], skippingCellIDs: Set<MIDITimeTableCellID>? = nil) -> MIDITimeTableCellEditResult {
    let editedIDSet = skippingCellIDs ?? Set(editedCells.map({ $0.id }))
    // Cells fully covered by an edit, tracked both by id (the output) and by their position in
    // the immutable `rowData` snapshot (so the scan below can skip them without needing to look
    // them up again).
    var removedIndices = Set<MIDITimeTableCellIndex>()
    var removals = [MIDITimeTableCellID]()
    // Live inserted fragments (right-hand remainders of "landed strictly inside" splits), tracked
    // as working state so that a *later* edited cell in the same batch that overlaps a fragment
    // resolves against it too, instead of the fragment being emitted untouched and leaving a
    // residual overlap. `sourceID` is propagated across nested splits so the fragment always
    // references the original host cell to clone from.
    var insertionWorking = [(row: Int, sourceID: MIDITimeTableCellID, data: MIDITimeTableCellLayoutData)]()
    // Working state of non-edited cells touched so far, keyed by their position in the immutable
    // `rowData` snapshot, so that multiple edited cells landing on the same underlying cell
    // resolve against each other in sequence rather than clobbering one another's changes. `id`
    // is preserved on every value here since we only ever mutate `position`/`duration` in place.
    var working = [MIDITimeTableCellIndex: MIDITimeTableCellLayoutData]()

    func currentCell(at index: MIDITimeTableCellIndex) -> MIDITimeTableCellLayoutData? {
      if let cell = working[index] { return cell }
      guard index.row >= 0, index.row < rowData.count,
        index.index >= 0, index.index < rowData[index.row].cells.count
        else { return nil }
      return rowData[index]
    }

    for edited in editedCells {
      let editedData = MIDITimeTableCellLayoutData(id: edited.id, position: edited.newPosition, duration: edited.newDuration)
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
          let rightPiece = MIDITimeTableCellLayoutData(
            id: MIDITimeTableCellID(),
            position: editedData.endPosition,
            duration: otherCell.endPosition - editedData.endPosition)
          otherCell.duration = editedData.position - otherCell.position
          working[otherCellIndex] = otherCell
          insertionWorking.append((targetRow, otherCell.id, rightPiece))
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

      // Re-resolve the edit against fragments already split off earlier in this same batch. Same
      // four cases as above; a fragment split again just appends another fragment to the list,
      // which any still-later edited cell will in turn see.
      var fragmentIndex = 0
      while fragmentIndex < insertionWorking.count {
        var fragment = insertionWorking[fragmentIndex]
        guard fragment.row == targetRow, editedData.overlaps(fragment.data) else {
          fragmentIndex += 1
          continue
        }

        if editedData.position <= fragment.data.position && editedData.endPosition >= fragment.data.endPosition {
          insertionWorking.remove(at: fragmentIndex)
          continue
        } else if editedData.position > fragment.data.position && editedData.endPosition < fragment.data.endPosition {
          let rightPiece = MIDITimeTableCellLayoutData(
            id: MIDITimeTableCellID(),
            position: editedData.endPosition,
            duration: fragment.data.endPosition - editedData.endPosition)
          fragment.data.duration = editedData.position - fragment.data.position
          insertionWorking[fragmentIndex] = fragment
          insertionWorking.append((targetRow, fragment.sourceID, rightPiece))
        } else if editedData.position <= fragment.data.position {
          fragment.data.duration = fragment.data.endPosition - editedData.endPosition
          fragment.data.position = editedData.endPosition
          insertionWorking[fragmentIndex] = fragment
        } else {
          fragment.data.duration = editedData.position - fragment.data.position
          insertionWorking[fragmentIndex] = fragment
        }
        fragmentIndex += 1
      }
    }

    // Sort so the batched result is deterministic for hosts that diff arrays, rather than reflecting
    // the (unordered) dictionary's iteration order.
    let updates: [MIDITimeTableViewEditedCellData] = working
      .map { index, cell in
        MIDITimeTableViewEditedCellData(id: cell.id, index: index, newRowIndex: index.row, newPosition: cell.position, newDuration: cell.duration)
      }
      .sorted { ($0.index.row, $0.index.index) < ($1.index.row, $1.index.index) }
    let insertions = insertionWorking.map { entry in
      MIDITimeTableCellInsertion(row: entry.row, sourceID: entry.sourceID, id: entry.data.id, position: entry.data.position, duration: entry.data.duration)
    }
    return MIDITimeTableCellEditResult(updates: updates, removals: removals, insertions: insertions)
  }

  /// Resolves overlaps within the edited selection itself. The normal resolver skips every
  /// edited id so selected cells win against non-selected cells, but a multi-cell resize can make
  /// selected neighbors overlap each other. This pass gives earlier cells in each row priority
  /// and trims/removes later selected cells against them.
  internal static func resolveOverlapsAmongEditedCells(_ editedCells: [MIDITimeTableViewEditedCellData]) -> MIDITimeTableCellEditResult {
    var removals = [MIDITimeTableCellID]()
    var working = editedCells

    let rowGroups = Dictionary(grouping: working.indices, by: { working[$0].newRowIndex })
    for indices in rowGroups.values {
      let orderedIndices = indices.sorted {
        if working[$0].newPosition == working[$1].newPosition {
          return working[$0].newDuration > working[$1].newDuration
        }
        return working[$0].newPosition < working[$1].newPosition
      }

      for blockerOffset in orderedIndices.indices {
        let blockerIndex = orderedIndices[blockerOffset]
        if removals.contains(working[blockerIndex].id) { continue }

        let blockerStart = working[blockerIndex].newPosition
        let blockerEnd = working[blockerIndex].newPosition + working[blockerIndex].newDuration

        for targetIndex in orderedIndices.dropFirst(blockerOffset + 1) {
          if removals.contains(working[targetIndex].id) { continue }

          let targetStart = working[targetIndex].newPosition
          let targetEnd = working[targetIndex].newPosition + working[targetIndex].newDuration
          guard blockerStart < targetEnd && blockerEnd > targetStart else { continue }

          if blockerEnd >= targetEnd {
            removals.append(working[targetIndex].id)
          } else {
            working[targetIndex].newPosition = blockerEnd
            working[targetIndex].newDuration = targetEnd - blockerEnd
          }
        }
      }
    }

    let removedIDs = Set(removals)
    let updates = working.filter({ !removedIDs.contains($0.id) })
    return MIDITimeTableCellEditResult(updates: updates, removals: removals)
  }
}
