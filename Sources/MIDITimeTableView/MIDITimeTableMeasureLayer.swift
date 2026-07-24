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
  /// Shape layer that draws bar-boundary tick lines.
  public var barLineLayer = CAShapeLayer()
  /// Shape layer that draws beat tick lines.
  public var beatLineLayer = CAShapeLayer()
  /// Shape layer that draws subbeat tick lines.
  public var subbeatLineLayer = CAShapeLayer()
  /// Shape layer that draws the bottom line.
  public var bottomLineLayer = CAShapeLayer()
  /// Draws bar numbers if set true. Defaults true.
  public var showsBarNumber = true { didSet { if oldValue != showsBarNumber { setNeedsLayout() } } }
  /// Shows beat tick lines if set true. Defaults true.
  public var showsBeatLines = true { didSet { if oldValue != showsBeatLines { setNeedsLayout() } } }
  /// Shows subbeat tick lines if set true. Defaults true.
  public var showsSubbeatLines = true { didSet { if oldValue != showsSubbeatLines { setNeedsLayout() } } }
  /// Shows a horizontal line along the bottom edge of the measure. Defaults true.
  public var showsBottomLine = true { didSet { if oldValue != showsBottomLine { setNeedsLayout() } } }
  /// Number of beats in the measure.
  public var beatCount = 4 { didSet { if oldValue != beatCount { setNeedsLayout() } } }
  /// Number of grid subdivisions per beat, used for drawing the small snap ticks. Defaults 4.
  public var snapResolution = 4 { didSet { if oldValue != snapResolution { setNeedsLayout() } } }
  /// Number of bar to show in text layer.
  public var barNumber = 0 { didSet { if oldValue != barNumber { setNeedsLayout() } } }
  /// Text and bar colors.
  public var tintColor: UIColor = .black { didSet { if oldValue != tintColor { setNeedsLayout() } } }
  /// Color of bar-boundary tick lines. Defaults nil, which uses `tintColor`.
  public var barLineColor: UIColor? { didSet { setNeedsLayout() } }
  /// Color of beat tick lines. Defaults nil, which uses `tintColor`.
  public var beatLineColor: UIColor? { didSet { setNeedsLayout() } }
  /// Color of subbeat tick lines. Defaults nil, which uses `tintColor`.
  public var subbeatLineColor: UIColor? { didSet { setNeedsLayout() } }
  /// Color of the bottom line. Defaults nil, which uses `tintColor`.
  public var bottomLineColor: UIColor? { didSet { setNeedsLayout() } }
  /// Width of bar-boundary tick lines. Defaults 1.
  public var barLineWidth: CGFloat = 1 { didSet { if oldValue != barLineWidth { setNeedsLayout() } } }
  /// Width of beat tick lines. Defaults 1.
  public var beatLineWidth: CGFloat = 1 { didSet { if oldValue != beatLineWidth { setNeedsLayout() } } }
  /// Width of subbeat tick lines. Defaults 1.
  public var subbeatLineWidth: CGFloat = 1 { didSet { if oldValue != subbeatLineWidth { setNeedsLayout() } } }
  /// Width of the bottom line. Defaults 1.
  public var bottomLineWidth: CGFloat = 1 { didSet { if oldValue != bottomLineWidth { setNeedsLayout() } } }
  /// Rendering scale used for the bar-number text layer's crispness. A plain `CALayer` has no
  /// `traitCollection` of its own, so this is propagated down from the owning
  /// `MIDITimeTableMeasureView`'s `traitCollection.displayScale` rather than read here directly.
  public var displayScale: CGFloat = UITraitCollection.current.displayScale

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
    addSublayer(bottomLineLayer)
    addSublayer(barLineLayer)
    addSublayer(beatLineLayer)
    addSublayer(subbeatLineLayer)
  }

  open override func layoutSublayers() {
    super.layoutSublayers()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    // Text layer
    textLayer.frame = CGRect(x: 2, y: 0, width: frame.width, height: frame.height/2)
    textLayer.fontSize = frame.height/2
    textLayer.foregroundColor = tintColor.cgColor
    textLayer.contentsScale = displayScale
    textLayer.alignmentMode = .left
    textLayer.string = showsBarNumber ? "\(barNumber)" : ""
    // Shape layers
    let layerFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    barLineLayer.frame = layerFrame
    beatLineLayer.frame = layerFrame
    subbeatLineLayer.frame = layerFrame
    bottomLineLayer.frame = layerFrame

    let barPath = UIBezierPath()
    let beatPath = UIBezierPath()
    let subbeatPath = UIBezierPath()
    let bottomPath = UIBezierPath()
    if showsBottomLine {
      bottomPath.move(to: CGPoint(x: 0, y: bottomLineLayer.frame.height))
      bottomPath.addLine(to: CGPoint(x: bottomLineLayer.frame.width, y: bottomLineLayer.frame.height))
      bottomPath.close()
    }
    let subdivisions = max(1, snapResolution)
    let ticks = max(1, beatCount) * subdivisions
    let width = frame.width / CGFloat(ticks)
    for i in 0...ticks {
      let currentX = CGFloat(i) * width
      if i == ticks {
        barPath.move(to: CGPoint(x: currentX, y: 0))
        barPath.addLine(to: CGPoint(x: currentX, y: barLineLayer.frame.height))
        barPath.close()
      } else if i % subdivisions == 0 {
        if showsBeatLines {
          beatPath.move(to: CGPoint(x: currentX, y: beatLineLayer.frame.height/2))
          beatPath.addLine(to: CGPoint(x: currentX, y: beatLineLayer.frame.height))
          beatPath.close()
        }
      } else if showsSubbeatLines {
        subbeatPath.move(to: CGPoint(x: currentX, y: subbeatLineLayer.frame.height/4*3))
        subbeatPath.addLine(to: CGPoint(x: currentX, y: subbeatLineLayer.frame.height))
        subbeatPath.close()
      }
    }
    // Draw measure
    barLineLayer.path = barPath.cgPath
    barLineLayer.lineWidth = barLineWidth
    barLineLayer.strokeColor = (barLineColor ?? tintColor).cgColor
    beatLineLayer.path = beatPath.cgPath
    beatLineLayer.lineWidth = beatLineWidth
    beatLineLayer.strokeColor = (beatLineColor ?? tintColor).cgColor
    subbeatLineLayer.path = subbeatPath.cgPath
    subbeatLineLayer.lineWidth = subbeatLineWidth
    subbeatLineLayer.strokeColor = (subbeatLineColor ?? tintColor).cgColor
    bottomLineLayer.path = bottomPath.cgPath
    bottomLineLayer.lineWidth = bottomLineWidth
    bottomLineLayer.strokeColor = (bottomLineColor ?? tintColor).cgColor
    CATransaction.commit()
  }
}
