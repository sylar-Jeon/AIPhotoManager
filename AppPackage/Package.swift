// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "AppPackage",
    platforms: [.iOS("16.4")],
    products: [        
        .library(name: "libaiphoto", targets: ["AIPhotoManagerApp"]),
    ],
    dependencies: [
        //.package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        //.package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.3.5"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from:"1.15.2"),
    ],
    targets: [
        .target(name: "APFoundation",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),

        .target(name: "Scenes",
            dependencies: ["APFoundation"]
        ),

        .target(
            name: "AIPhotoManagerApp",
            dependencies: ["Scenes", "APFoundation"]
        )
    ]
)

// MARK : test
package.targets.append(
    contentsOf: [
        .testTarget(name: "AppPackageTests", dependencies: ["Scenes"]),
    ]
)
