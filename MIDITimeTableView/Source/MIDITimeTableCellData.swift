//
//  MIDITimeTableCellData.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Data of each cell in the rows of `MIDITimeTableView`.
public struct MIDITimeTableCellData {
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
  ///   - data: Data to show in cell view.
  ///   - position: Position of cell in row in form of beats.
  ///   - duration: Duration of cell in row in form of beats.
  public init(data: Any, position: Double, duration: Double) {
    self.data = data
    self.position = position
    self.duration = duration
  }
}
