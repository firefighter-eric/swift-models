// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelEvaluationAppleRunner",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "ModelEvaluationAppleRunner",
            targets: ["ModelEvaluationAppleRunner"]
        ),
        .executable(
            name: "model-test-apple",
            targets: ["ModelEvaluationAppleCLI"]
        ),
    ],
    dependencies: [
        .package(path: "../ModelEvaluationCore"),
        .package(url: "https://github.com/FluidInference/FluidAudio", from: "0.12.5"),
        .package(url: "https://github.com/soniqo/speech-swift", exact: "0.0.7"),
    ],
    targets: [
        .target(
            name: "ModelEvaluationAppleRunner",
            dependencies: [
                "ModelEvaluationCore",
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "Qwen3ASR", package: "speech-swift"),
                .product(name: "AudioCommon", package: "speech-swift"),
            ]
        ),
        .executableTarget(
            name: "ModelEvaluationAppleCLI",
            dependencies: [
                "ModelEvaluationCore",
                "ModelEvaluationAppleRunner",
            ]
        ),
    ]
)
