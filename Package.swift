// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-models",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .executable(
            name: "model-test",
            targets: ["ModelTestCLI"]
        ),
    ],
    dependencies: [
        .package(path: "Packages/ModelEvaluationCore"),
    ],
    targets: [
        .executableTarget(
            name: "ModelTestCLI",
            dependencies: [
                "ModelEvaluationCore",
            ]
        ),
    ]
)
