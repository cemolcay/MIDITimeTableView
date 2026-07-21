//
//  MIDITimeTableRowData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

extension Collection where Iterator.Element == MIDITimeTableRowData {

  /// Returns a cell data at the index of a row.
  ///
  /// - Parameters:
  ///   - row: Row index of the cell data.
  ///   - index: Index number in the row of the cell data.
  public subscript(row: Int, index: Int) -> MIDITimeTableCellData {
    get {
      guard let this = self as? [MIDITimeTableRowData] // immutable copy of self.
        else { fatalError("This is not a 'MIDITimeTableRowData' collection type.") }
      return this[row].cells[index]
    } set {
      guard var this = self as? [MIDITimeTableRowData] // mutable copy of self.
        else { fatalError("This is not a 'MIDITimeTableRowData' collection type.") }
      this[row].cells[index] = newValue
      self = this as! Self
    }
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
    guard var this = self as? [MIDITimeTableRowData] else { return }
    this[at].cells.append(cell)
    self = this as! Self
  }

  /// Removes a cell from an index.
  ///
  /// - Parameter index: Cell index of the cell will be removed.
  /// - Returns: Returns the removed cell.
  public mutating func removeCell(at index: MIDITimeTableCellIndex) -> MIDITimeTableCellData {
    guard var this = self as? [MIDITimeTableRowData] else { fatalError() }
    let cell = this[index.row].cells.remove(at: index.index)
    self = this as! Self
    return cell
  }

  /// Removes multiple cells from multiple indices.
  ///
  /// - Parameter indicies: Indices of cells that will be removed.
  public mutating func removeCells(at indicies: [MIDITimeTableCellIndex]) {
    guard var this = self as? [MIDITimeTableRowData] else { fatalError() }
    for (row, index) in indicies.ordered {
      this[row].cells = this[row].cells.enumerated().filter({ !index.contains($0.offset) }).map({ $0.element })
    }
    self = this as! Self
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
