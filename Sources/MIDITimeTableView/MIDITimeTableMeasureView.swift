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
  public var barCount: Int = 0 { didSet{ update() }}
  /// Number of beats in a measure.
  public var beatCount: Int = 4 { didSet{ update() }}
  /// Property to show bar numbers. Defaults true.
  public var showsBarNumbers = true { didSet{ update() }}
  /// Stores measure layers.
  private var barLayers = [MIDITimeTableMeasureLayer]()

  /// Refreshes and redraws measure layers
  public func update() {
    barLayers.forEach({ $0.removeFromSuperlayer() })
    barLayers = []
    setNeedsLayout()
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    let width = frame.width / CGFloat(barCount)

    for i in 0..<barCount {
      let barLayer = MIDITimeTableMeasureLayer()
      barLayer.tintColor = tintColor
      barLayer.showsBarNumber = showsBarNumbers
      barLayer.beatCount = beatCount
      barLayer.barNumber = i + 1
      barLayer.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: frame.height)
      layer.addSublayer(barLayer)
      barLayers.append(barLayer)
    }
  }
}
