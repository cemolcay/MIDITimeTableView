// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MIDITimeTableView",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MIDITimeTableView",
            targets: ["MIDITimeTableView"]),
    ],
    targets: [
        .target(
            name: "MIDITimeTableView",
            path: "Sources/MIDITimeTableView"),
        .testTarget(
            name: "MIDITimeTableViewTests",
            dependencies: ["MIDITimeTableView"],
            path: "Tests/MIDITimeTableViewTests"),
    ]
)
