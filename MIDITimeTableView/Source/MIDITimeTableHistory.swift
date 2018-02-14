//
//  MIDITimeTableHistory.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 9.02.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

/// A history item that represents row data array.
public typealias MIDITimeTableHistoryItem = [MIDITimeTableRowData]

/// Informs about changes on history.
public protocol MIDITimeTableHistoryDelegate: class {

  /// Informs about current index of history is changed. It means either user did undo or redo.
  ///
  /// - Parameters:
  ///   - history: Current history object reference.
  ///   - item: Current item on history that should be shown.
  func midiTimeTableHistory(_ history: MIDITimeTableHistory, didHistoryChange item: MIDITimeTableHistoryItem)
}

/// Creates and manages history with a limit and items. Messages changes throught the delegate.
public class MIDITimeTableHistory {
  /// Items holding in the history queue.
  public private(set) var items = [MIDITimeTableHistoryItem]()
  /// Current index of history. Defaults nothing, -1.
  public private(set) var currentIndex = -1
  /// Limit of the history items. Defaults 10.
  public var limit: Int { didSet{ limitDidChange() }}
  /// Delegate that informs about changes.
  public weak var delegate: MIDITimeTableHistoryDelegate?

  /// Returns current history item.
  public var currentItem: MIDITimeTableHistoryItem {
    return items[currentIndex]
  }

  /// Returns true if user could do undo.
  public var hasPreviousItem: Bool {
    return currentIndex > 0
  }

  /// Returns true if user could do redo.
  public var hasNextItem: Bool {
    return currentIndex < items.count - 1
  }

  /// Manages history item limit changes.
  private func limitDidChange() {
    if items.count > limit {
      items = Array(items.prefix(limit))
    }
    if currentIndex >= items.count {
      currentIndex = items.count - 1
      delegate?.midiTimeTableHistory(self, didHistoryChange: currentItem)
    }
  }

  /// Initilizes the history.
  ///
  /// - Parameter limit: Limit of the history. Defaults 10.
  public init(limit: Int = 10) {
    self.limit = limit
  }

  /// Makes an undo. Moves back `currentIndex` pointer one item.
  public func undo() {
    guard hasPreviousItem else { return }
    currentIndex -= 1
    delegate?.midiTimeTableHistory(self, didHistoryChange: currentItem)
  }

  /// Makes a redo. Moves forward `currentIndex` pointer one item.
  public func redo() {
    guard hasNextItem else { return }
    currentIndex += 1
    delegate?.midiTimeTableHistory(self, didHistoryChange: currentItem)
  }

  /// Adds an item to history queue. If hits the limit, removes the first item and appends end of the queue.
  ///
  /// - Parameter item: Item to add to history.
  public func append(item: MIDITimeTableHistoryItem) {
    var newHistory = items.enumerated().filter({ $0.offset <= currentIndex }).map({ $0.element })
    newHistory.append(item)
    newHistory = Array(newHistory.suffix(limit))
    currentIndex = newHistory.count - 1
    items = newHistory
  }
}
