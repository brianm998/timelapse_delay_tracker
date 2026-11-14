// Renders the app icon offscreen: swift Tools/IconRenderer/render.swift <out.png>
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// Tweak these and re-render.
let skyTop = Color(red: 0.03, green: 0.07, blue: 0.20)
let skyBottom = Color(red: 0.0, green: 0.0, blue: 0.04)
let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
let bladeCount = 6
let starCount = 24

struct Blade: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let R = r.width / 2
        p.move(to: CGPoint(x: c.x - R * 0.28, y: c.y - R * 0.98))
        p.addLine(to: CGPoint(x: c.x + R * 0.5, y: c.y - R * 0.86))
        p.addLine(to: CGPoint(x: c.x + R * 0.1, y: c.y - R * 0.34))
        p.closeSubpath()
        return p
    }
}

struct IconView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)
            ForEach(0..<starCount, id: \.self) { i in
                let a = Double(i) * 2.399963
                let rad = 0.30 + 0.70 * Double((i * 37) % 24) / 24
                Circle().fill(.white.opacity(0.85))
                    .frame(width: i % 3 == 0 ? 14 : 8, height: i % 3 == 0 ? 14 : 8)
                    .position(x: 512 + cos(a) * rad * 500, y: 512 + sin(a) * rad * 500)
            }
            ZStack {
                Circle().stroke(accent, lineWidth: 36).frame(width: 760, height: 760)
                ForEach(0..<bladeCount, id: \.self) { i in
                    Blade().fill(accent)
                        .frame(width: 700, height: 700)
                        .rotationEffect(.degrees(Double(i) * 360 / Double(bladeCount)))
                }
                Circle().fill(skyBottom).frame(width: 330, height: 330)
                Circle().stroke(.white, lineWidth: 22).frame(width: 330, height: 330)
                Capsule().fill(.white).frame(width: 22, height: 120).offset(y: -50)
                Capsule().fill(.white).frame(width: 90, height: 22).offset(x: 34)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func render(to path: String) {
    let r = ImageRenderer(content: IconView())
    r.scale = 1
    guard let src = r.cgImage else { fatalError("render failed") }
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                              space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("ctx") }
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0.04, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    ctx.draw(src, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    guard let out = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("dest") }
    CGImageDestinationAddImage(dest, out, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("write failed") }
}

guard CommandLine.arguments.count > 1 else { print("usage: render.swift <out.png>"); exit(1) }
MainActor.assumeIsolated { render(to: CommandLine.arguments[1]) }
