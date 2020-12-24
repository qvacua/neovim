// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NvimServer",
  platforms: [.macOS(.v10_13)],
  products: [.library(name: "NvimServerTypes", targets: ["NvimServerTypes"])],
  dependencies: [],
  targets: [
    .target(
      name: "NvimServerTypes",
      dependencies: [],
      path: "NvimServerTypes/Sources"
    ),
    .target(
      name: "NvimServer",
      dependencies: [],
      path: "NvimServer/Sources",
      cSettings: [
        .headerSearchPath("src/"),
        .headerSearchPath("build/include"),
        .headerSearchPath(".deps/usr/include"),
        .headerSearchPath("build/config"),
        .headerSearchPath("NvimServer/third-party/include"),
      ]
    )
  ]
)
