// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftyMarkdown",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v11),
        .tvOS(SupportedPlatform.TVOSVersion.v11),
		.macOS(.v10_12),
		.watchOS(.v4)
    ],
    products: [
        .library(name: "SwiftyMarkdown", targets: ["SwiftyMarkdown"]),
    ],
    targets: [
        .target(name: "SwiftyMarkdown", path: "SwiftyMarkdown"),
    ]
)
