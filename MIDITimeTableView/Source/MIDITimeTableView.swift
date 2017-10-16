//
//  MIDITimeTableView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit
import ALKit

public enum MIDITimeTableNoteValue: Int {
  case whole = 1
  case half = 2
  case quarter = 4
  case eighth = 8
  case sixteenth = 16
  case thirtysecond = 32
  case sixtyfourth = 64
}

public struct MIDITimeTableTimeSignature {
  public var beats: Int
  public var noteValue: MIDITimeTableNoteValue

  public init(beats: Int, noteValue: MIDITimeTableNoteValue) {
    self.beats = beats
    self.noteValue = noteValue
  }
}

public class MIDITimeTableMeasureLayer: CALayer {
  public var textLayer = CATextLayer()
  public var shapeLayer = CAShapeLayer()
  public var showsBarNumber = true
  public var beatCount = 4
  public var barNumber = 1

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

  public override func layoutSublayers() {
    super.layoutSublayers()
    // Text layer
    textLayer.frame = CGRect(x: 2, y: 0, width: frame.width, height: frame.height/2)
    textLayer.fontSize = frame.height/2
    textLayer.foregroundColor = UIColor.black.cgColor
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.alignmentMode = kCAAlignmentLeft
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
    shapeLayer.strokeColor = UIColor.gray.cgColor
  }
}

public class MIDITimeTableMeasureView: UIView {
  public var barCount: Int = 1
  public var beatCount: Int = 4
  public var barLayers = [MIDITimeTableMeasureLayer]()
  public var showsBarNumbers = true

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

public protocol MIDITimeTableCellViewDelegate: class {
  func midiTimeTableCellViewDidMove(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer)
  func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer)
}

public class MIDITimeTableCellView: UIView {
  private var resizeView = UIView()
  private var resizeViewWidthConstraint: NSLayoutConstraint?
  public var resizePanThreshold: CGFloat = 10
  public weak var delegate: MIDITimeTableCellViewDelegate?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    addSubview(resizeView)
    resizeView.translatesAutoresizingMaskIntoConstraints = false
    resizeView.pinRight(to: self)
    resizeView.fillVertical(to: self)
    resizeViewWidthConstraint = NSLayoutConstraint(
      item: resizeView,
      attribute: .width,
      relatedBy: .equal,
      toItem: nil,
      attribute: .notAnAttribute,
      multiplier: 1,
      constant: resizePanThreshold)
    resizeView.addConstraint(resizeViewWidthConstraint!)

    let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(pan:)))
    addGestureRecognizer(moveGesture)

    let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(didResize(pan:)))
    resizeView.addGestureRecognizer(resizeGesture)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    resizeViewWidthConstraint?.constant = resizePanThreshold
  }

  @objc public func didMove(pan: UIPanGestureRecognizer) {
    delegate?.midiTimeTableCellViewDidMove(self, pan: pan)
  }

  @objc public func didResize(pan: UIPanGestureRecognizer) {
    delegate?.midiTimeTableCellViewDidResize(self, pan: pan)
  }
}

public class MIDITimeTableHeaderCellView: UIView {

}

public struct MIDITimeTableCellData {
  public var data: Any
  public var position: Double
  public var duration: Double

  public init(data: Any, position: Double, duration: Double) {
    self.data = data
    self.position = position
    self.duration = duration
  }
}

public struct MIDITimeTableRowData {
  public var cells: [MIDITimeTableCellData]
  public var headerCellView: MIDITimeTableHeaderCellView
  public var cellView: (MIDITimeTableCellData) -> MIDITimeTableCellView

  public var maxPosition: Double {
    var max = 0.0
    for cell in cells {
      let position = cell.position + cell.duration
      max = position > max ? position : max
    }
    return max
  }

  public init(cells: [MIDITimeTableCellData], headerCellView: MIDITimeTableHeaderCellView, cellView: @escaping (MIDITimeTableCellData) -> MIDITimeTableCellView) {
    self.cells = cells
    self.headerCellView = headerCellView
    self.cellView = cellView
  }
}

public protocol MIDITimeTableViewDataSource: class {
  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowAt index: Int) -> MIDITimeTableRowData
}

