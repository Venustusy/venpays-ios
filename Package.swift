// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VenPaysApplePay",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "VenPaysApplePay",
            targets: ["VenPaysApplePay"]
        )
    ],
    targets: [
        .target(
            name: "VenPaysApplePay",
            path: "Sources/VenPaysApplePay"
        ),
        .testTarget(
            name: "VenPaysApplePayTests",
            dependencies: ["VenPaysApplePay"],
            path: "Tests/VenPaysApplePayTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
