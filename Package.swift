// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CargasCalc",
    platforms: [
        .iOS("26.0"),
        .macOS(.v14),
    ],
    products: [
        // An xtool project must expose exactly one library product.
        .library(name: "CargasCalc", targets: ["CargasCalc"]),
    ],
    targets: [
        .target(name: "CargasCalcCore"),
        .target(name: "CargasCalc", dependencies: ["CargasCalcCore"]),
        .testTarget(name: "CargasCalcCoreTests", dependencies: ["CargasCalcCore"]),
    ]
)
