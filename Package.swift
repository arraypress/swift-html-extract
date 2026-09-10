// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-html-extract",
    platforms: [
        .macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1),
    ],
    products: [
        .library(name: "HTMLExtract", targets: ["HTMLExtract"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "HTMLExtract",
            dependencies: [.product(name: "SwiftSoup", package: "SwiftSoup")]
        ),
        .testTarget(name: "HTMLExtractTests", dependencies: ["HTMLExtract"]),
    ]
)
