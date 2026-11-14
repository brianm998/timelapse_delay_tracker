import SwiftUI
import UIKit
import XCTest
@testable import TimelapseDelayTracker

final class ShotCalculatorTests: XCTestCase {
    func testShotsAreTimeUntilStartOverInterval() throws {
        let shots = try XCTUnwrap(ShotCalculator.preMoveShots(interval: 22, secondsUntilStart: 3600))
        XCTAssertEqual(shots, 3600.0 / 22.0, accuracy: 1e-9)
    }

    func testNoResultWithoutAValidInterval() {
        XCTAssertNil(ShotCalculator.preMoveShots(interval: 0, secondsUntilStart: 3600))
        XCTAssertNil(ShotCalculator.preMoveShots(interval: -5, secondsUntilStart: 3600))
    }

    func testNoResultOnceTheStartHasPassed() {
        XCTAssertNil(ShotCalculator.preMoveShots(interval: 22, secondsUntilStart: 0))
        XCTAssertNil(ShotCalculator.preMoveShots(interval: 22, secondsUntilStart: -60))
    }

    func testRigCountRoundsUp() {
        XCTAssertEqual(ShotCalculator.rigShotCount(163.6), 164)
        XCTAssertEqual(ShotCalculator.rigShotCount(164.0), 164)
        XCTAssertEqual(ShotCalculator.rigShotCount(0.1), 1)
    }
}

/// UI smoke test without XCUITest: the main screen is laid out in an offscreen window inside the
/// test host (a headless simulator, nothing shown on the Mac) and drawn to an image. The test fails
/// if the view tree crashes, lays out at zero size, or draws a blank screen. The image is attached
/// to the result bundle so a person can look at it.
@MainActor
final class ContentViewSmokeTests: XCTestCase {
    func testMainScreenRendersSomething() throws {
        try render(name: "ContentView", size: CGSize(width: 393, height: 852))
    }

    /// 11" and 13" iPad portrait and landscape, and a narrow Split View column. Layout only (no
    /// drawing): drawing five full-size images is slow enough on a loaded simulator to time out.
    func testMainScreenLaysOutOnIPadSizes() throws {
        let sizes: [CGSize] = [
            CGSize(width: 834, height: 1194), CGSize(width: 1194, height: 834),
            CGSize(width: 1024, height: 1366), CGSize(width: 1366, height: 1024),
            CGSize(width: 507, height: 1024),
        ]
        for size in sizes {
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            let host = UIHostingController(rootView: ContentView())
            window.rootViewController = host
            window.isHidden = false
            host.view.frame = window.bounds
            host.view.layoutIfNeeded()
            XCTAssertEqual(host.view.bounds.size, size)
            let fitted = host.sizeThatFits(in: CGSize(width: size.width, height: .greatestFiniteMagnitude))
            XCTAssertLessThanOrEqual(fitted.width, size.width + 0.5, "content wider than \(size)")
            window.isHidden = true
        }
    }

    private func render(name: String, size: CGSize) throws {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let host = UIHostingController(rootView: ContentView())
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let image = UIGraphicsImageRenderer(size: size).image { _ in
            _ = host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }

        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertGreaterThan(distinctColorCount(in: image), 8, "main screen drew almost nothing")
        window.isHidden = true
    }

    /// Distinct colours on a coarse grid; a blank or single-colour screen has one or two.
    private func distinctColorCount(in image: UIImage) -> Int {
        guard let cg = image.cgImage,
              let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return 0 }
        let bpp = cg.bitsPerPixel / 8, bpr = cg.bytesPerRow
        var seen = Set<UInt32>()
        for y in stride(from: 0, to: cg.height, by: 6) {
            for x in stride(from: 0, to: cg.width, by: 6) {
                let o = y * bpr + x * bpp
                seen.insert(UInt32(bytes[o]) << 16 | UInt32(bytes[o + 1]) << 8 | UInt32(bytes[o + 2]))
            }
        }
        return seen.count
    }
}

@MainActor
final class StoreScreenshotTests: XCTestCase {
    private struct Shot {
        let device: String, orientation: String
        let points: CGSize, scale: CGFloat
        let pixels: CGSize
        let isPad: Bool
    }

