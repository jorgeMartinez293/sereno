// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SerenoApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../vidrio/Vendor/SwiftTerm"),
        // Sparkle: in-app auto-updates. The Makefile embeds Sparkle.framework
        // into the .app bundle (swift build alone doesn't).
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "SerenoApp",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        )
    ]
)
