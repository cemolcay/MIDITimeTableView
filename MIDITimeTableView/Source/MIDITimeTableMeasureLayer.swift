//
//  MIDITimeTableMeasureLayer.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Draws a time signature measure with beat and subbeat bars.
open class MIDITimeTableMeasureLayer: CALayer {
  /// Text layer that optionally shows bar number on it.
  public var textLayer = CATextLayer()
  /// Shape layer that draws measure bars.
  public var shapeLayer = CAShapeLayer()
  /// Draws bar numbers if set true. Defaults true.
  public var showsBarNumber = true
  /// Number of beats in the measure.
  public var beatCount = 4
  /// Number of bar to show in text layer.
  public var barNumber = 0
  /// Text and bar colors.
  public var tintColor: UIColor = .black

  /// Initilizes layer.
  public override init() {
    super.init()
    commonInit()
  }

  public override init(layer: Any) {
    super.init(layer: layer)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    addSublayer(textLayer)
    addSublayer(shapeLayer)
  }

  open override func layoutSublayers() {
    super.layoutSublayers()
    // Text layer
    textLayer.frame = CGRect(x: 2, y: 0, width: frame.width, height: frame.height/2)
    textLayer.fontSize = frame.height/2
    textLayer.foregroundColor = tintColor.cgColor
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.alignmentMode = .left
    textLayer.string = showsBarNumber ? "\(barNumber)" : ""
    // Shape layer
    shapeLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    let path = UIBezierPath()
    let width = frame.width / CGFloat(beatCount * 4)
    var currentX: CGFloat = width
    for i in 1...beatCount*4 {
      if i == beatCount * 4 {
        path.move(to: CGPoint(x: currentX, y: 0))
      } else if i%4 == 0 {
        path.move(to: CGPoint(x: currentX, y: shapeLayer.frame.height/2))
      } else {
        path.move(to: CGPoint(x: currentX, y: shapeLayer.frame.height/4*3))
      }
      path.addLine(to: CGPoint(x: currentX, y: shapeLayer.frame.height))
      path.close()
      currentX += width
    }
    // Draw measure
    shapeLayer.path = path.cgPath
    shapeLayer.lineWidth = 1
    shapeLayer.strokeColor = tintColor.cgColor
  }
}
