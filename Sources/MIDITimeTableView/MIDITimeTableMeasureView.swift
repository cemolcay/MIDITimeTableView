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
  /// Property to show beat tick lines. Defaults true.
  public var showsBeatLines = true { didSet { if oldValue != showsBeatLines { setNeedsLayout() } } }
  /// Property to show subbeat tick lines. Defaults true.
  public var showsSubbeatLines = true { didSet { if oldValue != showsSubbeatLines { setNeedsLayout() } } }
  /// Property to show the horizontal bottom line. Defaults true.
  public var showsBottomLine = true { didSet { if oldValue != showsBottomLine { setNeedsLayout() } } }
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
  /// The x-range (in this view's own coordinate space) of bars to realize layers for. Bars
  /// outside it are freed into a reuse pool instead of laid out, so the number of live
  /// `MIDITimeTableMeasureLayer`s tracks what's on screen rather than the whole timeline. The
  /// owning `MIDITimeTableView` keeps this in sync with the visible viewport (plus a small
  /// overscan margin) on every layout pass, including scroll. Defaults to a large placeholder so
  /// a view used standalone, before anything sets a real value, still shows its bars.
  public var virtualizationRect = CGRect(x: 0, y: 0, width: 100_000, height: 100_000)

  /// Realized bar layers keyed by (1-based) bar number.
  private var barLayersByNumber = [Int: MIDITimeTableMeasureLayer]()
  /// Bar layers freed because their bar scrolled out of `virtualizationRect`, kept around to be reused
  /// for a bar scrolling in instead of being deallocated and recreated.
  private var pooledBarLayers = [MIDITimeTableMeasureLayer]()

  /// Forces every bar layer to be rebuilt from scratch on the next layout pass. You shouldn't
  /// normally need this — `barCount`/`beatCount`/`snapResolution`/`showsBarNumbers`/tick visibility
  /// properties already trigger a refresh when they actually change — but it's kept as a manual
  /// escape hatch.
  public func update() {
    setNeedsLayout()
  }

  open override func layoutSubviews() {
    super.layoutSubviews()

    guard barCount > 0 else {
      barLayersByNumber.values.forEach({ $0.removeFromSuperlayer() })
      barLayersByNumber = [:]
      pooledBarLayers.forEach({ $0.removeFromSuperlayer() })
      pooledBarLayers = []
      return
    }
    let width = frame.width / CGFloat(barCount)
    guard width > 0 else { return }

    // Only the bars intersecting `virtualizationRect` (with a one-bar margin on each side) get a
    // realized layer; a bar just outside it is freed into `pooledBarLayers` for reuse rather
    // than kept alive regardless of document length.
    let lowerBarIndex = max(0, Int(floor(virtualizationRect.minX / width)) - 1)
    let upperBarIndex = min(barCount, Int(ceil(virtualizationRect.maxX / width)) + 1)
    let visibleIndices = lowerBarIndex < upperBarIndex ? Array(lowerBarIndex..<upperBarIndex) : []
    let visibleNumbers = Set(visibleIndices.map { $0 + 1 })

    // Recycle bars that scrolled out of view.
    for (number, barLayer) in barLayersByNumber where !visibleNumbers.contains(number) {
      barLayer.removeFromSuperlayer()
      pooledBarLayers.append(barLayer)
      barLayersByNumber.removeValue(forKey: number)
    }

    // Realize bars now in (or newly within range of) the viewport, reusing a pooled layer
    // instance where one's available instead of allocating a fresh one.
    for i in visibleIndices {
      let number = i + 1
      let barLayer: MIDITimeTableMeasureLayer
      if let existing = barLayersByNumber[number] {
        barLayer = existing
      } else if let reused = pooledBarLayers.popLast() {
        barLayer = reused
      } else {
        barLayer = MIDITimeTableMeasureLayer()
      }
      if barLayer.superlayer !== layer {
        layer.addSublayer(barLayer)
      }
      barLayersByNumber[number] = barLayer

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      barLayer.tintColor = tintColor
      barLayer.showsBarNumber = showsBarNumbers
      barLayer.showsBeatLines = showsBeatLines
      barLayer.showsSubbeatLines = showsSubbeatLines
      barLayer.showsBottomLine = showsBottomLine
      barLayer.barLineColor = barLineColor
      barLayer.beatLineColor = beatLineColor
      barLayer.subbeatLineColor = subbeatLineColor
      barLayer.bottomLineColor = bottomLineColor
      barLayer.barLineWidth = barLineWidth
      barLayer.beatLineWidth = beatLineWidth
      barLayer.subbeatLineWidth = subbeatLineWidth
      barLayer.bottomLineWidth = bottomLineWidth
      barLayer.beatCount = beatCount
      barLayer.snapResolution = snapResolution
      barLayer.displayScale = traitCollection.displayScale
      barLayer.barNumber = number
      barLayer.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: frame.height)
      // A reused layer whose frame size didn't change wouldn't otherwise redraw its content (its
      // own properties have no `didSet`), so ask explicitly.
      barLayer.setNeedsLayout()
      CATransaction.commit()
    }
  }
}
