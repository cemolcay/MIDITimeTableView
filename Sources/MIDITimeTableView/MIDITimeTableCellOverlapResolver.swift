//
//  MIDITimeTableCellOverlapResolver.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 21.07.2026.
//  Copyright © 2026 cemolcay. All rights reserved.
//

import Foundation

/// Pure overlap-resolution algorithm used by `MIDITimeTableView` after a cell is moved or
/// resized, and by hosts that want deterministic non-overlapping layout data before handing it
/// to the time table. Kept independent of the view so it can be reasoned about and tested
/// without any UIKit state.
///
/// Every public and internal entry point funnels through the same row-sweep engine at the
/// bottom of this file, so `.trimEarlierCells` and `.shiftLaterCells` mean exactly the same
/// thing everywhere they're used — interactively through `MIDITimeTableView.overlapResolution`,
/// or in a one-off batch normalization via `resolveOverlaps(in:using:priorityCellIDs:)`.
public enum MIDITimeTableCellOverlapResolver {

  // MARK: - Mode & Options

  /// Overlap-resolution behavior.
  public enum Mode: Int, Codable, CaseIterable, Hashable, Sendable {
    /// The winning cell (the higher-priority one — see `priorityCellIDs`, or the cell that was
    /// just edited in `MIDITimeTableView`) keeps its exact geometry. Any cell it overlaps is
    /// trimmed; a cell it lands strictly inside is split into a trimmed left piece and a new
    /// right-piece cell. Pieces shorter than `Options.minimumDuration` after trimming are
    /// removed. Among cells with equal priority, the later-positioned cell wins.
    case trimEarlierCells
    /// The winning cell keeps its exact geometry and position. Every cell it overlaps is pushed
    /// forward just enough to clear it; once a cell has been displaced, that displacement carries
    /// through the rest of the row so later gaps/rests keep their spacing. No cell is ever
    /// trimmed, split, or removed — every duration is preserved. Among cells with equal priority,
    /// the earlier-positioned cell wins and keeps its spot.
    case shiftLaterCells
    /// Overlap resolution is disabled: cells keep the exact geometry they were given, and nothing
    /// else is touched. Overlaps are allowed through untouched.
    case none
  }

  /// Tunable knobs for overlap resolution.
  public struct Options: Equatable, Hashable, Codable, Sendable {
    /// Resolution behavior.
    public var mode: Mode
    /// In `.trimEarlierCells`, a trimmed or split piece shorter than this (in beats) is removed
    /// instead of kept as a sliver. Ignored in `.shiftLaterCells`, which never changes durations.
    public var minimumDuration: Double
    /// Positions/durations within this many beats of each other are treated as equal — cells that
    /// only touch (one's end equals the other's start) are never considered overlapping, and
    /// floating point pixel-math noise at a boundary never triggers a trim or a shift.
    public var tolerance: Double
    /// In `.trimEarlierCells`, whether a cell the winner lands strictly inside is split into a
    /// left piece and a new right-piece cell (`true`, the default) or simply truncated at the
    /// winner's start, discarding its tail (`false`).
    public var splitsHostCells: Bool
    /// Cells are never placed before this position. `nil` disables the clamp.
    public var minimumPosition: Double?

    public init(
      mode: Mode = .trimEarlierCells,
      minimumDuration: Double = 0.001,
      tolerance: Double = 0.000001,
      splitsHostCells: Bool = true,
      minimumPosition: Double? = 0
    ) {
      self.mode = mode
      self.minimumDuration = minimumDuration
      self.tolerance = tolerance
      self.splitsHostCells = splitsHostCells
      self.minimumPosition = minimumPosition
    }
  }

  // MARK: - Public batch API

