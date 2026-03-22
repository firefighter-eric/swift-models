// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelEvaluationMLXRunner",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "ModelEvaluationMLXRunner",
            targets: ["ModelEvaluationMLXRunner"]
        ),
        .executable(
            name: "model-test-mlx",
            targets: ["ModelEvaluationMLXCLI"]
        ),
    ],
    dependencies: [
        .package(path: "../ModelEvaluationCore"),
        .package(url: "https://github.com/Blaizzy/mlx-audio-swift.git", exact: "0.1.2"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "ModelEvaluationMLXRunner",
            dependencies: [
                .product(name: "ModelEvaluationCore", package: "ModelEvaluationCore"),
                .product(name: "MLXAudioCore", package: "mlx-audio-swift"),
                .product(name: "MLXAudioSTT", package: "mlx-audio-swift"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
            ]
        ),
        .executableTarget(
            name: "ModelEvaluationMLXCLI",
            dependencies: [
                .product(name: "ModelEvaluationCore", package: "ModelEvaluationCore"),
                "ModelEvaluationMLXRunner",
            ]
        ),
    ]
)
