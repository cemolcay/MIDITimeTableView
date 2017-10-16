//
//  MIDITimeTableGridLayer.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Draws grid for each row, bar, beat and subbeat optionally with customisable line widths and colors for `MIDITimeTableView`.
public class MIDITimeTableGridLayer: CALayer {
  /// Layer that draws row lines on it.
  private var rowLineLayer = CAShapeLayer()
  /// Layer that draws bar lines on it.
  private var barLineLayer = CAShapeLayer()
  /// Layer that draws beat lines on it.
  private var beatLineLayer = CAShapeLayer()
  /// Layer that draws subbeat lines on it.
  private var subbeatLineLayer = CAShapeLayer()

  /// Property to show row lines. Defaults true.
  public var showsRowLines = true
  /// Property to show bar lines. Defaults true.
  public var showsBarLines = true
  /// Property to show beat lines. Defaults true.
  public var showsBeatLines = true
  /// Property to show subbeat lines. Defaults true.
  public var showsSubbeatLines = true

  /// Color of row lines. Defaults dark gray.
  public var rowLineColor: UIColor = .darkGray
  /// Color of bar lines. Defaults black.
  public var barLineColor: UIColor = .black
  /// Color of beat lines. Defaults gray.
  public var beatLineColor: UIColor = .gray
  /// Color of subbeat lines. Defaults light gray.
  public var subbeatLineColor: UIColor = .lightGray

  /// Widths of row lines. Defaults 1.
  public var rowLineWidth: CGFloat = 1
  /// Widths of bar lines. Defaults 1.
  public var barLineWidth: CGFloat = 1
  /// Widths of beat lines. Defaults 0.5.
  public var beatLineWidth: CGFloat = 0.5
  /// Widths of subbeat lines. Defaults 0.5.
  public var subbeatLineWidth: CGFloat = 0.5

  /// Number of rows in the time table.
  public var rowCount: Int = 0
  /// Number of measure bars in the time table.
  public var barCount: Int = 0
  /// Number of beats in a measure.
  public var beatCount: Int = 0
  /// Height of each row in the time table.
  public var rowHeight: CGFloat = 0
  /// Width of the header cell in each row of the time table.
  public var rowHeaderWidth: CGFloat = 0
  /// Width of a measure in the time table.
  public var measureWidth: CGFloat = 0
  /// Heigth of the measure view in the time table.
  public var measureHeight: CGFloat = 0

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
    addSublayer(rowLineLayer)
    addSublayer(barLineLayer)
    addSublayer(beatLineLayer)
    addSublayer(subbeatLineLayer)
  }

  public override func layoutSublayers() {
    super.layoutSublayers()

    // Row lines
    let rowPath = UIBezierPath()
    rowPath.move(to: CGPoint(x: 0, y: measureHeight))
    rowPath.addLine(to: CGPoint(x: frame.size.width, y: measureHeight))
    rowPath.close()
    for i in 0..<rowCount {
      rowPath.move(to: CGPoint(x: 0, y: measureHeight + rowHeight + (CGFloat(i) * rowHeight)))
      rowPath.addLine(to: CGPoint(x: frame.size.width, y: measureHeight + rowHeight + (CGFloat(i) * rowHeight)))
      rowPath.close()
    }
    rowLineLayer.path = rowPath.cgPath
    rowLineLayer.strokeColor = rowLineColor.cgColor
    rowLineLayer.lineWidth = rowLineWidth
    rowLineLayer.isHidden = !showsRowLines

    // Bar lines
    let barPath = UIBezierPath()
    for i in 0..<barCount {
      barPath.move(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth), y: 0))
      barPath.addLine(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth), y: frame.height))
      barPath.close()
    }
    barPath.move(to: CGPoint(x: rowHeaderWidth + (CGFloat(barCount) * measureWidth), y: 0))
    barPath.addLine(to: CGPoint(x: rowHeaderWidth + (CGFloat(barCount) * measureWidth), y: frame.height))
    barPath.close()
    barLineLayer.path = barPath.cgPath
    barLineLayer.strokeColor = barLineColor.cgColor
    barLineLayer.lineWidth = barLineWidth
    barLineLayer.isHidden = !showsBarLines

    // Beat lines
    let beatPath = UIBezierPath()
    for i in 0..<barCount*beatCount {
      if i%beatCount == 0 { continue }
      beatPath.move(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth / CGFloat(beatCount)), y: measureHeight))
      beatPath.addLine(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth / CGFloat(beatCount)), y: frame.height))
      beatPath.close()
    }
    beatLineLayer.path = beatPath.cgPath
    beatLineLayer.strokeColor = beatLineColor.cgColor
    beatLineLayer.lineWidth = beatLineWidth
    beatLineLayer.isHidden = !showsBeatLines

    // Subbeat lines
    let subbeatPath = UIBezierPath()
    for i in 0..<barCount*beatCount*4 {
      if i%4 == 0 { continue }
      subbeatPath.move(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth / (CGFloat(beatCount) * 4)), y: measureHeight))
      subbeatPath.addLine(to: CGPoint(x: rowHeaderWidth + (CGFloat(i) * measureWidth / (CGFloat(beatCount) * 4)), y: frame.height))
      subbeatPath.close()
    }
    subbeatLineLayer.path = subbeatPath.cgPath
    subbeatLineLayer.strokeColor = subbeatLineColor.cgColor
    subbeatLineLayer.lineWidth = subbeatLineWidth
    subbeatLineLayer.isHidden = !showsSubbeatLines

    // Layout grids
    rowLineLayer.frame = bounds
    barLineLayer.frame = bounds
    beatLineLayer.frame = bounds
    subbeatLineLayer.frame = bounds
  }
}