  /// Resolves overlaps in a caller-owned model snapshot using only public layout types.
  ///
  /// Useful when a host mutates its backing data directly (generating a pattern, inserting a
  /// cell in the middle, randomizing a track) and wants normalized, non-overlapping layout data
  /// before handing it to `MIDITimeTableView`. Cells are resolved independently per row; input
  /// does not need to be pre-sorted by row or position.
  ///
  /// - Parameters:
  ///   - cells: Public cell layout data to resolve, in any order.
  ///   - options: Resolution behavior.
  ///   - priorityCellIDs: Cells that must win every overlap they're part of and must never be
  ///     trimmed, split, or moved — for example a cell the host just inserted or is about to
  ///     insert, so the rest of the row makes room for it. Cells outside this set are resolved
  ///     against each other and against the priority cells using `options.mode`'s normal
  ///     priority rule.
  /// - Returns: The resolved updates, removals, and split insertions.
  public static func resolveOverlaps(
    in cells: [MIDITimeTableViewEditedCellData],
    using options: Options,
    priorityCellIDs: Set<MIDITimeTableCellID> = []
  ) -> MIDITimeTableCellEditResult {
    var updates = [MIDITimeTableViewEditedCellData]()
    var removals = [MIDITimeTableCellID]()
    var insertions = [MIDITimeTableCellInsertion]()

    let grouped = Dictionary(grouping: cells, by: { $0.newRowIndex })
    for row in grouped.keys.sorted() {
      guard let rowCells = grouped[row], !rowCells.isEmpty else { continue }

      if options.mode == .none {
        updates.append(contentsOf: rowCells)
        continue
      }

      let segments = rowCells.enumerated().map { offset, cell in
        Segment(
          id: cell.id,
          position: cell.newPosition,
          duration: cell.newDuration,
          originalPosition: cell.newPosition,
          isPriority: priorityCellIDs.contains(cell.id),
          sourceID: nil,
          originalIndex: cell.index,
          orderingIndex: offset)
      }

      switch options.mode {
      case .trimEarlierCells:
        let result = trimSweepRow(segments, options: options)
        removals.append(contentsOf: result.removed)
        for survivor in result.survivors {
          if result.insertedIDs.contains(survivor.id) {
            insertions.append(survivor.asInsertion(row: row))
          } else {
            updates.append(survivor.asEditedCellData(row: row))
          }
        }

      case .shiftLaterCells:
        let priority = segments.filter(\.isPriority).sorted { $0.position < $1.position }
        let rest = segments.filter { !$0.isPriority }.sorted { $0.originalPosition < $1.originalPosition }
        let placed = shiftSweepRow(pinned: priority, unpinned: rest, tolerance: options.tolerance)
        updates.append(contentsOf: placed.map { $0.asEditedCellData(row: row) })

      case .none:
        break
      }
    }

    clampPositions(&updates, &insertions, floor: options.minimumPosition)
    sortByRowThenPosition(&updates, &insertions)
    return MIDITimeTableCellEditResult(updates: updates, removals: removals, insertions: insertions)
  }

  /// Convenience overload matching the pre-`Options` call shape.
  ///
  /// - Parameters:
  ///   - cells: Public cell layout data to resolve, in any order.
  ///   - mode: Resolution behavior.
  ///   - minimumDuration: Cells shorter than this after trimming are removed. Used only by
  ///     `.trimEarlierCells`.
  public static func resolveOverlaps(
    in cells: [MIDITimeTableViewEditedCellData],
    mode: Mode,
    minimumDuration: Double = 0.001
  ) -> MIDITimeTableCellEditResult {
    return resolveOverlaps(in: cells, using: Options(mode: mode, minimumDuration: minimumDuration))
  }

  // MARK: - Internal funnel (interactive edits)

