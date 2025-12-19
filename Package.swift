// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Keyboarding",
	 platforms: [
				 .macOS(.v15),
				 .iOS(.v17),
//				 .watchOS(.v7)
		  ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Keyboarding",
            targets: ["Keyboarding"]
        ),
    ],
	 dependencies: [
		 .package(url: "https://github.com/ios-tooling/Suite.git", from: "1.2.50"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Keyboarding", dependencies: [
					.product(name: "Suite", package: "Suite")
				]
        ),

    ]
)
