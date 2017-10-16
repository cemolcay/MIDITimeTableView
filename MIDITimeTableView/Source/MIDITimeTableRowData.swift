//
//  MIDITimeTableRowData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Data for each row of `MIDITimeTableView`.
public struct MIDITimeTableRowData {
  /// Cell data that row shows.
  public var cells: [MIDITimeTableCellData]
  /// Header cell reference that optionally shown as the `MIDITimeTableView`'s row header.
  public var headerCellView: MIDITimeTableHeaderCellView
  /// View of each cell in the row.
  public var cellView: (MIDITimeTableCellData) -> MIDITimeTableCellView

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
  public init(cells: [MIDITimeTableCellData], headerCellView: MIDITimeTableHeaderCellView, cellView: @escaping (MIDITimeTableCellData) -> MIDITimeTableCellView) {
    self.cells = cells
    self.headerCellView = headerCellView
    self.cellView = cellView
  }
}
