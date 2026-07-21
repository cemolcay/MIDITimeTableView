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
    func configure(with cellData: MIDITimeTableCellData) {
        titleLabel.text = cellData.data as? String ?? ""
    }
    
    @objc func didPressCustomMenuItem() {
        print("custom menu item pressed")
    }
}

final class SongRowData: MIDITimeTableRowData {
    let title: String
    
    init(title: String, cells: [MIDITimeTableCellData]) {
        self.title = title
        super.init(cells: cells)
    }
    
    override func copy() -> MIDITimeTableRowData {
        return SongRowData(title: title, cells: cells)
    }
}

class ViewController: UIViewController, MIDITimeTableViewDataSource, MIDITimeTableViewDelegate {
    @IBOutlet weak var timeTableView: MIDITimeTableView?
    @IBOutlet weak var undoButton: UIBarButtonItem?
    @IBOutlet weak var redoButton: UIBarButtonItem?
    
    var rowData: [MIDITimeTableRowData] = [
        SongRowData(
            title: "Chords",
            cells: [
                MIDITimeTableCellData(data: "C7", position: 0, duration: 4),
                MIDITimeTableCellData(data: "Dm7", position: 4, duration: 4),
                MIDITimeTableCellData(data: "G7b5", position: 8, duration: 4),
                MIDITimeTableCellData(data: "C7", position: 12, duration: 4),
            ]),
        
        SongRowData(
            title: "Bass",
            cells: [
                MIDITimeTableCellData(data: "C", position: 0, duration: 1),
                MIDITimeTableCellData(data: "D", position: 4, duration: 1),
                MIDITimeTableCellData(data: "G", position: 8, duration: 1),
                MIDITimeTableCellData(data: "C", position: 12, duration: 1),
            ]),
        
        SongRowData(
            title: "Melody",
            cells: [
                MIDITimeTableCellData(data: "C", position: 0, duration: 1),
                MIDITimeTableCellData(data: "C", position: 1, duration: 1),
                MIDITimeTableCellData(data: "C", position: 2, duration: 1),
                MIDITimeTableCellData(data: "C", position: 3, duration: 1),
                
                MIDITimeTableCellData(data: "D", position: 4, duration: 1),
                MIDITimeTableCellData(data: "D", position: 5, duration: 1),
                MIDITimeTableCellData(data: "D", position: 6, duration: 1),
                MIDITimeTableCellData(data: "D", position: 7, duration: 1),
                
                MIDITimeTableCellData(data: "G", position: 8, duration: 1),
                MIDITimeTableCellData(data: "G", position: 9, duration: 1),
                MIDITimeTableCellData(data: "G", position: 10, duration: 1),
                MIDITimeTableCellData(data: "G", position: 11, duration: 1),
                
                MIDITimeTableCellData(data: "C", position: 12, duration: 1),
                MIDITimeTableCellData(data: "C", position: 13, duration: 1),
                MIDITimeTableCellData(data: "C", position: 14, duration: 1),
                MIDITimeTableCellData(data: "C", position: 15, duration: 1),
            ]),
        
        SongRowData(
            title: "Synths",
            cells: [
                MIDITimeTableCellData(data: "C", position: 0, duration: 0.5),
                MIDITimeTableCellData(data: "C", position: 2, duration: 0.5),
                
                MIDITimeTableCellData(data: "D", position: 4, duration: 0.5),
                MIDITimeTableCellData(data: "D", position: 6, duration: 0.5),
                
                MIDITimeTableCellData(data: "G", position: 8, duration: 0.5),
                MIDITimeTableCellData(data: "G", position: 10, duration: 0.5),
                
                MIDITimeTableCellData(data: "C", position: 12, duration: 0.5),
                MIDITimeTableCellData(data: "C", position: 14, duration: 0.5),
            ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeTableView?.dataSource = self
        timeTableView?.timeTableDelegate = self
        timeTableView?.gridLayer.showsSubbeatLines = false
        timeTableView?.reloadData()
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
        timeTableView?.history.redo()
        updateHistoryButtons()
    }
    
    @IBAction func undoDidPress(sender: UIButton) {
        timeTableView?.history.undo()
        updateHistoryButtons()
    }
    
    private func updateHistoryButtons() {
        undoButton?.isEnabled = timeTableView?.history.hasPreviousItem ?? false
        redoButton?.isEnabled = timeTableView?.history.hasNextItem ?? false
    }
    
    // MARK: MIDITimeTableViewDataSource
    
    func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int {
        return rowData.count
    }
    
    func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
        return MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowDataForRow row: Int) -> MIDITimeTableRowData {
        return rowData[row]
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForHeaderInRow row: Int) -> MIDITimeTableHeaderCellView {
        let header = midiTimeTableView.dequeueReusableHeaderCellView(withIdentifier: "Header") as? HeaderCellView ?? HeaderCellView(title: "")
        header.titleLabel.text = (rowData[row] as? SongRowData)?.title ?? ""
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
        rowData.removeCells(at: cells)
        // Incremental: only the deleted cells' views are torn down, everything else keeps its
        // existing view instance. `MIDITimeTableView` also records this as a new history entry
        // internally, so no `reloadData()` is needed here.
        timeTableView?.removeCells(at: cells)
        updateHistoryButtons()
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit result: MIDITimeTableCellEditResult) {
        // Keep our own mirror of the data in sync. `MIDITimeTableView` has already applied this same
        // result to its own state incrementally (see `applyEditResult(_:)`) and recorded history, so
        // there's no `reloadData()` to do here — the table is already showing the new state.
        rowData.apply(result)
        updateHistoryButtons()
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdatePlayhead position: Double) {
        return
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didUpdateRangeHead position: Double) {
        return
    }
    
    func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, historyDidChange history: MIDITimeTableHistory) {
        rowData = history.currentItem
    }
}