public protocol MIDITimeTableViewDelegate: class {
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEditCellAtRow: Int, index: Int, newCellRow: Int, newCellData: MIDITimeTableCellData)
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDeleteCellAtRow: Int, index: Int)
  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
}

public class MIDITimeTableGridLayer: CALayer {
  private var rowLineLayer = CAShapeLayer()
  private var barLineLayer = CAShapeLayer()
  private var beatLineLayer = CAShapeLayer()
  private var subbeatLineLayer = CAShapeLayer()

  public var showsRowLines = true
  public var showsBarLines = true
  public var showsBeatLines = true
  public var showsSubbeatLines = true

  public var rowLineColor: UIColor = .darkGray
  public var barLineColor: UIColor = .black
  public var beatLineColor: UIColor = .gray
  public var subbeatLineColor: UIColor = .lightGray

  public var rowLineWidth: CGFloat = 1
  public var barLineWidth: CGFloat = 1
  public var beatLineWidth: CGFloat = 0.5
  public var subbeatLineWidth: CGFloat = 0.5

  public var rowCount: Int = 0
  public var barCount: Int = 0
  public var rowHeight: CGFloat = 0
  public var rowHeaderWidth: CGFloat = 0
  public var measureWidth: CGFloat = 0
  public var measureHeight: CGFloat = 0
  public var beatCount: Int = 0

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

public class MIDITimeTableView: UIScrollView, MIDITimeTableCellViewDelegate {
  public var showsMeasure: Bool = true
  public var showsHeaders: Bool = true
  public var showsGrid: Bool = true

  public var maxMeasureWidth: CGFloat = 500
  public var minMeasureWidth: CGFloat = 100
  public var measureWidth: CGFloat = 200 {
    didSet {
      if measureWidth >= maxMeasureWidth {
        measureWidth = maxMeasureWidth
      } else if measureWidth <= minMeasureWidth {
        measureWidth = minMeasureWidth
      }
    }
  }

  public private(set) var gridLayer = MIDITimeTableGridLayer()
  public private(set) var measureView = MIDITimeTableMeasureView()
  private var rowHeaderCellViews = [MIDITimeTableHeaderCellView]()
  private var cellViews = [[MIDITimeTableCellView]]()

  public weak var dataSource: MIDITimeTableViewDataSource?
  public weak var timeTableDelegate: MIDITimeTableViewDelegate?

  private var rowHeight: CGFloat {
    return timeTableDelegate?.midiTimeTableViewHeightForRows(self) ?? 60
  }

  private var measureHeight: CGFloat {
    return showsMeasure ? timeTableDelegate?.midiTimeTableViewHeightForMeasureView(self) ?? 30 : 0
  }

  private var headerCellWidth: CGFloat {
    return showsHeaders ? timeTableDelegate?.midiTimeTableViewWidthForRowHeaderCells(self) ?? 120 : 0
  }

  private var beatWidth: CGFloat {
    return measureWidth / CGFloat(measureView.beatCount)
  }

  private var subbeatWidth: CGFloat {
    return beatWidth / 4
  }

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    addSubview(measureView)
    layer.insertSublayer(gridLayer, at: 0)
    let pinch = UIPinchGestureRecognizer(
      target: self,
      action: #selector(didPinch(pinch:)))
    addGestureRecognizer(pinch)
  }

  // MARK: Pinch Gesture

  private var lastScale: CGFloat = 0
  @objc func didPinch(pinch: UIPinchGestureRecognizer) {
    measureWidth += (lastScale < pinch.scale ? 1 : -1) * pinch.scale
    lastScale = pinch.scale
    setNeedsLayout()
  }

  // MARK: Lifecycle