    private let shots: [Shot] = [
        Shot(device: "iphone-6.9", orientation: "portrait", points: CGSize(width: 440, height: 956),
             scale: 3, pixels: CGSize(width: 1320, height: 2868), isPad: false),
        Shot(device: "ipad-13", orientation: "portrait", points: CGSize(width: 1032, height: 1376),
             scale: 2, pixels: CGSize(width: 2064, height: 2752), isPad: true),
        Shot(device: "ipad-13", orientation: "landscape", points: CGSize(width: 1376, height: 1032),
             scale: 2, pixels: CGSize(width: 2752, height: 2064), isPad: true),
    ]

    private func date(_ h: Int, _ m: Int, _ s: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 14; c.hour = h; c.minute = m; c.second = s
        return Calendar.current.date(from: c)!
    }

    private struct ShotState {
        let name: String, interval: String, now: Date
    }

    private var states: [ShotState] {
        [ShotState(name: "result", interval: "22", now: date(20, 11, 58)),
         ShotState(name: "invalid-interval", interval: "0", now: date(20, 11, 58)),
         ShotState(name: "start-passed", interval: "22", now: date(21, 5))]
    }

    func testSizeTableMatchesAppStoreRequirements() {
        for shot in shots {
            XCTAssertEqual(shot.points.width * shot.scale, shot.pixels.width)
            XCTAssertEqual(shot.points.height * shot.scale, shot.pixels.height)
        }
        XCTAssertEqual(shots.map { "\(Int($0.pixels.width))x\(Int($0.pixels.height))" },
                       ["1320x2868", "2064x2752", "2752x2064"])
    }

    func testRendersStoreScreenshots() throws {
        let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"].flatMap { $0.isEmpty ? nil : $0 }
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if let dir {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        let chosen = dir == nil ? Array(states.prefix(1)) : states
        for shot in shots where shot.isPad == isPad {
            for state in chosen {
                let image = try render(shot, state)
                let cg = try XCTUnwrap(image.cgImage)
                XCTAssertEqual(CGFloat(cg.width), shot.pixels.width)
                XCTAssertEqual(CGFloat(cg.height), shot.pixels.height)
                XCTAssertGreaterThan(distinctColorCount(in: image), 8, "\(shot.device) \(state.name) is blank")
                if let dir {
                    let png = try XCTUnwrap(image.pngData())
                    let name = "\(shot.device)-\(shot.orientation)-\(state.name).png"
                    try png.write(to: URL(fileURLWithPath: dir).appendingPathComponent(name))
                }
            }
        }
    }

    private func render(_ shot: Shot, _ state: ShotState) throws -> UIImage {
        let window = UIWindow(frame: CGRect(origin: .zero, size: shot.points))
        window.overrideUserInterfaceStyle = .light
        let host = UIHostingController(rootView: ContentView(startTime: date(21, 0),
                                                             intervalText: state.interval,
                                                             now: state.now))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        let format = UIGraphicsImageRendererFormat()
        format.scale = shot.scale
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: shot.points, format: format).image { _ in
            _ = host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image
    }

    private func distinctColorCount(in image: UIImage) -> Int {
        guard let cg = image.cgImage,
              let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return 0 }
        let bpp = cg.bitsPerPixel / 8, bpr = cg.bytesPerRow
        var seen = Set<UInt32>()
        for y in stride(from: 0, to: cg.height, by: 12) {
            for x in stride(from: 0, to: cg.width, by: 12) {
                let o = y * bpr + x * bpp
                seen.insert(UInt32(bytes[o]) << 16 | UInt32(bytes[o + 1]) << 8 | UInt32(bytes[o + 2]))
            }
        }
        return seen.count
    }
}

final class PrivacyManifestTests: XCTestCase {
    func testPrivacyManifestDeclaresUserDefaultsReason() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"),
                                "PrivacyInfo.xcprivacy is missing from the app bundle")
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let dict = try XCTUnwrap(plist as? [String: Any])
        XCTAssertEqual(dict["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((dict["NSPrivacyTrackingDomains"] as? [Any])?.count, 0)
        XCTAssertEqual((dict["NSPrivacyCollectedDataTypes"] as? [Any])?.count, 0)
        let apis = try XCTUnwrap(dict["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let ud = try XCTUnwrap(apis.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" },
                               "UserDefaults category not declared")
        XCTAssertEqual(ud["NSPrivacyAccessedAPITypeReasons"] as? [String], ["CA92.1"])
    }
}

final class AppIconTests: XCTestCase {
    func testBuiltAppDeclaresTheAppIcon() {
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        XCTAssertEqual(primary?["CFBundleIconName"] as? String, "AppIcon")
    }
}
