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
  /// Hashable value
  public var hashValue: Int

  /// Initilizes the index with row and column indices.
  ///
  /// - Parameter row: Row index of the cell.
  /// - Parameter index: Index number in the row.
  public init(row: Int, index: Int) {
    self.row = row
    self.index = index
    hashValue = row.hashValue ^ index.hashValue &* 16777619
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

extension Collection where Iterator.Element == MIDITimeTableCellIndex {

  /// Creates a dictionary that rows as key and indices of same rows as their value.
  public var ordered: [Int: [Int]] {
    guard let this = self as? [MIDITimeTableCellIndex] else { fatalError() }
    var dict = [Int: [Int]]()
    let keys = Set(this.map({ $0.row })).sorted()
    for key in keys {
      dict[key] = this.filter({ $0.row == key }).map({ $0.index })
    }
    return dict
  }
}

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
