import AppKit
import Foundation

enum ImageResizer {
    /// Resize PNG data with optional Retina downscale and max pixel size constraint.
    /// - Parameters:
    ///   - data: Raw PNG data from screencapture
    ///   - downscaleToLogical: If true, downscale Retina 2x to 1x (point size)
    ///   - maxSize: Maximum pixel size for the longest edge (0 = no limit)
    /// - Returns: Resized PNG data
    static func resize(_ data: Data, downscaleToLogical: Bool = true, maxSize: Int = 0) -> Data {
        guard let imageRep = NSBitmapImageRep(data: data) else { return data }

        let pixelW = imageRep.pixelsWide
        let pixelH = imageRep.pixelsHigh

        // Step 1: Determine base target dimensions
        var targetW: Int
        var targetH: Int

        if downscaleToLogical {
            // Use point size (logical 1x resolution)
            targetW = Int(imageRep.size.width)
            targetH = Int(imageRep.size.height)
        } else {
            // Keep original pixel dimensions
            targetW = pixelW
            targetH = pixelH
        }

        // Step 2: Apply max-size constraint on the longest edge
        if maxSize > 0 {
            let longest = max(targetW, targetH)
            if longest > maxSize {
                let scale = Double(maxSize) / Double(longest)
                targetW = Int(Double(targetW) * scale)
                targetH = Int(Double(targetH) * scale)
            }
        }

        // Skip resize if dimensions unchanged
        if targetW == pixelW && targetH == pixelH {
            return data
        }

        guard let resized = resizeBitmap(imageRep, width: targetW, height: targetH) else {
            return data
        }

        return resized
    }

    private static func resizeBitmap(_ source: NSBitmapImageRep, width: Int, height: Int) -> Data? {
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        bitmapRep.size = NSSize(width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        let sourceImage = NSImage(size: NSSize(width: source.pixelsWide, height: source.pixelsHigh))
        sourceImage.addRepresentation(source)
        sourceImage.draw(
            in: NSRect(x: 0, y: 0, width: width, height: height),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        return bitmapRep.representation(using: .png, properties: [:])
    }
}
