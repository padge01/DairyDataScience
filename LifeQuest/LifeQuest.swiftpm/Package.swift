// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LifeQuest",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "LifeQuest",
            targets: ["LifeQuest"],
            bundleIdentifier: "com.lifequest.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .compass),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .healthKit(access: .init(
                    readData: [
                        .activitySummary,
                        .stepCount,
                        .distanceWalkingRunning,
                        .activeEnergyBurned,
                        .sleepAnalysis,
                        .heartRate,
                        .heartRateVariabilitySDNN,
                        .workoutType
                    ]
                ))
            ]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LifeQuest",
            path: "Sources/LifeQuest"
        )
    ]
)
