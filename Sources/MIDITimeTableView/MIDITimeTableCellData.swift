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

/// Optional protocol for app-owned cell models that can be displayed in a `MIDITimeTableView`.
///
/// `MIDITimeTableView` does not require this protocol; its data source remains the source of
/// truth. Conforming your own model can make the data source implementation and app-side history
/// code more structured without forcing your data to inherit from framework-owned model classes.
public protocol MIDITimeTableCellRepresentable {
  /// Stable identity for the cell.
  var id: MIDITimeTableCellID { get }
  /// Position of the cell in beats.
  var position: Double { get set }
  /// Duration of the cell in beats.
  var duration: Double { get set }
}

/// Optional protocol for app-owned row models that group time table cells.
///
/// This is only a convenience contract. `MIDITimeTableViewDataSource` still asks for row/cell
/// counts and geometry explicitly so apps remain free to use any backing model shape.
public protocol MIDITimeTableRowRepresentable {
  associatedtype Cell: MIDITimeTableCellRepresentable

  /// Cells displayed in this row.
  var cells: [Cell] { get set }
}

/// Optional protocol for app-owned history stacks used with
/// `MIDITimeTableViewDelegate.midiTimeTableViewShouldPushHistory(_:)`.
///
/// The core view intentionally does not own history snapshots because app models may include
/// arbitrary domain data. This protocol provides a small, consistent shape for apps that want to
/// keep their own undo/redo manager near their time table data.
public protocol MIDITimeTableHistoryRepresentable {
  associatedtype Item
  var history: MIDITimeTableHistoryStack<Item> { get set }
}

/// Generic history storage for app-owned time table snapshots.
public struct MIDITimeTableHistoryStack<Item> {
  public private(set) var items: [Item]
  public private(set) var currentIndex: Int
  public var limit: Int

  public init(limit: Int = 10) {
    self.items = []
    self.currentIndex = -1
    self.limit = limit
  }

  public var currentItem: Item? {
    guard currentIndex >= 0, currentIndex < items.count else { return nil }
    return items[currentIndex]
  }

  public var hasPreviousItem: Bool {
    return currentIndex > 0
  }

  public var hasNextItem: Bool {
    return currentIndex < items.count - 1
  }

  public mutating func append(_ item: Item) {
    var newHistory = items.enumerated().filter({ $0.offset <= currentIndex }).map({ $0.element })
    newHistory.append(item)
    newHistory = Array(newHistory.suffix(limit))
    currentIndex = newHistory.count - 1
    items = newHistory
  }

  public mutating func undo() -> Item? {
    guard hasPreviousItem else { return nil }
    currentIndex -= 1
    return currentItem
  }

  public mutating func redo() -> Item? {
    guard hasNextItem else { return nil }
    currentIndex += 1
    return currentItem
  }
}

public extension MIDITimeTableHistoryRepresentable {
  var hasPreviousHistoryItem: Bool {
    return history.hasPreviousItem
  }

  var hasNextHistoryItem: Bool {
    return history.hasNextItem
  }

  var currentHistoryItem: Item? {
    return history.currentItem
  }

  mutating func append(_ item: Item) {
    history.append(item)
  }

  mutating func undo() -> Item? {
    return history.undo()
  }

  mutating func redo() -> Item? {
    return history.redo()
  }
}