  public override func layoutSubviews() {
    super.layoutSubviews()

    for (index, row) in rowHeaderCellViews.enumerated() {
      row.frame = CGRect(
        x: 0,
        y: measureHeight + (CGFloat(index) * rowHeight),
        width: headerCellWidth,
        height: rowHeight)
    }

    var maxPosition = 0.0
    for i in 0..<(dataSource?.numberOfRows(in: self) ?? 0) {
      guard let row = dataSource?.midiTimeTableView(self, rowAt: i) else { continue }
      maxPosition = row.maxPosition > maxPosition ? row.maxPosition : maxPosition
      for (index, cell) in row.cells.enumerated() {
        let cellView = cellViews[i][index]
        let startX = beatWidth * CGFloat(cell.position)
        let width = beatWidth * CGFloat(cell.duration)
        cellView.frame = CGRect(
          x: headerCellWidth + startX,
          y: measureHeight + (CGFloat(i) * rowHeight),
          width: width,
          height: rowHeight)
      }
    }

    measureView.barCount = Int(ceil(maxPosition / Double(measureView.beatCount)))
    measureView.frame = CGRect(
      x: headerCellWidth,
      y: 0,
      width: CGFloat(measureView.barCount) * measureWidth,
      height: measureHeight)

    contentSize = CGSize(
      width: headerCellWidth + measureView.frame.width,
      height: measureView.frame.height + (rowHeight * CGFloat(rowHeaderCellViews.count)))

    gridLayer.rowCount = rowHeaderCellViews.count
    gridLayer.barCount = measureView.barCount
    gridLayer.rowHeight = rowHeight
    gridLayer.rowHeaderWidth = headerCellWidth
    gridLayer.measureWidth = measureWidth
    gridLayer.measureHeight = measureHeight
    gridLayer.beatCount = measureView.beatCount
    gridLayer.isHidden = !showsGrid
    gridLayer.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: frame.size.height)
  }

  public func reloadData() {
    rowHeaderCellViews.forEach({ $0.removeFromSuperview() })
    rowHeaderCellViews = []
    cellViews.flatMap({ $0 }).forEach({ $0.removeFromSuperview() })
    cellViews = []

    let numberOfRows = dataSource?.numberOfRows(in: self) ?? 0
    let timeSignature = dataSource?.timeSignature(of: self) ?? MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    measureView.beatCount = timeSignature.beats

    for i in 0..<numberOfRows {
      guard let row = dataSource?.midiTimeTableView(self, rowAt: i) else { continue }
      let rowHeaderCell = row.headerCellView
      rowHeaderCellViews.append(rowHeaderCell)
      addSubview(rowHeaderCell)

      var cells = [MIDITimeTableCellView]()
      for cell in row.cells {
        let cellView = row.cellView(cell)
        cellView.delegate = self
        cells.append(cellView)
        addSubview(cellView)
      }
      cellViews.append(cells)
    }
  }

  // MARK: MIDITimeTableCellViewDelegate

  public func midiTimeTableCellViewDidMove(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    // Horizontal move
    if translation.x > subbeatWidth, midiTimeTableCellView.frame.maxX < contentSize.width {
      midiTimeTableCellView.center = CGPoint(
        x: midiTimeTableCellView.center.x + subbeatWidth,
        y: midiTimeTableCellView.center.y)
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, midiTimeTableCellView.frame.minX > headerCellWidth {
      midiTimeTableCellView.center = CGPoint(
        x: midiTimeTableCellView.center.x - subbeatWidth,
        y: midiTimeTableCellView.center.y)
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    // Vertical move
    if translation.y > rowHeight, midiTimeTableCellView.frame.maxY < measureHeight + (rowHeight * CGFloat(cellViews.count)) {
      midiTimeTableCellView.center = CGPoint(
        x: midiTimeTableCellView.center.x,
        y: midiTimeTableCellView.center.y + rowHeight)
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    } else if translation.y < -rowHeight, midiTimeTableCellView.frame.minY > measureHeight {
      midiTimeTableCellView.center = CGPoint(
        x: midiTimeTableCellView.center.x,
        y: midiTimeTableCellView.center.y - rowHeight)
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    if translation.x > subbeatWidth, midiTimeTableCellView.frame.maxX < contentSize.width - subbeatWidth { // Increase
      midiTimeTableCellView.frame.size.width += subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, midiTimeTableCellView.frame.width > subbeatWidth { // Decrease
      midiTimeTableCellView.frame.size.width -= subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }
  }
}
