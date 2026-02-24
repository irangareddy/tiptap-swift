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
    targets: [
        .target(
            name: "TipTapSwift",
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
