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
    func configure(with cellData: SongCell) {
        titleLabel.text = cellData.title
    }
    
    @objc func didPressCustomMenuItem() {
        print("custom menu item pressed")
    }
}

struct SongCell {
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

struct SongRow {
    var title: String
    var cells: [SongCell]
}

struct SongHistory {
    var items = [[[SongCell]]]()
    var currentIndex = -1
    
    var hasPreviousItem: Bool { currentIndex > 0 }
    var hasNextItem: Bool { currentIndex < items.count - 1 }
    var currentItem: [[SongCell]] {
        guard currentIndex >= 0, currentIndex < items.count else { return [] }
        return items[currentIndex]
    }
    
    mutating func append(_ rows: [SongRow]) {
        var nextItems = items.enumerated().filter({ $0.offset <= currentIndex }).map({ $0.element })
        nextItems.append(rows.map({ $0.cells }))
        items = nextItems
        currentIndex = items.count - 1
    }
    
    mutating func undo() -> [[SongCell]]? {
        guard hasPreviousItem else { return nil }
        currentIndex -= 1
        return currentItem
    }
    
    mutating func redo() -> [[SongCell]]? {
        guard hasNextItem else { return nil }
        currentIndex += 1
        return currentItem
    }
}

class ViewController: UIViewController, MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
    @IBOutlet weak var timeTableView: MIDITimeTableView?
    @IBOutlet weak var undoButton: UIBarButtonItem?
    @IBOutlet weak var redoButton: UIBarButtonItem?
    
    var rowData: [SongRow] = [
        SongRow(
            title: "Chords",
            cells: [
                SongCell(title: "C7", position: 0, duration: 4),
                SongCell(title: "Dm7", position: 4, duration: 4),
                SongCell(title: "G7b5", position: 8, duration: 4),
                SongCell(title: "C7", position: 12, duration: 4),
            ]),
        
        SongRow(
            title: "Bass",
            cells: [
                SongCell(title: "C", position: 0, duration: 1),
                SongCell(title: "D", position: 4, duration: 1),
                SongCell(title: "G", position: 8, duration: 1),
                SongCell(title: "C", position: 12, duration: 1),
            ]),
        
        SongRow(
            title: "Melody",
            cells: [
                SongCell(title: "C", position: 0, duration: 1),
                SongCell(title: "C", position: 1, duration: 1),
                SongCell(title: "C", position: 2, duration: 1),
                SongCell(title: "C", position: 3, duration: 1),
                
                SongCell(title: "D", position: 4, duration: 1),
                SongCell(title: "D", position: 5, duration: 1),
                SongCell(title: "D", position: 6, duration: 1),
                SongCell(title: "D", position: 7, duration: 1),
                
                SongCell(title: "G", position: 8, duration: 1),
                SongCell(title: "G", position: 9, duration: 1),
                SongCell(title: "G", position: 10, duration: 1),
                SongCell(title: "G", position: 11, duration: 1),
                
                SongCell(title: "C", position: 12, duration: 1),
                SongCell(title: "C", position: 13, duration: 1),
                SongCell(title: "C", position: 14, duration: 1),
                SongCell(title: "C", position: 15, duration: 1),
            ]),
        
        SongRow(
            title: "Synths",
            cells: [
                SongCell(title: "C", position: 0, duration: 0.5),
                SongCell(title: "C", position: 2, duration: 0.5),
                
                SongCell(title: "D", position: 4, duration: 0.5),
                SongCell(title: "D", position: 6, duration: 0.5),
                
                SongCell(title: "G", position: 8, duration: 0.5),
                SongCell(title: "G", position: 10, duration: 0.5),
                
                SongCell(title: "C", position: 12, duration: 0.5),
                SongCell(title: "C", position: 14, duration: 0.5),
            ])
    ]
    var history = SongHistory()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeTableView?.dataSource = self
        timeTableView?.timeTableDelegate = self
        timeTableView?.gridLayer.showsSubbeatLines = false
        timeTableView?.reloadData()
        history.append(rowData)
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
        undoButton?.isEnabled = history.hasPreviousItem
        redoButton?.isEnabled = history.hasNextItem
    }
    
    private func applyHistoryItem(_ item: [[SongCell]]) {
        for rowIndex in rowData.indices where rowIndex < item.count {
            rowData[rowIndex].cells = item[rowIndex]
        }
        timeTableView?.reloadData()
    }
    
    private func index(ofCellID id: MIDITimeTableCellID) -> MIDITimeTableCellIndex? {
        for (row, rowData) in rowData.enumerated() {
            if let i = rowData.cells.firstIndex(where: { $0.id == id }) {
                return MIDITimeTableCellIndex(row: row, index: i)
            }
        }
        return nil
    }
    
    private func apply(_ result: MIDITimeTableCellEditResult) {
        for update in result.updates {
            guard let currentIndex = index(ofCellID: update.id) else { continue }
            var cell = rowData[currentIndex.row].cells[currentIndex.index]
            cell.position = update.newPosition
            cell.duration = update.newDuration
            if currentIndex.row == update.newRowIndex {
                rowData[currentIndex.row].cells[currentIndex.index] = cell
            } else if update.newRowIndex >= 0 && update.newRowIndex < rowData.count {
                rowData[currentIndex.row].cells.remove(at: currentIndex.index)
                rowData[update.newRowIndex].cells.append(cell)
            }
        }
        
        for id in result.removals {
            guard let currentIndex = index(ofCellID: id) else { continue }
            rowData[currentIndex.row].cells.remove(at: currentIndex.index)
        }
        
        for insertion in result.insertions {
            guard insertion.row >= 0 && insertion.row < rowData.count,
                  let sourceIndex = index(ofCellID: insertion.sourceID)
            else { continue }
            var cell = rowData[sourceIndex.row].cells[sourceIndex.index]
            cell.id = insertion.id
            cell.position = insertion.position
            cell.duration = insertion.duration
            rowData[insertion.row].cells.append(cell)
        }
    }
    
    private func removeCells(at indices: [MIDITimeTableCellIndex]) {
        for (row, index) in indices.ordered {
            rowData[row].cells = rowData[row].cells.enumerated().filter({ !index.contains($0.offset) }).map({ $0.element })
        }
    }
    
    // MARK: MIDITimeTableViewDataSource
    
    func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int {
        return rowData.count
    }
    
    func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
        return MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, numberOfCellsInRow row: Int) -> Int {
        return rowData[row].cells.count
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, idForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellID {
        return rowData[index.row].cells[index.index].id
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, positionForCellAt index: MIDITimeTableCellIndex) -> Double {
        return rowData[index.row].cells[index.index].position
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, durationForCellAt index: MIDITimeTableCellIndex) -> Double {
        return rowData[index.row].cells[index.index].duration
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForHeaderInRow row: Int) -> MIDITimeTableHeaderCellView {
        let header = midiTimeTableView.dequeueReusableHeaderCellView(withIdentifier: "Header") as? HeaderCellView ?? HeaderCellView(title: "")
        header.titleLabel.text = rowData[row].title
        return header
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellView {
        let cell = midiTimeTableView.dequeueReusableCellView(withIdentifier: "Cell") as? CellView ?? CellView(title: "")
        cell.configure(with: rowData[index.row].cells[index.index])
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
        history.append(rowData)
        updateHistoryButtons()
    }
}
