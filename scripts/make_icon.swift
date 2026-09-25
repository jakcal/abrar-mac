// Renders the Abrar app icon into Abrar/Resources/Assets.xcassets/AppIcon.appiconset.
// Usage: swift scripts/make_icon.swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appendingPathComponent("Abrar/Resources/Assets.xcassets/AppIcon.appiconset")

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func starPath(center: CGPoint, outer: CGFloat) -> CGPath {
    let inner = outer * cos(.pi / 4) / cos(.pi / 8)
    let path = CGMutablePath()
    for index in 0..<16 {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = Double(index) * .pi / 8 + .pi / 2
        let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        index == 0 ? path.move(to: point) : path.addLine(to: point)
    }
    path.closeSubpath()
    return path
}

/// Draws the 1024 pt master in a Big Sur-style rounded square (824 pt, 100 pt margin).
func drawIcon(in context: CGContext) {
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    let space = CGColorSpace(name: CGColorSpace.sRGB)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    context.addPath(shape)
    context.setFillColor(color(0x0B3B3C))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(shape)
    context.clip()
    let sky = CGGradient(colorsSpace: space, colors: [color(0x061E2B), color(0x0E4A4C), color(0x1B6B62)] as CFArray, locations: [0, 0.6, 1])
    if let sky {
        context.drawLinearGradient(sky, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
    }
    let glow = CGGradient(colorsSpace: space, colors: [color(0xF4D58D, 0.28), color(0xF4D58D, 0)] as CFArray, locations: [0, 1])
    if let glow {
        context.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 530), startRadius: 0, endCenter: CGPoint(x: 512, y: 530), endRadius: 420, options: [])
    }
    for (x, y, r) in [(250.0, 780.0, 5.0), (330.0, 700.0, 3.0), (760.0, 800.0, 4.0), (800.0, 300.0, 3.0), (230.0, 330.0, 4.0), (700.0, 240.0, 3.0)] {
        context.setFillColor(color(0xFFFFFF, 0.55))
        context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    context.restoreGState()

    let center = CGPoint(x: 512, y: 512)
    let star = starPath(center: center, outer: 300)
    context.saveGState()
    context.addPath(star)
    context.clip()
    let gold = CGGradient(colorsSpace: space, colors: [color(0xFBE3A1), color(0xE0A93B), color(0xB9801F)] as CFArray, locations: [0, 0.55, 1])
    if let gold {
        context.drawLinearGradient(gold, start: CGPoint(x: 512, y: 812), end: CGPoint(x: 512, y: 212), options: [])
    }
    context.restoreGState()

    context.addPath(starPath(center: center, outer: 250))
    context.setFillColor(color(0x0B3B3C))
    context.fillPath()

    // Crescent: a gold disc with an offset dark disc cut out.
    context.saveGState()
    context.addPath(starPath(center: center, outer: 250))
    context.clip()
    context.setFillColor(color(0xF4D58D))
    context.fillEllipse(in: CGRect(x: 512 - 150, y: 512 - 150, width: 300, height: 300))
    context.setFillColor(color(0x0B3B3C))
    context.fillEllipse(in: CGRect(x: 512 - 150 + 78, y: 512 - 150 + 52, width: 290, height: 290))
    context.restoreGState()
}

func render(size: Int) throws -> Data {
    guard let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw CocoaError(.fileWriteUnknown) }
    context.interpolationQuality = .high
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    drawIcon(in: context)
    guard let image = context.makeImage(),
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    return data
}

let entries: [(points: Int, scale: Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)
var images: [[String: String]] = []
for entry in entries {
    let pixels = entry.points * entry.scale
    let name = "icon_\(entry.points)x\(entry.points)\(entry.scale == 2 ? "@2x" : "").png"
    try render(size: pixels).write(to: iconSet.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(entry.points)x\(entry.points)", "scale": "\(entry.scale)x", "filename": name])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: iconSet.appendingPathComponent("Contents.json"))
let catalog = iconSet.deletingLastPathComponent().appendingPathComponent("Contents.json")
try Data(#"{"info":{"author":"xcode","version":1}}"#.utf8).write(to: catalog)
print("Wrote \(entries.count) icons to \(iconSet.path)")
