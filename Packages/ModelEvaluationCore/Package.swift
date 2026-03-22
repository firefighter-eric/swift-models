// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelEvaluationCore",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "ModelEvaluationCore",
            targets: ["ModelEvaluationCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.7.0"),
    ],
    targets: [
        .target(
            name: "ModelEvaluationCore"
        ),
        .testTarget(
            name: "ModelEvaluationCoreTests",
            dependencies: [
                "ModelEvaluationCore",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
