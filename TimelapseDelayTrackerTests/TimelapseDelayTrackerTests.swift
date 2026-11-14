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
