import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func renderIcon(size: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    let background = NSBezierPath(roundedRect: NSRect(x: 96, y: 96, width: 832, height: 832),
                                  xRadius: 187, yRadius: 187)
    NSGradient(starting: NSColor(srgbRed: 0.11, green: 0.66, blue: 0.57, alpha: 1),
               ending: NSColor(srgbRed: 0.02, green: 0.33, blue: 0.36, alpha: 1))!
        .draw(in: background, angle: -64)

    let page = NSBezierPath()
    page.move(to: NSPoint(x: 353, y: 768))
    page.line(to: NSPoint(x: 538, y: 768))
    page.line(to: NSPoint(x: 696, y: 610))
    page.line(to: NSPoint(x: 696, y: 313))
    page.curve(to: NSPoint(x: 640, y: 257), controlPoint1: NSPoint(x: 696, y: 282), controlPoint2: NSPoint(x: 671, y: 257))
    page.line(to: NSPoint(x: 353, y: 257))
    page.curve(to: NSPoint(x: 297, y: 313), controlPoint1: NSPoint(x: 322, y: 257), controlPoint2: NSPoint(x: 297, y: 282))
    page.line(to: NSPoint(x: 297, y: 712))
    page.curve(to: NSPoint(x: 353, y: 768), controlPoint1: NSPoint(x: 297, y: 743), controlPoint2: NSPoint(x: 322, y: 768))
    page.close()
    NSColor.white.setFill()
    page.fill()

    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 538, y: 768))
    fold.line(to: NSPoint(x: 696, y: 610))
    fold.line(to: NSPoint(x: 571, y: 610))
    fold.curve(to: NSPoint(x: 538, y: 643), controlPoint1: NSPoint(x: 553, y: 610), controlPoint2: NSPoint(x: 538, y: 625))
    fold.close()
    NSColor(srgbRed: 0.75, green: 0.89, blue: 0.87, alpha: 1).setFill()
    fold.fill()

    NSColor(srgbRed: 0.05, green: 0.48, blue: 0.42, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 390, y: 437, width: 209, height: 46), xRadius: 23, yRadius: 23).fill()
    NSBezierPath(roundedRect: NSRect(x: 471.5, y: 355.5, width: 46, height: 209), xRadius: 23, yRadius: 23).fill()
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try renderIcon(size: size).write(to: output.appendingPathComponent("icon_\(size)x\(size).png"))
    try renderIcon(size: size * 2).write(to: output.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
