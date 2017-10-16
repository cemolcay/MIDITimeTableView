//
//  MIDITimeTableView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

public protocol MIDITimeTableViewDataSource: class {
  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowAt index: Int) -> MIDITimeTableRowData
}

public protocol MIDITimeTableViewDelegate: class {
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEditCellAt row: Int, index: Int, newCellRow: Int, newCellPosition: Double, newCellDuration: Double)
  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDeleteCellAt row: Int, index: Int)
  func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
  func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
  func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat
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
  private var editingCellRow: Int?

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

    var duration = 0.0
    for i in 0..<(dataSource?.numberOfRows(in: self) ?? 0) {
      guard let row = dataSource?.midiTimeTableView(self, rowAt: i) else { continue }
      duration = row.duration > duration ? row.duration : duration
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

    measureView.barCount = Int(ceil(duration / Double(measureView.beatCount)))
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

    if case .began = pan.state {
      editingCellRow = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
    }

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

    if case .ended = pan.state {
      didEditCell(midiTimeTableCellView)
    }
  }

  public func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubview(toFront: midiTimeTableCellView)

    if case .began = pan.state {
      editingCellRow = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
    }

    if translation.x > subbeatWidth, midiTimeTableCellView.frame.maxX < contentSize.width - subbeatWidth { // Increase
      midiTimeTableCellView.frame.size.width += subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -subbeatWidth, midiTimeTableCellView.frame.width > subbeatWidth { // Decrease
      midiTimeTableCellView.frame.size.width -= subbeatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    if case .ended = pan.state {
      didEditCell(midiTimeTableCellView)
    }
  }

  public func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView) {
    let row = Int((midiTimeTableCellView.frame.minY - measureHeight) / rowHeight)
    guard let index = cellViews[row].index(of: midiTimeTableCellView) else { return }
    timeTableDelegate?.midiTimeTableView(self, didDeleteCellAt: row, index: index)
  }

  private func didEditCell(_ cellView: MIDITimeTableCellView) {
    guard let row = editingCellRow, let index = cellViews[row].index(of: cellView) else { return }
    let newCellPosition = Double(cellView.frame.minX - headerCellWidth) / Double(beatWidth)
    let newCellDuration = Double(cellView.frame.size.width / beatWidth)
    let newCellRow = Int((cellView.frame.minY - measureHeight) / rowHeight)

    timeTableDelegate?.midiTimeTableView(
      self,
      didEditCellAt: row,
      index: index,
      newCellRow: newCellRow,
      newCellPosition: newCellPosition,
      newCellDuration: newCellDuration)

    editingCellRow = nil
    if row != newCellRow {
      reloadData()
    }
  }
}
