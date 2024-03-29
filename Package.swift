// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BwCalendar",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BwCalendar",
            targets: ["BwCalendar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/BlueEventHorizon/BwTools.git", from: "3.3.6"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BwCalendar",
            dependencies: ["BwTools"]
        ),
        .testTarget(
            name: "BwCalendarTests",
            dependencies: ["BwCalendar"]
        ),
    ]
)
