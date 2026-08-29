// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LifeAchievementCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LifeAchievementCore",
            targets: ["LifeAchievementCore"]
        )
    ],
    targets: [
        .target(
            name: "LifeAchievementCore",
            dependencies: []
        ),
        .testTarget(
            name: "LifeAchievementCoreTests",
            dependencies: ["LifeAchievementCore"]
        )
    ]
)
