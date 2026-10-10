// TMovie app icon: three translucent play triangles offset like split projector light.
// Regenerate: swiftc -O Tools/make_icon.swift -o /tmp/make_icon && /tmp/make_icon App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// Rounded play triangle of height `h` around (cx, cy).
func play(cx: CGFloat, cy: CGFloat, h: CGFloat, r: CGFloat) -> CGPath {
    let w = h * 0.9
    let a = CGPoint(x: cx - w * 0.4, y: cy - h / 2), b = CGPoint(x: cx - w * 0.4, y: cy + h / 2), c = CGPoint(x: cx + w * 0.6, y: cy)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2))
    p.addArc(tangent1End: b, tangent2End: c, radius: r)
    p.addArc(tangent1End: c, tangent2End: a, radius: r)
    p.addArc(tangent1End: a, tangent2End: b, radius: r)
    p.closeSubpath()
    return p
}

let bg = CGGradient(colorsSpace: cs, colors: [rgb(0x1A1F2E), rgb(0x05070B)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: 512, y: 600), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 760, options: [.drawsAfterEndLocation])

// Screen blending turns the overlaps white, like stacked coloured light.
ctx.setBlendMode(.screen)
for (dx, dy, color) in [(-34.0, 26.0, 0x14D6C4 as UInt32), (30, 18, 0x8A5CFF), (0, -30, 0xFF4F8B)] {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 70, color: rgb(color, 0.8))
    ctx.addPath(play(cx: 530 + dx, cy: 512 + dy, h: 520, r: 70))
    ctx.setFillColor(rgb(color, 0.85))
    ctx.fillPath()
    ctx.restoreGState()
}

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
