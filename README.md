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
* Cells and Row Headers are fully customisable. You can show any `UIView` inside them.
* Shows bar measure (optional).
* Shows editable playhead that shows current time (optional).
* Shows an editable range head, with optional automatic extension to the last cell.
* Pinch to zoom in/out (optional).
* Edit a single cell or multiple selected cells.
* Drag selected cells around to change row or position.
* Drag selected cells from the right edge to change duration.
* Long-press the time table surface to draw a marquee selection rectangle.
* Auto-scrolls near grid edges while drawing a marquee, moving cells, or resizing cells.
* Snaps cell moves/resizes, playhead drags, and range-head drags to a configurable beat subdivision.
* Resolves overlaps after edits, including trims, removals, splits, and overlaps inside a multi-cell resize.
* Long-press any cell to show a customisable menu.
* Holds history with a customisable limit and supports undo/redo (optional).
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

`MIDITimeTableViewDataSource` is similar to `UITableViewDataSource` or `UICollectionViewDataSource` API. Just feed the row data, number of rows, time signature and you are ready to go.

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

Keep your model in sync by applying the edit and delete callbacks from `MIDITimeTableViewDelegate`.
The time table view applies edits internally before calling `didEdit`; your app should apply the
same result to its own `rowData`.

``` swift
func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didEdit result: MIDITimeTableCellEditResult) {
  rowData.apply(result)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didDelete cells: [MIDITimeTableCellIndex]) {
  rowData.removeCells(at: cells)
  midiTimeTableView.removeCells(at: cells)
}

func midiTimeTableViewSnapResolution(_ midiTimeTableView: MIDITimeTableView) -> Int {
  return 4
}
```
  
You can customise the measure bar, the grid, each header and data cell. Check out the example project.

`MIDITimeTableCellView`'s are editable, you can move them around the grid, resize their duration,
or long press to open a delete menu. Subclass `MIDITimeTableCellView` to present your own data.
  
You can set the `minMeasureWidth` and `maxMeasureWidth` to set zoom levels of the time table.

### Editing behavior

Tap a cell to select it. Dragging or resizing an unselected cell clears the previous selection and
edits only that cell. Dragging or resizing an already-selected cell edits the selected group
together.

Long-press anywhere on the time table surface, including empty space below the last row, to start
marquee selection. A small rectangle appears under the long-press location immediately; as you drag,
that point and the current touch location act as opposite corners, so selection works in every
direction like a desktop marquee tool.

When the touch reaches the grid edge, the time table auto-scrolls. Marquee selection can auto-scroll
horizontally and vertically. Moving cells can auto-scroll horizontally and vertically while the
selected cells can still move in that direction. Resizing cells can auto-scroll horizontally while
the selected cells can still grow or shrink. Auto-scroll stops at the grid and row bounds.

Moves and resizes snap to the delegate's `midiTimeTableViewSnapResolution(_:)`, which defaults to
`4` subdivisions per beat. After every move or resize, overlaps are resolved and reported as a
`MIDITimeTableCellEditResult` containing updates, removals, and insertions. Call
`rowData.apply(result)` in `midiTimeTableView(_:didEdit:)` to keep your data source in sync.

### Viewport virtualization & cell reuse

`MIDITimeTableView` only keeps live `MIDITimeTableCellView`s for cells that are actually near the
viewport (plus a small overscan margin, tunable via `virtualizationOverscanMultiplier`), or that
are currently selected. This is what `visibleCells` (`public private(set) var`) reflects — it's
**not** every cell in your data, only the ones currently realized as views. A cell that isn't in
`visibleCells` still exists in your data source; it just isn't on screen right now. Look a
specific cell's view up by its stable `MIDITimeTableCellID` with `midiTimeTableView.cellView(for: cellData.id)`,
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

[Full documentation is here.](http://cemolcay.github.io/MIDITimeTableView)

AppStore
----

This library is used in my app [ChordBud](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8), check it out!
  
[![alt tag](https://linkmaker.itunes.apple.com/assets/shared/badges/en-us/appstore-lrg.svg)](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8)
