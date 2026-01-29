// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SMB-for-Watch",
    platforms: [
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "SMB-for-Watch",
            targets: ["SMB-for-Watch"]),
    ],
    dependencies: [
        // Hier können externe Abhängigkeiten hinzugefügt werden
        // z.B. für SMB: https://github.com/samba-team/samba
        // Für Produktions-Apps würde man hier SMB-Bibliotheken hinzufügen
    ],
    targets: [
        .target(
            name: "SMB-for-Watch",
            dependencies: []),
        .testTarget(
            name: "SMB-for-WatchTests",
            dependencies: ["SMB-for-Watch"]),
    ]
)
