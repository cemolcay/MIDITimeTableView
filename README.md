MIDITimeTableView
===

Customisable and editable time table grid for showing midi or audio related data with a measure.

Demo
----

![alt tag](https://github.com/cemolcay/MIDITimeTableView/raw/master/demo.gif)

Requirements
----

- Swift 3+
- iOS 9.0+

Install
----

```
pod 'MIDITimeTableView'
```

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