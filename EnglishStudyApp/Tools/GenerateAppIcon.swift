import AppKit

let outputPath = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.92, alpha: 1),
    NSColor(calibratedRed: 0.02, green: 0.68, blue: 0.56, alpha: 1)
])!
gradient.draw(in: rect, angle: 315)

let bookRect = NSRect(x: 188, y: 190, width: 648, height: 644)
let bookPath = NSBezierPath(roundedRect: bookRect, xRadius: 132, yRadius: 132)
NSColor.white.withAlphaComponent(0.94).setFill()
bookPath.fill()

let spine = NSBezierPath(roundedRect: NSRect(x: 256, y: 250, width: 86, height: 524), xRadius: 43, yRadius: 43)
NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.92, alpha: 0.92).setFill()
spine.fill()

let lineColor = NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.92, alpha: 0.18)
lineColor.setStroke()
for y in stride(from: 350, through: 690, by: 86) {
    let line = NSBezierPath()
    line.lineWidth = 18
    line.lineCapStyle = .round
    line.move(to: NSPoint(x: 410, y: y))
    line.line(to: NSPoint(x: 710, y: y))
    line.stroke()
}

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 210, weight: .black),
    .foregroundColor: NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.92, alpha: 1),
    .paragraphStyle: paragraph
]
"E".draw(in: NSRect(x: 350, y: 392, width: 330, height: 260), withAttributes: textAttributes)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Unable to render app icon")
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
