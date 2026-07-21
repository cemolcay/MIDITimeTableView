//
//  ViewController.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit
import MIDITimeTableView

class HeaderCellView: MIDITimeTableHeaderCellView {
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override init(reuseIdentifier: String? = nil) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    convenience init(title: String) {
        self.init(reuseIdentifier: "Header")
        titleLabel.text = title
    }
    
    func commonInit() {
        addSubview(titleLabel)
        backgroundColor = UIColor(red: 36.0/255.0, green: 40.0/255.0, blue: 41.0/255.0, alpha: 1)
        titleLabel.textColor = UIColor(red: 216.0/255.0, green: 214.0/255.0, blue: 217.0/255.0, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(origin: .zero, size: frame.size)
    }
}

class CellView: MIDITimeTableCellView {
    var titleLabel = UILabel()
    var selectedBorderColor: UIColor = .yellow
    var defaultBorderColor: UIColor = .black
    
    override var isSelected: Bool {
        didSet {
            titleLabel.layer.borderColor = (isSelected ? selectedBorderColor : defaultBorderColor).cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override init(reuseIdentifier: String? = nil) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    convenience init(title: String) {
        self.init(reuseIdentifier: "Cell")
        titleLabel.text = title
    }
    
    func commonInit() {
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.backgroundColor = UIColor(red: 16.0/255.0, green: 92.0/255.0, blue: 28.0/255.0, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.layer.masksToBounds = true
        titleLabel.layer.borderColor = UIColor.black.cgColor
        titleLabel.layer.borderWidth = 1
        titleLabel.layer.cornerRadius = 5
        customMenuItems = [
            MIDITimeTableCellViewCustomMenuItem(
                title: "Custom Menu Item",
                action: #selector(didPressCustomMenuItem))
        ]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(origin: .zero, size: frame.size)
    }
    
    /// Applies a cell's data to this view, whether it's freshly created or being dequeued.
    func configure(with cellData: CellData) {
        titleLabel.text = cellData.title
    }
    
    @objc func didPressCustomMenuItem() {
        print("custom menu item pressed")
    }
}

struct CellData: MIDITimeTableCellRepresentable {
    var id: MIDITimeTableCellID
    var title: String
    var position: Double
    var duration: Double
    
    init(id: MIDITimeTableCellID = MIDITimeTableCellID(), title: String, position: Double, duration: Double) {
        self.id = id
        self.title = title
        self.position = position
        self.duration = duration
    }
}

struct RowData: MIDITimeTableRowRepresentable {
    var title: String
    var cells: [CellData]
}

struct History: MIDITimeTableHistoryRepresentable {
    var history = MIDITimeTableHistoryStack<[RowData]>()
}

class ViewController: UIViewController, MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
    @IBOutlet weak var timeTableView: MIDITimeTableView?
    @IBOutlet weak var undoButton: UIBarButtonItem?
    @IBOutlet weak var redoButton: UIBarButtonItem?
    
    var rows: [RowData] = [
        RowData(
            title: "Chords",
            cells: [
                CellData(title: "C7", position: 0, duration: 4),
                CellData(title: "Dm7", position: 4, duration: 4),
                CellData(title: "G7b5", position: 8, duration: 4),
                CellData(title: "C7", position: 12, duration: 4),
            ]),
        
        RowData(
            title: "Bass",
            cells: [
                CellData(title: "C", position: 0, duration: 1),
                CellData(title: "D", position: 4, duration: 1),
                CellData(title: "G", position: 8, duration: 1),
                CellData(title: "C", position: 12, duration: 1),
            ]),
        
        RowData(
            title: "Melody",
            cells: [
                CellData(title: "C", position: 0, duration: 1),
                CellData(title: "C", position: 1, duration: 1),
                CellData(title: "C", position: 2, duration: 1),
                CellData(title: "C", position: 3, duration: 1),
                
                CellData(title: "D", position: 4, duration: 1),
                CellData(title: "D", position: 5, duration: 1),
                CellData(title: "D", position: 6, duration: 1),
                CellData(title: "D", position: 7, duration: 1),
                
                CellData(title: "G", position: 8, duration: 1),
                CellData(title: "G", position: 9, duration: 1),
                CellData(title: "G", position: 10, duration: 1),
                CellData(title: "G", position: 11, duration: 1),
                
                CellData(title: "C", position: 12, duration: 1),
                CellData(title: "C", position: 13, duration: 1),
                CellData(title: "C", position: 14, duration: 1),
                CellData(title: "C", position: 15, duration: 1),
            ]),
        
        RowData(
            title: "Synths",
            cells: [
                CellData(title: "C", position: 0, duration: 0.5),
                CellData(title: "C", position: 2, duration: 0.5),
                
                CellData(title: "D", position: 4, duration: 0.5),
                CellData(title: "D", position: 6, duration: 0.5),
                
                CellData(title: "G", position: 8, duration: 0.5),
                CellData(title: "G", position: 10, duration: 0.5),
                
                CellData(title: "C", position: 12, duration: 0.5),
                CellData(title: "C", position: 14, duration: 0.5),
            ])
    ]
    var history = History()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeTableView?.dataSource = self
        timeTableView?.timeTableDelegate = self
        timeTableView?.gridLayer.showsSubbeatLines = false
        timeTableView?.reloadData()
        history.append(rows)
        updateHistoryButtons()
        
        view.backgroundColor = UIColor(red: 18.0/255.0, green: 20.0/255.0, blue: 19.0/255.0, alpha: 1)
        timeTableView?.measureView.backgroundColor = UIColor(red: 26.0/255.0, green: 28.0/255.0, blue: 27.0/255.0, alpha: 1)
        timeTableView?.measureView.tintColor = UIColor(red: 119.0/255.0, green: 121.0/255.0, blue: 120.0/255.0, alpha: 1)
        timeTableView?.gridLayer.rowLineColor = .black
        timeTableView?.gridLayer.barLineColor = UIColor(red: 42.0/255.0, green: 42.0/255.0, blue: 42.0/255.0, alpha: 1)
        timeTableView?.gridLayer.beatLineColor = UIColor(red: 42.0/255.0, green: 42.0/255.0, blue: 42.0/255.0, alpha: 1)
        timeTableView?.playheadView.tintColor = UIColor.gray.withAlphaComponent(0.5)
        timeTableView?.rangeheadView.tintColor = UIColor.gray.withAlphaComponent(0.3)
    }
    
    @IBAction func redoDidPress(sender: UIButton) {
        if let item = history.redo() {
            applyHistoryItem(item)
        }
        updateHistoryButtons()
    }
    
    @IBAction func undoDidPress(sender: UIButton) {
        if let item = history.undo() {
            applyHistoryItem(item)
        }
        updateHistoryButtons()
    }
    
    private func updateHistoryButtons() {
        undoButton?.isEnabled = history.hasPreviousHistoryItem
        redoButton?.isEnabled = history.hasNextHistoryItem
    }
    
    private func applyHistoryItem(_ item: [RowData]) {
        rows = item
        timeTableView?.reloadData()
    }
    
    private func index(ofCellID id: MIDITimeTableCellID) -> MIDITimeTableCellIndex? {
        for (row, rows) in rows.enumerated() {
            if let i = rows.cells.firstIndex(where: { $0.id == id }) {
                return MIDITimeTableCellIndex(row: row, index: i)
            }
        }
        return nil
    }
    
    private func apply(_ result: MIDITimeTableCellEditResult) {
        for update in result.updates {
            guard let currentIndex = index(ofCellID: update.id) else { continue }
            var cell = rows[currentIndex.row].cells[currentIndex.index]
            cell.position = update.newPosition
            cell.duration = update.newDuration
            if currentIndex.row == update.newRowIndex {
                rows[currentIndex.row].cells[currentIndex.index] = cell
            } else if update.newRowIndex >= 0 && update.newRowIndex < rows.count {
                rows[currentIndex.row].cells.remove(at: currentIndex.index)
                rows[update.newRowIndex].cells.append(cell)
            }
        }
        
        for id in result.removals {
            guard let currentIndex = index(ofCellID: id) else { continue }
            rows[currentIndex.row].cells.remove(at: currentIndex.index)
        }
        
        for insertion in result.insertions {
            guard insertion.row >= 0 && insertion.row < rows.count,
                  let sourceIndex = index(ofCellID: insertion.sourceID)
            else { continue }
            var cell = rows[sourceIndex.row].cells[sourceIndex.index]
            cell.id = insertion.id
            cell.position = insertion.position
            cell.duration = insertion.duration
            rows[insertion.row].cells.append(cell)
        }
    }
    
    private func removeCells(at indices: [MIDITimeTableCellIndex]) {
        for (row, index) in indices.ordered {
            rows[row].cells = rows[row].cells.enumerated().filter({ !index.contains($0.offset) }).map({ $0.element })
        }
    }
    
    // MARK: MIDITimeTableViewDataSource
    
    func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int {
        return rows.count
    }
    
    func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
        return MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, numberOfCellsInRow row: Int) -> Int {
        return rows[row].cells.count
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, idForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellID {
        return rows[index.row].cells[index.index].id
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, positionForCellAt index: MIDITimeTableCellIndex) -> Double {
        return rows[index.row].cells[index.index].position
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, durationForCellAt index: MIDITimeTableCellIndex) -> Double {
        return rows[index.row].cells[index.index].duration
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForHeaderInRow row: Int) -> MIDITimeTableHeaderCellView {
        let header = midiTimeTableView.dequeueReusableHeaderCellView(withIdentifier: "Header") as? HeaderCellView ?? HeaderCellView(title: "")
        header.titleLabel.text = rows[row].title
        return header
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellView {
        let cell = midiTimeTableView.dequeueReusableCellView(withIdentifier: "Cell") as? CellView ?? CellView(title: "")
        cell.configure(with: rows[index.row].cells[index.index])
        return cell
    }
    
    // MARK: MIDITimeTableViewDelegate
    
    func midiTimeTableViewHeightForRows(_ midiTimeTableView: MIDITimeTableView) -> CGFloat {
        return 60
    }
    
    func midiTimeTableViewHeightForMeasureView(_ midiTimeTableView: MIDITimeTableView) -> CGFloat {
        return 20
    }
    
    func midiTimeTableViewWidthForRowHeaderCells(_ midiTimeTableView: MIDITimeTableView) -> CGFloat {
        return 100
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDelete cells: [MIDITimeTableCellIndex]) {
        removeCells(at: cells)
        timeTableView?.removeCells(at: cells)
        updateHistoryButtons()
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit result: MIDITimeTableCellEditResult) {
        apply(result)
        updateHistoryButtons()
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double) {
        return
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double) {
        return
    }
    
    func midiTimeTableViewShouldPushHistory(_ midiTimeTableView: MIDITimeTableView) {
        history.append(rows)
        updateHistoryButtons()
    }
}
