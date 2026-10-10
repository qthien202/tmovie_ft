import CoreImage
import SwiftUI
import UIKit

/// Average colour of an image, brightened and saturated for use as a tint.
public enum ColorSampler {
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    public static func tint(of url: URL?) async -> Color? {
        guard let url, let data = try? await URLSession.shared.data(from: url).0, let image = CIImage(data: data),
              let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: image, kCIInputExtentKey: CIVector(cgRect: image.extent)]),
              let output = filter.outputImage
        else { return nil }
        var px = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &px, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0
        UIColor(red: CGFloat(px[0]) / 255, green: CGFloat(px[1]) / 255, blue: CGFloat(px[2]) / 255, alpha: 1)
            .getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return Color(hue: h, saturation: min(1, s * 1.6 + 0.15), brightness: max(0.55, min(0.9, b * 1.5)))
    }
}