  /// Resolves a move/resize edit against `rowData`, a snapshot of every row immediately before
  /// the edit. This is the single entry point `MIDITimeTableView` uses for every interactive
  /// edit, in every mode: it first resolves the edited cells against each other — a multi-cell
  /// resize can make selected cells overlap one another — then resolves the survivors against
  /// the rest of each row they touch. The returned result is always complete and
  /// self-sufficient: it includes the edited cells' own final geometry, so a caller never needs
  /// to assemble anything else on top of it.
  internal static func resolve(
    editedCells: [MIDITimeTableViewEditedCellData],
    in rowData: [MIDITimeTableRowLayoutData],
    using options: Options
  ) -> MIDITimeTableCellEditResult {
    guard !editedCells.isEmpty else { return MIDITimeTableCellEditResult() }

    if options.mode == .none {
      var updates = editedCells
      var insertions = [MIDITimeTableCellInsertion]()
      clampPositions(&updates, &insertions, floor: options.minimumPosition)
      return MIDITimeTableCellEditResult(updates: updates)
    }

    let editedIDs = Set(editedCells.map(\.id))
    var originalRow = [MIDITimeTableCellID: Int]()
    var originalGeometry = [MIDITimeTableCellID: (position: Double, duration: Double)]()
    for (rowIndex, row) in rowData.enumerated() {
      for cell in row.cells {
        originalRow[cell.id] = rowIndex
        originalGeometry[cell.id] = (cell.position, cell.duration)
      }
    }

    var allUpdates = [MIDITimeTableViewEditedCellData]()
    var allRemovals = [MIDITimeTableCellID]()
    var allInsertions = [MIDITimeTableCellInsertion]()

    let editedByTargetRow = Dictionary(grouping: editedCells, by: { $0.newRowIndex })
    for row in editedByTargetRow.keys.sorted() {
      guard let group = editedByTargetRow[row], row >= 0, row < rowData.count else { continue }

      // Pass 1: resolve this row's edited cells against each other.
      let selfInput = group.enumerated().map { offset, cell in
        Segment(
          id: cell.id, position: cell.newPosition, duration: cell.newDuration,
          originalPosition: cell.newPosition, isPriority: false, sourceID: nil,
          originalIndex: cell.index, orderingIndex: offset)
      }

      let priority: [Segment]
      // Fragments a split creates in pass 1 (below) must still be reported as insertions after
      // pass 2 re-touches them — pass 2 gets its own fresh `insertedIDs` set, so this carries
      // pass 1's fragment ids forward to be unioned with it.
      var selfInsertedIDs = Set<MIDITimeTableCellID>()
      switch options.mode {
      case .trimEarlierCells:
        let selfResolved = trimSweepRow(selfInput, options: options)
        allRemovals.append(contentsOf: selfResolved.removed)
        priority = selfResolved.survivors
        selfInsertedIDs = selfResolved.insertedIDs
      case .shiftLaterCells:
        priority = shiftSweepRow(pinned: [], unpinned: selfInput.sorted { $0.position < $1.position }, tolerance: options.tolerance)
      case .none:
        priority = selfInput
      }

      // Pass 2: resolve the (self-resolved) priority set against the rest of the row.
      let hostCells = rowData[row].cells.enumerated().filter { !editedIDs.contains($0.element.id) }
      let unpinned = hostCells.map { offset, cell in
        Segment(
          id: cell.id, position: cell.position, duration: cell.duration,
          originalPosition: cell.position, isPriority: false, sourceID: nil,
          originalIndex: MIDITimeTableCellIndex(row: row, index: offset), orderingIndex: offset)
      }

      switch options.mode {
      case .trimEarlierCells:
        let priorityMarked = priority.map { segment -> Segment in
          var s = segment
          s.isPriority = true
          return s
        }
        let result = trimSweepRow(unpinned + priorityMarked, options: options)
        allRemovals.append(contentsOf: result.removed)
        let insertedIDs = result.insertedIDs.union(selfInsertedIDs)
        for survivor in result.survivors {
          if insertedIDs.contains(survivor.id) {
            allInsertions.append(survivor.asInsertion(row: row))
          } else if survivor.isPriority {
            allUpdates.append(survivor.asEditedCellData(row: row))
          } else if let original = originalGeometry[survivor.id],
            abs(original.position - survivor.position) > options.tolerance || abs(original.duration - survivor.duration) > options.tolerance {
            allUpdates.append(survivor.asEditedCellData(row: row))
          }
        }

      case .shiftLaterCells:
        let priorityMarked = priority.map { segment -> Segment in
          var s = segment
          s.isPriority = true
          return s
        }

        // Time-insertion rule: growing an edited block from its right edge (same start, longer
        // end) inserts real time that pushes later cells; only cells originally FROM this row
        // count toward that block, so a cell arriving from another row never inflates it.
        let sameRowGroup = group.filter { originalRow[$0.id] == row }
        var insertedDuration = 0.0
        if !sameRowGroup.isEmpty,
          let originalStart = sameRowGroup.compactMap({ originalGeometry[$0.id]?.position }).min(),
          let originalEnd = sameRowGroup.compactMap({ originalGeometry[$0.id].map { $0.position + $0.duration } }).max(),
          let editedStart = priorityMarked.map(\.position).min(),
          let editedEnd = priorityMarked.map({ $0.position + $0.duration }).max(),
          abs(editedStart - originalStart) <= options.tolerance,
          editedEnd > originalEnd + options.tolerance {
          insertedDuration = editedEnd - originalEnd
        }
        let originalRowEnd = sameRowGroup.compactMap { originalGeometry[$0.id].map { $0.position + $0.duration } }.max() ?? .infinity

        let seededUnpinned = unpinned.map { segment -> Segment in
          guard insertedDuration > 0, segment.originalPosition >= originalRowEnd - options.tolerance else { return segment }
          var s = segment
          s.originalPosition += insertedDuration
          return s
        }.sorted { $0.originalPosition < $1.originalPosition }

        let placed = shiftSweepRow(pinned: priorityMarked.sorted { $0.position < $1.position }, unpinned: seededUnpinned, tolerance: options.tolerance)
        for survivor in placed {
          if survivor.isPriority {
            allUpdates.append(survivor.asEditedCellData(row: row))
          } else if let original = originalGeometry[survivor.id], abs(original.position - survivor.position) > options.tolerance {
            allUpdates.append(survivor.asEditedCellData(row: row))
          }
        }

      case .none:
        allUpdates.append(contentsOf: priority.map { $0.asEditedCellData(row: row) })
      }
    }

    clampPositions(&allUpdates, &allInsertions, floor: options.minimumPosition)
    sortByRowThenPosition(&allUpdates, &allInsertions)
    return MIDITimeTableCellEditResult(updates: allUpdates, removals: allRemovals, insertions: allInsertions)
  }

