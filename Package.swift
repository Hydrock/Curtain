// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Curtain",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Curtain", targets: ["Curtain"])],
    targets: [.executableTarget(name: "Curtain", path: "Sources")]
)
