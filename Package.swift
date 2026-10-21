// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "tiptap-swift",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TipTapSwift",
            targets: ["TipTapSwift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.14.3")
    ],
    targets: [
        .target(
            name: "TipTapSwift",
            dependencies: [.product(name: "SwiftSoup", package: "SwiftSoup")],
            resources: [
                .copy("Resources/RichTextEditor")
            ]
        ),
        .testTarget(
            name: "TipTapSwiftTests",
            dependencies: ["TipTapSwift"]
        )
    ]
)
