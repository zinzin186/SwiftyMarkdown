// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftyMarkdown",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v8),
        .tvOS(SupportedPlatform.TVOSVersion.v9),
    ],
    products: [
        .library(
            name: "SwiftyMarkdown",
            targets: ["SwiftyMarkdown"]),
    ],
    targets: [
        .target(
            name: "SwiftyMarkdown",
            path: "SwiftyMarkdown"),
        .testTarget(
            name: "SwiftyMarkdownTests",
            dependencies: ["SwiftyMarkdown"],
            path: "SwiftyMarkdownTests"),
    ]
)
