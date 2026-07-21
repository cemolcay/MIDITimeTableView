//
//  MIDITimeTableCellData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import Foundation

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

/// Stable identity for a time table cell. Unlike `MIDITimeTableCellIndex` — which is only
/// a snapshot of a cell's current (row, array-position) and goes stale the moment any cell in the
/// same row is added, removed, or reordered — a cell's `id` never changes across edits, so it's
/// the reliable way to track "the same cell" through a sequence of moves, resizes, or splits.
public typealias MIDITimeTableCellID = UUID
