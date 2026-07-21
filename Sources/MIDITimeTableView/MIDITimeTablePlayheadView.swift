//
//  MIDITimeTablePlayheadView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 23.11.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Delegate that informs about playhead is going to move.
public protocol MIDITimeTablePlayheadViewDelegate: AnyObject {
  /// Delegate method that should update playhead's position based on pan gesture translation in timetable view.
  ///
  /// - Parameters:
  ///   - playheadView: Playhead that panning.
  ///   - panGestureRecognizer: Pan gesture that pans playhead.
  func playheadView(_ playheadView: MIDITimeTablePlayheadView, didPan panGestureRecognizer: UIPanGestureRecognizer)
}

public enum MIDITimeTablePlayheadShape {
  /// Down arrow shape for showing or adjusting current time on the timetable.
  case playhead
  /// Left arrow shape for adjusting range of the playable area on the timetable.
  case range
}

/// Draws a triangle, movable playhead that customisable with a custom shape layer or an image.
public class MIDITimeTablePlayheadView: UIView {
  /// Current position on timetable. Based on beats.
  @objc public dynamic var position: Double = 0.0 { didSet{ updatePosition() }}
  /// MIDITimeTableMeasureView's width that used in layout playhead in timetable.
  public var measureBeatWidth: CGFloat = 0.0 { didSet{ updatePosition() }}
  /// MIDITimeTableMeasureView's height that used in layout playhead in timetable.
  public var measureHeight: CGFloat = 0.0 { didSet{ updatePosition() }}
  /// MIDITimeTableHeaderCellView's width that used in layout playhead in timetable.
  public var rowHeaderWidth: CGFloat = 0.0 { didSet{ updatePosition() }}

  /// Optional image for playhead instead of default triangle shape layer.
  public var image: UIImage? { didSet{ updateImage() }}
  /// Shape layer that draws triangle playhead shape. You can change the default shape.
  public var shapeLayer = CAShapeLayer() { didSet{ setNeedsLayout() } }
  /// Shape of the playhead triangle.
  public var shapeType: MIDITimeTablePlayheadShape = .range

  /// Playhead's guide line color that draws on timetable.
  public var lineColor: UIColor = .white { didSet{ setNeedsLayout() }}
  /// Playhead's guide line height that draws on timetable. It's best to match timetable's content height.
  public var lineHeight: CGFloat = 0 { didSet{ setNeedsLayout() }}
  /// Playhead's guide line width that draws on timetable. Defaults to a device hairline (one
  /// physical pixel). The default is refreshed for the actual display scale once the view enters a
  /// window (see `didMoveToWindow`); an explicit value assigned by the caller always wins.
  public var lineWidth: CGFloat = 1 / UITraitCollection.current.displayScale {
    didSet {
      if !isRefreshingDefaultLineWidth { usesDefaultLineWidth = false }
      setNeedsLayout()
    }
  }
  /// Tracks whether `lineWidth` still holds its trait-derived default, so the hairline can be
  /// refreshed for the real display scale without clobbering a caller-supplied value.
  private var usesDefaultLineWidth = true
  /// Guards the internal refresh assignment so it doesn't mark `lineWidth` as caller-overridden.
  private var isRefreshingDefaultLineWidth = false
  /// Line layer that draws playhead's position guide on timetable.
  private var lineLayer = CALayer()
  /// Optional image view that initilizes if an image assings.
  private var imageView: UIImageView?
  /// Delegate of playhead.
  public weak var delegate: MIDITimeTablePlayheadViewDelegate?
  /// The view for panning.
  private var panningView = UIView()
  /// The hit are offset for panning.
  public var panningOffset: CGFloat = 20

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  public convenience init() {
    self.init(frame: .zero)
  }

  private func commonInit() {
    panningView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(pan:))))
    addSubview(panningView)
    layer.addSublayer(lineLayer)
    layer.addSublayer(shapeLayer)
  }

  // Lifecycle

  public override func layoutSubviews() {
    super.layoutSubviews()
    panningView.frame = CGRect(x: -panningOffset, y: -panningOffset, width: frame.size.width + (panningOffset * 2), height: frame.size.height + (panningOffset * 2))
    lineLayer.frame.size = CGSize(width: lineWidth, height: lineHeight + (frame.height / 2))
    lineLayer.frame.origin.y = frame.height - (frame.height / 2)
    lineLayer.position.x = frame.width / 2
    lineLayer.backgroundColor = lineColor.cgColor
    imageView?.frame = CGRect(origin: .zero, size: frame.size)
    shapeLayer.frame = CGRect(origin: .zero, size: frame.size)
    drawShapeLayer()
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    // Now attached to a real screen, so refresh the hairline default to that screen's scale. Only
    // touches the value while it's still the default; a caller-set width is left alone.
    guard usesDefaultLineWidth, window != nil else { return }
    let hairline = 1 / traitCollection.displayScale
    guard lineWidth != hairline else { return }
    isRefreshingDefaultLineWidth = true
    lineWidth = hairline
    isRefreshingDefaultLineWidth = false
  }

  public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if !isUserInteractionEnabled || isHidden || alpha == 0 {
      return nil
    }

    for subview in subviews.reversed() {
      let subPoint = subview.convert(point, from: self)
      if let result = subview.hitTest(subPoint, with: event) {
        return result
      }
    }

    return nil
  }

  private func updatePosition() {
    frame = CGRect(
      x: rowHeaderWidth + (CGFloat(position) * measureBeatWidth) - (frame.size.width / 2),
      y: 1,
      width: measureHeight,
      height: measureHeight - 1)
  }

  private func updateImage() {
    if let image = image {
      let imageView = UIImageView(image: image)
      addSubview(imageView)
      self.imageView = imageView
    } else {
      imageView?.removeFromSuperview()
      imageView = nil
    }
  }

  private func drawShapeLayer() {
    let cornerRadius: CGFloat = 1
    let path = CGMutablePath()

    switch shapeType {
    case .playhead:
      let point1 = CGPoint(x: 0, y: 0)
      let point2 = CGPoint(x: 0, y: frame.size.height / 2)
      let point3 = CGPoint(x: frame.size.width / 2, y: frame.size.height)
      let point4 = CGPoint(x: frame.size.width, y: frame.size.height / 2)
      let point5 = CGPoint(x: frame.size.width, y: 0)

      path.move(to: point2)
      path.addArc(tangent1End: point2, tangent2End: point3, radius: cornerRadius)
      path.addArc(tangent1End: point3, tangent2End: point4, radius: cornerRadius)
      path.addArc(tangent1End: point4, tangent2End: point5, radius: cornerRadius)
      path.addArc(tangent1End: point5, tangent2End: point1, radius: cornerRadius)
      path.addArc(tangent1End: point1, tangent2End: point2, radius: cornerRadius)

    case .range:
      let point1 = CGPoint(x: frame.size.width, y: 0)
      let point2 = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
      let point3 = CGPoint(x: frame.size.width, y: frame.size.height)

      path.move(to: point2)
      path.addArc(tangent1End: point2, tangent2End: point3, radius: cornerRadius)
      path.addArc(tangent1End: point3, tangent2End: point1, radius: cornerRadius)
      path.addArc(tangent1End: point1, tangent2End: point2, radius: cornerRadius)
    }

    shapeLayer.path = path
    shapeLayer.shadowPath = path
    shapeLayer.fillColor = tintColor.cgColor
    shapeLayer.shadowColor = UIColor.black.cgColor
    shapeLayer.shadowRadius = 1
  }

  @objc internal func didPan(pan: UIPanGestureRecognizer) {
    delegate?.playheadView(self, didPan: pan)
  }
}
