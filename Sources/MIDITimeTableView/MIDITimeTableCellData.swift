//
//  MIDITimeTableCellData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Defines cell index in the time table view.
public struct MIDITimeTableCellIndex: Hashable {
  /// Row index of the cell.
  public var row: Int
  /// Index number in the row. Does not represent column.
  public var index: Int

  /// Initilizes the index with row and column indices.
  ///
  /// - Parameter row: Row index of the cell.
  /// - Parameter index: Index number in the row.
  public init(row: Int, index: Int) {
    self.row = row
    self.index = index
  }

  // MARK: Hashable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(row)
    hasher.combine(index)
  }

  // MARK: Equatable

  /// Checks equality between two indices.
  ///
  /// - Parameters:
  ///   - lhs: Left hand side of the equation.
  ///   - rhs: Right hand side of the equation.
  /// - Returns: Returns true if two indicies are equal, otherwise returns false.
  public static func ==(lhs: MIDITimeTableCellIndex, rhs: MIDITimeTableCellIndex) -> Bool {
    return lhs.row == rhs.row && lhs.index == rhs.index
  }
}

extension Sequence where Element == MIDITimeTableCellIndex {

  /// Creates a dictionary that rows as key and indices of same rows as their value.
  public var ordered: [Int: [Int]] {
    var dict = [Int: [Int]]()
    for cellIndex in self {
      dict[cellIndex.row, default: []].append(cellIndex.index)
    }
    return dict
  }
}

/// Stable identity for a `MIDITimeTableCellData`. Unlike `MIDITimeTableCellIndex` — which is only
/// a snapshot of a cell's current (row, array-position) and goes stale the moment any cell in the
/// same row is added, removed, or reordered — a cell's `id` never changes across edits, so it's
/// the reliable way to track "the same cell" through a sequence of moves, resizes, or splits.
public typealias MIDITimeTableCellID = UUID

/// Data of each cell in the rows of `MIDITimeTableView`.
public struct MIDITimeTableCellData: Identifiable {
  /// Stable identity of the cell. See `MIDITimeTableCellID`.
  public let id: MIDITimeTableCellID

  /// Actual data to show on views.
  public var data: Any

  /// Position of the cell in the row in beats.
  /// For example if it is second beat of a second bar in a 4/4 measure, than it should be 6.0
  public var position: Double

  /// Duration of the cell in the row in beats.
  /// For example if it is a quarter beat in a 4/4 measure, than it should be 0.25
  public var duration: Double

  /// Initilizes the cell data.
  ///
  /// - Parameters:
  ///   - id: Stable identity for the cell. Defaults to a new random id; pass an existing one when
  ///     re-hydrating a cell (e.g. from your own persistence) so its identity survives a reload.
  ///   - data: Data to show in cell view.
  ///   - position: Position of cell in row in form of beats.
  ///   - duration: Duration of cell in row in form of beats.
  public init(id: MIDITimeTableCellID = MIDITimeTableCellID(), data: Any, position: Double, duration: Double) {
    self.id = id
    self.data = data
    self.position = position
    self.duration = duration
  }

  /// End position of the cell in the row in beats. Equals `position + duration`.
  public var endPosition: Double {
    return position + duration
  }

  /// Checks if this cell overlaps another cell's beat range.
  ///
  /// - Parameter other: The other cell to check overlap against.
  /// - Returns: Returns true if the two cells' beat ranges intersect.
  public func overlaps(_ other: MIDITimeTableCellData) -> Bool {
    return position < other.endPosition && endPosition > other.position
  }
}