  // MARK: - Private sweep engine

  /// Working unit for both sweeps. `position`/`duration` are mutated in place as the sweep
  /// resolves overlaps; every other field is fixed at construction.
  private struct Segment {
    let id: MIDITimeTableCellID
    var position: Double
    var duration: Double
    /// Pre-sweep position. For priority/edited input this equals `position` throughout (priority
    /// segments are never moved). For host cells being shifted this is the pre-edit position,
    /// possibly pre-seeded by the time-insertion rule; `shiftSweepRow` adds the accumulated
    /// displacement on top of it.
    var originalPosition: Double
    /// Priority segments win every overlap they're part of and are never trimmed, split, moved,
    /// or removed by the sweep.
    var isPriority: Bool
    /// Set on a right-piece fragment created by a split; references the cell it was split from
    /// (propagated through nested splits so it always points at the original host).
    let sourceID: MIDITimeTableCellID?
    /// Row/array-position snapshot to report back on the output, if known.
    let originalIndex: MIDITimeTableCellIndex?
    /// Stable tie-break for otherwise-equal sort keys, so output is deterministic regardless of
    /// dictionary/array iteration order upstream.
    let orderingIndex: Int

    var endPosition: Double { position + duration }

    func asEditedCellData(row: Int) -> MIDITimeTableViewEditedCellData {
      return MIDITimeTableViewEditedCellData(
        id: id,
        index: originalIndex ?? MIDITimeTableCellIndex(row: row, index: 0),
        newRowIndex: row,
        newPosition: position,
        newDuration: duration)
    }

    func asInsertion(row: Int) -> MIDITimeTableCellInsertion {
      return MIDITimeTableCellInsertion(row: row, sourceID: sourceID ?? id, id: id, position: position, duration: duration)
    }
  }

  private struct RowTrimResult {
    var survivors: [Segment]
    var removed: [MIDITimeTableCellID]
    var insertedIDs: Set<MIDITimeTableCellID>
  }

  /// Flattens `input` into a non-overlapping list. Segments are inserted one at a time — every
  /// non-priority segment first (in position order, shortest-first on a tie so the longer of two
  /// coincident cells survives), then every priority segment (in position order) — and each
  /// insertion clips whatever already sits in `output` using the same four cases the old
  /// per-edit resolver used: fully covered → removed, landed strictly inside → split, overlaps
  /// the start → trimmed from the left, overlaps the end → trimmed from the right. Because a
  /// split's right piece is appended back into `output`, a later insertion that lands on it
  /// re-triggers the same clipping — a split fragment further split by a later winner just
  /// appends another fragment, with no separate re-scan pass required.
  private static func trimSweepRow(_ input: [Segment], options: Options) -> RowTrimResult {
    guard !input.isEmpty else { return RowTrimResult(survivors: [], removed: [], insertedIDs: []) }
    let tolerance = options.tolerance

    let ordered = input.sorted { lhs, rhs in
      if lhs.isPriority != rhs.isPriority { return rhs.isPriority }
      if abs(lhs.position - rhs.position) > tolerance { return lhs.position < rhs.position }
      if abs(lhs.duration - rhs.duration) > tolerance { return lhs.duration < rhs.duration }
      return lhs.orderingIndex < rhs.orderingIndex
    }

    var output = [Segment]()
    var removed = [MIDITimeTableCellID]()
    var insertedIDs = Set<MIDITimeTableCellID>()

    for seg in ordered {
      var i = 0
      while i < output.count {
        let host = output[i]
        let overlaps = seg.position < host.endPosition - tolerance && seg.endPosition > host.position + tolerance
        guard overlaps else { i += 1; continue }

        let fullyCovers = seg.position <= host.position + tolerance && seg.endPosition >= host.endPosition - tolerance
        let landsStrictlyInside = seg.position > host.position + tolerance && seg.endPosition < host.endPosition - tolerance

        if fullyCovers {
          output.remove(at: i)
          removed.append(host.id)
          insertedIDs.remove(host.id)
          continue
        } else if landsStrictlyInside && options.splitsHostCells {
          var left = host
          left.duration = seg.position - host.position
          let right = Segment(
            id: MIDITimeTableCellID(),
            position: seg.endPosition,
            duration: host.endPosition - seg.endPosition,
            originalPosition: seg.endPosition,
            isPriority: false,
            sourceID: host.sourceID ?? host.id,
            originalIndex: nil,
            orderingIndex: host.orderingIndex)
          output[i] = left
          output.insert(right, at: i + 1)
          insertedIDs.insert(right.id)
          i += 2
        } else if seg.position <= host.position + tolerance {
          var trimmed = host
          trimmed.duration = host.endPosition - seg.endPosition
          trimmed.position = seg.endPosition
          output[i] = trimmed
          i += 1
        } else {
          var trimmed = host
          trimmed.duration = seg.position - host.position
          output[i] = trimmed
          i += 1
        }
      }
      output.append(seg)
    }

    var survivors = [Segment]()
    for s in output {
      if !s.isPriority && s.duration < options.minimumDuration - tolerance {
        removed.append(s.id)
        insertedIDs.remove(s.id)
      } else {
        survivors.append(s)
      }
    }

    return RowTrimResult(survivors: survivors, removed: removed, insertedIDs: insertedIDs)
  }

