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
        let size = CGSize(width: 393, height: 852)
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
        attachment.name = "ContentView"
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

final class AppIconTests: XCTestCase {
    func testBuiltAppDeclaresTheAppIcon() {
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        XCTAssertEqual(primary?["CFBundleIconName"] as? String, "AppIcon")
    }
}
