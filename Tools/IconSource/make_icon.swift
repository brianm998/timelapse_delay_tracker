// Builds the 1024x1024 opaque sRGB app icon from the owner's artwork. Offscreen only.
// swift Tools/IconSource/make_icon.swift <source.png> <out.png>
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 3, let src = NSImage(contentsOfFile: args[1]),
      let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <source.png> <out.png>\n".utf8)); exit(1)
}
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
let w = cg.width, h = cg.height
var px = [UInt8](repeating: 0, count: w * h * 4)
px.withUnsafeMutableBytes { buf in
    let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
}

func isWhite(_ x: Int, _ y: Int) -> Bool {
    let i = (y * w + x) * 4
    return Int(px[i]) + Int(px[i + 1]) + Int(px[i + 2]) > 3 * 240
}
// Bounding box: scan the middle row and column inward from each side for the art.
let mx = w / 2, my = h / 2
var x0 = 0; while x0 < w && isWhite(x0, my) { x0 += 1 }
var x1 = w - 1; while x1 > 0 && isWhite(x1, my) { x1 -= 1 }
var y0 = 0; while y0 < h && isWhite(mx, y0) { y0 += 1 }
var y1 = h - 1; while y1 > 0 && isWhite(mx, y1) { y1 -= 1 }
// Drop the anti-aliased edge, then take the largest centred square.
let m = 3
x0 += m; y0 += m; x1 -= m; y1 -= m
let side = min(x1 - x0 + 1, y1 - y0 + 1)
let sx = x0 + ((x1 - x0 + 1) - side) / 2
let sy = y0 + ((y1 - y0 + 1) - side) / 2
FileHandle.standardError.write(Data("art box x \(x0)-\(x1) y \(y0)-\(y1), square \(side) at \(sx),\(sy)\n".utf8))

// Copy the square crop, then replace everything outside the art's rounded shape.
// "Outside" = near-white pixels connected to the crop border (flood fill), grown a few pixels to eat the
// anti-aliased rim. Each such pixel takes the colour of the nearest art pixel (multi-source breadth-first fill).
var sq = [UInt8](repeating: 255, count: side * side * 4)
for y in 0..<side {
    for x in 0..<side {
        let s = ((sy + y) * w + sx + x) * 4, o = (y * side + x) * 4
        sq[o] = px[s]; sq[o + 1] = px[s + 1]; sq[o + 2] = px[s + 2]
    }
}
func light(_ i: Int) -> Bool { Int(sq[i * 4]) + Int(sq[i * 4 + 1]) + Int(sq[i * 4 + 2]) > 3 * 200 }
var outside = [Bool](repeating: false, count: side * side)
var queue = [Int]()
func seed(_ i: Int) { if !outside[i] && light(i) { outside[i] = true; queue.append(i) } }
for k in 0..<side { seed(k); seed((side - 1) * side + k); seed(k * side); seed(k * side + side - 1) }
let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
var head = 0
while head < queue.count {
    let i = queue[head]; head += 1
    let x = i % side, y = i / side
    for (dx, dy) in dirs {
        let nx = x + dx, ny = y + dy
        if nx >= 0 && ny >= 0 && nx < side && ny < side { seed(ny * side + nx) }
    }
}
// Grow the outside region by 4 pixels (anti-aliased rim).
for _ in 0..<4 {
    var grown = outside
    for i in 0..<(side * side) where outside[i] {
        let x = i % side, y = i / side
        for (dx, dy) in dirs {
            let nx = x + dx, ny = y + dy
            if nx >= 0 && ny >= 0 && nx < side && ny < side { grown[ny * side + nx] = true }
        }
    }
    outside = grown
}
var filled = outside.map { !$0 }
var bfs = (0..<(side * side)).filter { filled[$0] }
head = 0
while head < bfs.count {
    let i = bfs[head]; head += 1
    let x = i % side, y = i / side
    for (dx, dy) in dirs {
        let nx = x + dx, ny = y + dy
        if nx >= 0 && ny >= 0 && nx < side && ny < side && !filled[ny * side + nx] {
            let j = ny * side + nx
            filled[j] = true
            sq[j * 4] = sq[i * 4]; sq[j * 4 + 1] = sq[i * 4 + 1]; sq[j * 4 + 2] = sq[i * 4 + 2]
            bfs.append(j)
        }
    }
}
let sqImg: CGImage = sq.withUnsafeMutableBytes { buf in
    CGContext(data: buf.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
              space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!.makeImage()!
}

// Scale to 1024 and store as 24-bit RGB (no alpha channel at all).
let n = 1024
var big = [UInt8](repeating: 0, count: n * n * 4)
big.withUnsafeMutableBytes { buf in
    let bctx = CGContext(data: buf.baseAddress, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
                         space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    bctx.interpolationQuality = .high
    bctx.draw(sqImg, in: CGRect(x: 0, y: 0, width: n, height: n))
}
var rgb = [UInt8](); rgb.reserveCapacity(n * n * 3)
for i in 0..<(n * n) { rgb += [big[i * 4], big[i * 4 + 1], big[i * 4 + 2]] }
let out = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: n * 3, space: srgb,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                  provider: CGDataProvider(data: Data(rgb) as CFData)!, decode: nil,
                  shouldInterpolate: true, intent: .defaultIntent)!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { exit(1) }
