//
//  MIDITimeTableMeasureView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Draws time table measures in its frame.
public class MIDITimeTableMeasureView: UIView {
  /// Number of measure bars.
  public var barCount: Int = 1
  /// Number of beats in a measure.
  public var beatCount: Int = 4
  /// Property to show bar numbers. Defaults true.
  public var showsBarNumbers = true
  /// Stores measure layers.
  private var barLayers = [MIDITimeTableMeasureLayer]()

  public override func layoutSubviews() {
    super.layoutSubviews()
    barLayers.forEach({ $0.removeFromSuperlayer() })
    barLayers = []
    let width = frame.width / CGFloat(barCount)
    for i in 0..<barCount {
      let barLayer = MIDITimeTableMeasureLayer()
      barLayer.showsBarNumber = showsBarNumbers
      barLayer.beatCount = beatCount
      barLayer.barNumber = i + 1
      barLayer.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: frame.height)
      layer.addSublayer(barLayer)
      barLayers.append(barLayer)
    }
  }
}
