//
//  MIDITimeTableView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

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
}

public enum MIDITimeTableSubbeat {
  case empty
  case midi(data: Any)
}

public struct MIDITimeTableBeat {
  public var subbeats: [MIDITimeTableSubbeat] = [.empty, .empty, .empty, .empty]
}

public struct MIDITimeTableBar {
  public var beats: [MIDITimeTableBeat]

  public init(timeSignature: MIDITimeTableTimeSignature) {
    beats = (0..<timeSignature.beats).map({ _ in MIDITimeTableBeat() })
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
      barLayer.barNumber = i
      barLayer.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: frame.height)
      layer.addSublayer(barLayer)
      barLayers.append(barLayer)
    }
  }
}

public class MIDITimeTableCellView: UIView {

}

public class MIDITimeTableHeaderCellView: UIView {

}

public protocol MIDITimeTableViewDataSource: class {
  func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int
  func numberOfBars(in midiTimeTableView: MIDITimeTableView) -> Int
  func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature
//  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, cellForRow: Int, position: MIDITimeTablePosition) -> MIDITimeTableCellView
//  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, headerCellForRow: Int) -> MIDITimeTableHeaderCellView?
}

public protocol MIDITimeTableViewDelegate: class {
//  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEditCellAtRow: Int, position: MIDITimeTablePosition, newRow: Int, newPosition: MIDITimeTablePosition, newDuration: MIDITimeTableDuration)
//  func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDeleteCellAtRow: Int, position: MIDITimeTablePosition)
}

public class MIDITimeTableView: UIScrollView {
  public var showsMeasure: Bool = true
  public var showsHeaders: Bool = true

  public override func layoutSubviews() {
    super.layoutSubviews()
  }

  public func reloadData() {

  }
}
