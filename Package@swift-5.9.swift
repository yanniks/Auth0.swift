// swift-tools-version:5.9

import PackageDescription

let webAuthPlatforms: [Platform] = [.iOS, .macOS, .macCatalyst, .visionOS]
let swiftSettings: [SwiftSetting] = [.define("WEB_AUTH_PLATFORM", .when(platforms: webAuthPlatforms))]

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13), .visionOS(.v1), .watchOS(.v7)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", .upToNextMajor(from: "3.1.0")),
    ],
    targets: [
        .target(
            name: "Auth0", 
            dependencies: [
                .product(name: "SimpleKeychain", package: "SimpleKeychain"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ],
            path: "Auth0",
            exclude: ["Info.plist"],
            swiftSettings: swiftSettings
        ),
    ]
)
