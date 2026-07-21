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
* Customise grid and show bar, beat and subbeat lines with any style (optional).
* Viewport virtualization: cell views, grid lines and measure bars are only realized near what's
  actually on screen, so documents with hundreds or thousands of cells scroll smoothly instead of
  paying for every cell up front.


Usage
----

Create a `MIDITimeTableView` either programmatically or from storyboard and implement its `MIDITimeTableViewDataSource` and `MIDITimeTableViewDelegate` methods.
  
Keep your own row and cell models. The time table asks your data source only for stable IDs,
positions and durations.

``` swift
struct SongCell: MIDITimeTableCellRepresentable {
  var id = MIDITimeTableCellID()
  var title: String
  var position: Double
  var duration: Double
}

struct SongRow: MIDITimeTableRowRepresentable {
  var title: String
  var cells: [SongCell]
}

var rowData: [SongRow] = [
  SongRow(
    title: "Chords",
    cells: [
      SongCell(title: "C7", position: 0, duration: 4),
      SongCell(title: "Dm7", position: 4, duration: 4),
    ]),
]
```

`MIDITimeTableViewDataSource` is similar to `UITableViewDataSource` or `UICollectionViewDataSource` API. Feed the row/cell model and return configured views for headers and cells.

``` swift
func numberOfRows(in midiTimeTableView: MIDITimeTableView) -> Int {
  return rowData.rowCount
}

func timeSignature(of midiTimeTableView: MIDITimeTableView) -> MIDITimeTableTimeSignature {
  return MIDITimeTableTimeSignature(beats: 4, noteValue: .quarter)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, numberOfCellsInRow row: Int) -> Int {
  return rowData.cellCount(inRow: row)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, idForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellID {
  return rowData.cellID(at: index)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, positionForCellAt index: MIDITimeTableCellIndex) -> Double {
  return rowData.cellPosition(at: index)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, durationForCellAt index: MIDITimeTableCellIndex) -> Double {
  return rowData.cellDuration(at: index)
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForHeaderInRow row: Int) -> MIDITimeTableHeaderCellView {
  let header = midiTimeTableView.dequeueReusableHeaderCellView(withIdentifier: "Header") as? HeaderCellView ?? HeaderCellView(title: "")
  header.titleLabel.text = rowData[row].title
  return header
}

func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellView {
  let cell = midiTimeTableView.dequeueReusableCellView(withIdentifier: "Cell") as? CellView ?? CellView(title: "")
  cell.configure(with: rowData.cell(at: index))
  return cell
}
```

Those helpers come from the optional `MIDITimeTableRowRepresentable` /
`MIDITimeTableCellRepresentable` protocols. They only read your model; view creation and
configuration stay explicit in the data source.

Keep your model in sync by applying the change callback from `MIDITimeTableViewDelegate`.
Your app's model remains the source of truth. Moves, resizes, overlap trims, split insertions and
deletions all arrive as one `MIDITimeTableCellEditResult` in `didChange`. Apply the result
synchronously there; the time table updates its internal layout immediately after the callback
returns, so any newly split cells can be dequeued and configured from your already-updated data
source.

``` swift
func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, didChange result: MIDITimeTableCellEditResult) {
  apply(result)
}

func midiTimeTableViewShouldPushHistory(_ midiTimeTableView: MIDITimeTableView) {
  history.append(rowData)
}

func midiTimeTableViewSnapResolution(_ midiTimeTableView: MIDITimeTableView) -> Int {
  return 4
}
```

`MIDITimeTableCellEditResult` has three parts:

* `updates`: existing cells whose row, position or duration changed. Locate these in your model by
  stable `id`, then update their stored geometry.
* `removals`: existing cell IDs that were fully covered and should be deleted from your model.
* `insertions`: new split fragments created from an existing cell. Clone the model referenced by
  `sourceID`, assign the new `id`, `position` and `duration`, then insert it into `row`.

For example:

``` swift
private func index(ofCellID id: MIDITimeTableCellID) -> MIDITimeTableCellIndex? {
  return rowData.index(ofCellID: id)
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
```

Cell IDs must be unique and stable. Positions must be finite and non-negative; durations must be
finite and greater than zero. Debug builds assert when a data source snapshot violates those
contracts.

`MIDITimeTableHistoryRepresentable` and `MIDITimeTableHistoryStack` are available if you want an
app-owned undo/redo stack with default append/undo/redo behavior:

``` swift
struct SongHistory: MIDITimeTableHistoryRepresentable {
  var history = MIDITimeTableHistoryStack<[SongRow]>()
}
```

The optional `midiTimeTableViewShouldPushHistory(_:)` delegate callback is called after the table
has accepted a user change and applied the same result to its internal layout. Use it to snapshot
your already-updated model. Programmatic changes that you apply yourself should push their own
history entry when appropriate.
  
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
`4` subdivisions per beat. After every user change, overlaps are resolved and reported as a
`MIDITimeTableCellEditResult` containing updates, removals, and insertions. Apply that result in
`midiTimeTableView(_:didChange:)` to keep your data source in sync.

### Viewport virtualization & cell reuse

`MIDITimeTableView` only keeps live `MIDITimeTableCellView`s for cells that are actually near the
viewport (plus a small overscan margin, tunable via `virtualizationOverscanMultiplier`), or that
are currently selected. This is what `visibleCells` (`public private(set) var`) reflects — it's
**not** every cell in your data, only the ones currently realized as views. A cell that isn't in
`visibleCells` still exists in your data source; it just isn't on screen right now. Look a
specific cell's view up by its stable `MIDITimeTableCellID` with `midiTimeTableView.cellView(for: songCell.id)`,
which returns `nil` for a cell that isn't currently realized.

To get `UITableView`-style reuse instead of a fresh view every time one scrolls into view, create
views with a reuse identifier and dequeue them in the data source:

``` swift
func midiTimeTableView(_ midiTimeTableView: MIDITimeTableView, viewForCellAt index: MIDITimeTableCellIndex) -> MIDITimeTableCellView {
  let cell = midiTimeTableView.dequeueReusableCellView(withIdentifier: "Cell") as? CellView ?? CellView(title: "")
  cell.configure(with: rowData.cell(at: index))
  return cell
}
```

Views are pooled by reuse identifier. Leave the dequeue call out to opt out — the time table still
realizes what's near the viewport, it just creates a fresh view each time instead of reusing an
instance.

Documentation
----

[Full documentation is here.](http://cemolcay.github.io/MIDITimeTableView)

AppStore
----

This library is used in my app [ChordBud](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8), check it out!
  
[![alt tag](https://linkmaker.itunes.apple.com/assets/shared/badges/en-us/appstore-lrg.svg)](https://itunes.apple.com/us/app/chordbud-chord-progressions/id1313017378?mt=8)
