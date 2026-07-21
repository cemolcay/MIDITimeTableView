//
//  MIDITimeTableMeasureView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Draws time table measures in its frame. Use `tintColor` property to change text and bar colors.
open class MIDITimeTableMeasureView: UIView {
  /// Number of measure bars.
  public var barCount: Int = 0 { didSet { if oldValue != barCount { setNeedsLayout() } } }
  /// Number of beats in a measure.
  public var beatCount: Int = 4 { didSet { if oldValue != beatCount { setNeedsLayout() } } }
  /// Number of grid subdivisions per beat, used for drawing the small snap ticks within a beat.
  /// Defaults 4.
  public var snapResolution: Int = 4 { didSet { if oldValue != snapResolution { setNeedsLayout() } } }
  /// Property to show bar numbers. Defaults true.
  public var showsBarNumbers = true { didSet { if oldValue != showsBarNumbers { setNeedsLayout() } } }
  /// Stores measure layers.
  private var barLayers = [MIDITimeTableMeasureLayer]()

  /// Forces every bar layer to be rebuilt from scratch on the next layout pass. You shouldn't
  /// normally need this — `barCount`/`beatCount`/`snapResolution`/`showsBarNumbers` already
  /// trigger a refresh when they actually change — but it's kept as a manual escape hatch.
  public func update() {
    setNeedsLayout()
  }

  open override func layoutSubviews() {
    super.layoutSubviews()

    guard barCount > 0 else {
      barLayers.forEach({ $0.removeFromSuperlayer() })
      barLayers = []
      return
    }
    let width = frame.width / CGFloat(barCount)

    // Reconcile the layer count to `barCount` instead of unconditionally appending new layers.
    // `layoutSubviews` can run again with the same `barCount` — e.g. only this view's width
    // changed during a zoom — and blindly creating fresh layers every time used to stack
    // duplicates on top of the stale ones instead of replacing them.
    if barLayers.count > barCount {
      barLayers[barCount...].forEach({ $0.removeFromSuperlayer() })
      barLayers.removeLast(barLayers.count - barCount)
    } else if barLayers.count < barCount {
      for _ in barLayers.count..<barCount {
        let barLayer = MIDITimeTableMeasureLayer()
        layer.addSublayer(barLayer)
        barLayers.append(barLayer)
      }
    }

    for (i, barLayer) in barLayers.enumerated() {
      barLayer.tintColor = tintColor
      barLayer.showsBarNumber = showsBarNumbers
      barLayer.beatCount = beatCount
      barLayer.snapResolution = snapResolution
      barLayer.displayScale = traitCollection.displayScale
      barLayer.barNumber = i + 1
      barLayer.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: frame.height)
      // A reused layer whose frame size didn't change wouldn't otherwise redraw its content (its
      // own properties have no `didSet`), so ask explicitly.
      barLayer.setNeedsLayout()
    }
  }
}
