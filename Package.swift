// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppServerClient",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v18),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppServerClient",
            targets: ["AppServerClient"]
        ),
        .executable(
            name: "appserver-smoke",
            targets: ["AppServerSmokeCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMajor(from: "1.12.2")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMajor(from: "1.12.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppServerClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            exclude: [
                "JSONSchema",
                "openapi.json.template",
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .executableTarget(
            name: "AppServerSmokeCLI",
            dependencies: ["AppServerClient"]
        ),
        .testTarget(
            name: "AppServerClientTests",
            dependencies: ["AppServerClient"]
        ),
    ]
)
