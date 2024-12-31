// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let kPackageName = "RedactedAbortMarkers"

let kPlatforms: [SupportedPlatform] = [.iOS(.v15), .macOS(.v11)]

let package = Package(
    name: kPackageName,
    platforms: kPlatforms,
    products: [
        .library(
            name: kPackageName,
            targets: [.init(stringLiteral: kPackageName)]
        ),
    ],
    targets: [.target(name: kPackageName)]
)
