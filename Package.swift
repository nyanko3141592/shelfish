// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Shelfish",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Shelfish",
            path: "Sources/Shelfish"
        )
    ]
)
