// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-models",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "ModelEvaluationKit",
            targets: ["ModelEvaluationKit"]
        ),
        .executable(
            name: "model-test",
            targets: ["ModelTestCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio", from: "0.12.5"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.7.0"),
    ],
    targets: [
        .target(
            name: "ModelEvaluationKit",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
            ]
        ),
        .executableTarget(
            name: "ModelTestCLI",
            dependencies: ["ModelEvaluationKit"]
        ),
        .testTarget(
            name: "ModelEvaluationKitTests",
            dependencies: [
                "ModelEvaluationKit",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
