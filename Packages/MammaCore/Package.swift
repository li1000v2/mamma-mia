// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MammaCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MammaCore", targets: ["MammaCore"]),
    ],
    dependencies: [
        // FSRS-6 is only on main; the last tagged release (v5.0.0) is FSRS-5, so pin the commit.
        .package(
            url: "https://github.com/open-spaced-repetition/swift-fsrs.git",
            revision: "4fbaf20184d62f82a9f44f343337c61a2c5483e9"
        ),
    ],
    targets: [
        .target(
            name: "MammaCore",
            dependencies: [.product(name: "FSRS", package: "swift-fsrs")]
        ),
        .testTarget(
            name: "MammaCoreTests",
            dependencies: ["MammaCore", .product(name: "FSRS", package: "swift-fsrs")]
        ),
    ]
)
