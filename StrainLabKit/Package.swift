// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrainLabKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "StrainLabKit",
            targets: ["StrainLabKit"]
        )
    ],
    targets: [
        .target(
            name: "StrainLabKit",
            path: "Sources/StrainLabKit"
        ),
        .testTarget(
            name: "StrainLabKitTests",
            dependencies: ["StrainLabKit"],
            path: "Tests/StrainLabKitTests"
        )
    ]
)
