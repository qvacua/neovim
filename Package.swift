// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "NvimServerTypes",
  platforms: [.macOS(.v10_13)],
  products: [.library(name: "NvimServerTypes", targets: ["NvimServerTypes"])],
  dependencies: [],
  targets: [
    .target(
      name: "NvimServerTypes",
      dependencies: [],
      path: "NvimServerTypes",
      exclude: ["README.md"]
    ),
  ]
)
