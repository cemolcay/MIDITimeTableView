MIDITimeTableView
===
 
Customisable and editable time table grid for showing midi or audio related data with a measure.

Demo
----

![alt tag](https://github.com/cemolcay/MIDITimeTableView/raw/master/Example/demo.gif)

Requirements
----

- Swift 5.9+
- iOS 13.0+

Install
----

### Swift Package Manager

```
.package(url: "https://github.com/cemolcay/MIDITimeTableView", from: "1.0.3")
```

Or add it via Xcode: File > Add Package Dependencies... and paste the repo URL.

A runnable demo project is available in [`Example/`](Example).

Features
----

* Easy to implement, Delegate/DataSource API similar to `UITableView` and `UICollectionView`.
* Unlimited rows and cells.
* Cells and Row Headers are fully customisable. You can show any UIView inside them.
* Shows bar measure (optional).
* Shows editable playhead that shows current time (optional).
* Pinch to zoom in/out. (optional).
* Edit single cell or multiple cells.
* Drag them around to change row or position.
* Drag them from right edge to change duration.
* Long press any cell to show customisable menu.
* Holds history with a customisable limit and make undo/redo (optional).
* Customise grid and show bar, beat and subbeat lines with any style (optional).
* Viewport virtualization: cell views, grid lines and measure bars are only realized near what's
  actually on screen, so documents with hundreds or thousands of cells scroll smoothly instead of
  paying for every cell up front.


Usage
----

Create a `MIDITimeTableView` either programmatically or from storyboard and implement its `MIDITimeTableViewDataSource` and `MIDITimeTableViewDelegate` methods.
  
You need a data object to store each row and its cells data.

``` swift
var rowData: [MIDITimeTableRowData] = [
  MIDITimeTableRowData(
    cells: [
      MIDITimeTableCellData(data: "C7", position: 0, duration: 4),
      MIDITimeTableCellData(data: "Dm7", position: 4, duration: 4),
      MIDITimeTableCellData(data: "G7b5", position: 8, duration: 4),
      MIDITimeTableCellData(data: "C7", position: 12, duration: 4),
    ],
    headerCellView: HeaderCellView(title: "Chords"),
    cellView: { cellData in
      let title = cellData.data as? String ?? ""
      return CellView(title: title)
    }),
]
```

`MIDITimeTableViewDataSource` is very likely to `UITableViewDataSource` or `UICollectionViewDataSource` API. Just feed the row data, number of rows, time signature and you are ready to go.

``` swift
func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int {
  return rowData.count
}

func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
  return MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, rowAt index: Int) -> MIDITimeTableRowData {
  let row = rowData[index]
  return row
}
```
  
You can customise the measure bar, the grid, each header and data cell. Check out the example project.

`MIDITimeTableCellView`'s are editable, you can move around them on the grid, resize their duration or long press to open a delete menu. Also, you need to subclass yourself to present your own data on it.
  
You can set the `minMeasureWidth` and `maxMeasureWidth` to set zoom levels of the time table.

### Viewport virtualization & cell reuse

`MIDITimeTableView` only keeps live `MIDITimeTableCellView`s for cells that are actually near the
viewport (plus a small overscan margin, tunable via `virtualizationOverscanMultiplier`), or that
are currently selected. This is what `visibleCells` (`public private(set) var`) reflects — it's
**not** every cell in your data, only the ones currently realized as views. A cell that isn't in
`visibleCells` still exists in your data source; it just isn't on screen right now. Look a
specific cell's view up by its stable id with `midiTimeTableView.cellView(for: cellData.id)`,
which returns `nil` for a cell that isn't currently realized.

To get `UITableView`-style cell reuse instead of a fresh view per cell every time one scrolls into
view, provide `configureCellView` alongside `cellView` on `MIDITimeTableRowData`:

``` swift
MIDITimeTableRowData(
  cells: cells,
  headerCellView: HeaderCellView(title: "Chords"),
  cellView: { cellData in
    let title = cellData.data as? String ?? ""
    return CellView(title: title)
  },
  configureCellView: { view, cellData in
    (view as? CellView)?.configure(with: cellData)
  })
```

Views are pooled per row, so a dequeued instance is always the exact subclass that row's
`cellView` produces. Leave `configureCellView` `nil` to opt out — the time table still only
realizes what's near the viewport, it just creates a fresh view each time instead of reusing an
instance.

Documentation
----

[Full documentation are here.](http://cemolcay.github.io/MIDITimeTableView)

AppStore
----

This library used in my app [ChordBud](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8), check it out!
  
[![alt tag](https://linkmaker.itunes.apple.com/assets/shared/badges/en-us/appstore-lrg.svg)](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8)