  /// Places `unpinned` around the fixed `pinned` obstacles without ever changing a duration.
  /// `pinned` must already be mutually non-overlapping and sorted by position — every entry is
  /// emitted unchanged. `unpinned` is processed in ascending `originalPosition` order (the row's
  /// natural pre-edit order, so a cell that starts before an obstacle but whose original span
  /// reaches into it is still pushed clear of it, not left overlapping); each segment is placed
  /// at `originalPosition + accumulatedShift`, then nudged forward past the running cursor and
  /// any pinned obstacle it still overlaps, repeating until stable. Once a segment is displaced
  /// by some amount, `accumulatedShift` grows by that amount permanently, so every later segment
  /// in the row inherits at least that much displacement — this is what keeps a rest's width
  /// intact even when the cell right after it happens not to collide with anything itself.
  private static func shiftSweepRow(pinned: [Segment], unpinned: [Segment], tolerance: Double) -> [Segment] {
    var accumulatedShift = 0.0
    var cursor = -Double.infinity
    var placed = [Segment]()
    placed.reserveCapacity(pinned.count + unpinned.count)

    for seg in unpinned {
      var pos = seg.originalPosition + accumulatedShift
      var changed = true
      while changed {
        changed = false
        if pos < cursor - tolerance {
          pos = cursor
          changed = true
        }
        for obstacle in pinned {
          let stillOverlaps = pos < obstacle.endPosition - tolerance && pos + seg.duration > obstacle.position + tolerance
          if stillOverlaps {
            pos = obstacle.endPosition
            changed = true
          }
        }
      }

      let bump = pos - (seg.originalPosition + accumulatedShift)
      if bump > 0 { accumulatedShift += bump }

      var s = seg
      s.position = pos
      placed.append(s)
      cursor = max(cursor, pos + s.duration)
    }

    return placed + pinned
  }

  private static func clampPositions(
    _ updates: inout [MIDITimeTableViewEditedCellData],
    _ insertions: inout [MIDITimeTableCellInsertion],
    floor: Double?
  ) {
    guard let floor else { return }
    for i in updates.indices where updates[i].newPosition < floor {
      updates[i].newPosition = floor
    }
    for i in insertions.indices where insertions[i].position < floor {
      insertions[i].position = floor
    }
  }

  /// Sorts the result by (row, position) so it's deterministic for hosts that diff arrays,
  /// rather than reflecting whatever order the sweep happened to emit entries in.
  private static func sortByRowThenPosition(
    _ updates: inout [MIDITimeTableViewEditedCellData],
    _ insertions: inout [MIDITimeTableCellInsertion]
  ) {
    updates.sort {
      if $0.newRowIndex != $1.newRowIndex { return $0.newRowIndex < $1.newRowIndex }
      return $0.newPosition < $1.newPosition
    }
    insertions.sort {
      if $0.row != $1.row { return $0.row < $1.row }
      return $0.position < $1.position
    }
  }
}
