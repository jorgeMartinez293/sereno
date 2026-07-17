import SwiftUI
import AppKit

/// Replicates the logic of get_color.py natively in Swift.
/// Returns the dominant pastel color of an image (ignores dark/transparent pixels).
enum ColorExtractor {
    static func dominantColor(for url: URL) -> Color {
        guard let nsImage = NSImage(contentsOf: url),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return .red }

        let w = cgImage.width, h = cgImage.height
        let bpp = 4
        var raw = [UInt8](repeating: 0, count: h * w * bpp)

        guard let ctx = CGContext(
            data: &raw, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * bpp,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .red }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        let darkThreshold = 40
        var counts: [UInt32: Int] = [:]
        let step = 4

        for y in stride(from: 0, to: h, by: step) {
            for x in stride(from: 0, to: w, by: step) {
                let i = (y * w + x) * bpp
                let r = Int(raw[i]), g = Int(raw[i+1]), b = Int(raw[i+2]), a = Int(raw[i+3])
                guard a >= 128 else { continue }                       // transparent
                guard r >= darkThreshold || g >= darkThreshold || b >= darkThreshold
                else { continue }                                       // too dark
                // Quantize to 4 bits per channel
                let key = (UInt32(r >> 4) << 8) | (UInt32(g >> 4) << 4) | UInt32(b >> 4)
                counts[key, default: 0] += 1
            }
        }

        guard let dominant = counts.max(by: { $0.value < $1.value })?.key else { return .red }

        // Unpack quantized + apply pastel factor 0.4 (same as get_color.py)
        let pastel = 0.4
        let r = Double((dominant >> 8) & 0xF) / 15.0
        let g = Double((dominant >> 4) & 0xF) / 15.0
        let b = Double(dominant       & 0xF) / 15.0
        return Color(
            red:   r + (1 - r) * pastel,
            green: g + (1 - g) * pastel,
            blue:  b + (1 - b) * pastel
        )
    }
}
