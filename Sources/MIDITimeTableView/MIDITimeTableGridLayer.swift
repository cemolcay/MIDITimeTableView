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
  /// Number of grid subdivisions per beat, used for drawing subbeat lines. Defaults 4.
  public var snapResolution: Int = 4
  /// Height of each row in the time table.
  public var rowHeight: CGFloat = 0
  /// Width of the header cell in each row of the time table.
  public var rowHeaderWidth: CGFloat = 0
  /// Width of a measure in the time table.
  public var measureWidth: CGFloat = 0
  /// Heigth of the measure view in the time table.
  public var measureHeight: CGFloat = 0
  /// The rect (in this layer's own coordinate space, i.e. content coordinates) to draw grid lines
  /// within. Everything outside it is skipped entirely rather than built and clipped visually, so
  /// the number of line segments this layer builds tracks what's on screen, not the size of the
  /// whole document. The owning `MIDITimeTableView` keeps this in sync with its visible viewport
  /// (plus a small overscan margin) on every layout pass, including on scroll. Defaults to a large
  /// placeholder so a layer used standalone, before anything sets a real value, still draws.
  ///
  /// Named distinctly from `CALayer`'s own (unrelated, read-only) `visibleRect` to avoid
  /// colliding with it.
  public var virtualizationRect = CGRect(x: 0, y: 0, width: 100_000, height: 100_000)

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

    // Clip every path to `virtualizationRect` instead of spanning the whole (potentially huge)
    // content, so the number of line segments built here tracks what's on screen, not document size.
    let clipMinX = max(0, virtualizationRect.minX)
    let clipMaxX = min(frame.size.width, virtualizationRect.maxX)
    let clipMinY = max(0, virtualizationRect.minY)
    let clipMaxY = min(frame.size.height, virtualizationRect.maxY)
    guard clipMaxX > clipMinX, clipMaxY > clipMinY else {
      // Nothing intersects the visible rect (e.g. not laid out yet) — draw nothing rather than
      // fall through to `CGFloat.nan`-poisoned ranges below.
      rowLineLayer.path = nil
      barLineLayer.path = nil
      beatLineLayer.path = nil
      subbeatLineLayer.path = nil
      return
    }

    // Row lines
    let rowPath = UIBezierPath()
    let rowLineYs = [measureHeight] + (0..<rowCount).map { measureHeight + rowHeight + (CGFloat($0) * rowHeight) }
    for y in rowLineYs where y >= clipMinY && y <= clipMaxY {
      rowPath.move(to: CGPoint(x: clipMinX, y: y))
      rowPath.addLine(to: CGPoint(x: clipMaxX, y: y))
      rowPath.close()
    }
    rowLineLayer.path = rowPath.cgPath
    rowLineLayer.strokeColor = rowLineColor.cgColor
    rowLineLayer.lineWidth = rowLineWidth
    rowLineLayer.isHidden = !showsRowLines

    // Bar lines. `barCount + 1` lines total: one at each bar boundary, plus the trailing edge.
    let barPath = UIBezierPath()
    let barRange = Self.visibleIndexRange(clipMinX: clipMinX, clipMaxX: clipMaxX, offset: rowHeaderWidth, unitWidth: measureWidth, count: barCount + 1)
    for i in barRange {
      let x = rowHeaderWidth + (CGFloat(i) * measureWidth)
      barPath.move(to: CGPoint(x: x, y: clipMinY))
      barPath.addLine(to: CGPoint(x: x, y: clipMaxY))
      barPath.close()
    }
    barLineLayer.path = barPath.cgPath
    barLineLayer.strokeColor = barLineColor.cgColor
    barLineLayer.lineWidth = barLineWidth
    barLineLayer.isHidden = !showsBarLines

    // Beat lines. Beat ticks only start below the measure header.
    let beatPath = UIBezierPath()
    let beatLineMinY = max(measureHeight, clipMinY)
    if beatCount > 0, beatLineMinY < clipMaxY {
      let beatWidth = measureWidth / CGFloat(beatCount)
      let beatRange = Self.visibleIndexRange(clipMinX: clipMinX, clipMaxX: clipMaxX, offset: rowHeaderWidth, unitWidth: beatWidth, count: barCount * beatCount)
      for i in beatRange where i % beatCount != 0 {
        let x = rowHeaderWidth + (CGFloat(i) * beatWidth)
        beatPath.move(to: CGPoint(x: x, y: beatLineMinY))
        beatPath.addLine(to: CGPoint(x: x, y: clipMaxY))
        beatPath.close()
      }
    }
    beatLineLayer.path = beatPath.cgPath
    beatLineLayer.strokeColor = beatLineColor.cgColor
    beatLineLayer.lineWidth = beatLineWidth
    beatLineLayer.isHidden = !showsBeatLines

    // Subbeat lines
    let subbeatPath = UIBezierPath()
    let subdivisions = max(1, snapResolution)
    if beatCount > 0, beatLineMinY < clipMaxY {
      let subbeatWidth = measureWidth / (CGFloat(beatCount) * CGFloat(subdivisions))
      let subbeatRange = Self.visibleIndexRange(clipMinX: clipMinX, clipMaxX: clipMaxX, offset: rowHeaderWidth, unitWidth: subbeatWidth, count: barCount * beatCount * subdivisions)
      for i in subbeatRange where i % subdivisions != 0 {
        let x = rowHeaderWidth + (CGFloat(i) * subbeatWidth)
        subbeatPath.move(to: CGPoint(x: x, y: beatLineMinY))
        subbeatPath.addLine(to: CGPoint(x: x, y: clipMaxY))
        subbeatPath.close()
      }
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

  /// Returns the index range (clamped to `0..<count`) of lines at `offset + i * unitWidth` that
  /// intersect `[clipMinX, clipMaxX]`, with a one-unit margin on each side so a line sitting
  /// exactly at the clip edge is never dropped. Used to bound each grid tier's loop to only the
  /// visible span instead of iterating the whole document.
  private static func visibleIndexRange(clipMinX: CGFloat, clipMaxX: CGFloat, offset: CGFloat, unitWidth: CGFloat, count: Int) -> Range<Int> {
    guard unitWidth > 0, count > 0 else { return 0..<0 }
    let lower = max(0, Int(floor((clipMinX - offset) / unitWidth)) - 1)
    let upper = min(count, Int(ceil((clipMaxX - offset) / unitWidth)) + 1)
    guard upper > lower else { return 0..<0 }
    return lower..<upper
  }
}
