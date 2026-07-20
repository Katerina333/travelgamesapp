import AppKit

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> NSColor {
    NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

let W = CGFloat(size)
let full = NSRect(x: 0, y: 0, width: W, height: W)

// --- Sky: warm sunset gradient (top lighter, horizon deeper orange) --------
NSGradient(
    starting: rgb(1.00, 0.72, 0.36),
    ending: rgb(0.98, 0.44, 0.15)
)!.draw(in: full, angle: -90)

let horizon: CGFloat = 430

// --- Sun with soft glow, upper area ---------------------------------------
let sunC = CGPoint(x: 690, y: 720)
for (i, a) in [(160.0, 0.10), (128.0, 0.16), (100.0, 1.0)].enumerated() {
    let r = CGFloat(a.0)
    let col = i == 2 ? rgb(1.0, 0.93, 0.72, 1) : rgb(1.0, 0.95, 0.80, CGFloat(a.1))
    col.setFill()
    NSBezierPath(ovalIn: NSRect(x: sunC.x - r, y: sunC.y - r, width: r*2, height: r*2)).fill()
}

// --- Hills (layered for depth) --------------------------------------------
func hill(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: NSRect(x: cx - w/2, y: cy - h/2, width: w, height: h)).fill()
}
// clip everything below horizon-ish so hills sit on the land
// back hills (darker green)
hill(cx: 250, cy: 250, w: 900, h: 520, color: rgb(0.24, 0.55, 0.36))
hill(cx: 820, cy: 250, w: 820, h: 460, color: rgb(0.24, 0.55, 0.36))
// front ground band (lighter green), rounded top
rgb(0.33, 0.66, 0.42).setFill()
let ground = NSBezierPath()
ground.move(to: NSPoint(x: 0, y: 0))
ground.line(to: NSPoint(x: 0, y: 300))
ground.curve(to: NSPoint(x: W, y: 300),
             controlPoint1: NSPoint(x: 340, y: 250),
             controlPoint2: NSPoint(x: 680, y: 350))
ground.line(to: NSPoint(x: W, y: 0))
ground.close()
ground.fill()

// --- Trees dotting the hills (simple, charming) ---------------------------
func tree(x: CGFloat, y: CGFloat, s: CGFloat) {
    rgb(0.42, 0.30, 0.20).setFill()
    NSBezierPath(roundedRect: NSRect(x: x - 7*s, y: y, width: 14*s, height: 40*s),
                 xRadius: 6*s, yRadius: 6*s).fill()
    rgb(0.20, 0.50, 0.32).setFill()
    NSBezierPath(ovalIn: NSRect(x: x - 42*s, y: y + 24*s, width: 84*s, height: 84*s)).fill()
    rgb(0.26, 0.58, 0.38).setFill()
    NSBezierPath(ovalIn: NSRect(x: x - 30*s, y: y + 40*s, width: 60*s, height: 60*s)).fill()
}
tree(x: 175, y: 250, s: 1.15)
tree(x: 850, y: 235, s: 1.25)
tree(x: 300, y: 150, s: 0.95)

// --- Winding road (clean tapering ribbon into the distance) ---------------
let road = NSBezierPath()
road.move(to: NSPoint(x: 398, y: 0))
// left edge — gentle inward taper, no bulge
road.curve(to: NSPoint(x: 484, y: horizon),
           controlPoint1: NSPoint(x: 412, y: 150),
           controlPoint2: NSPoint(x: 458, y: 300))
// across the narrow far end
road.line(to: NSPoint(x: 540, y: horizon))
// right edge back down
road.curve(to: NSPoint(x: 626, y: 0),
           controlPoint1: NSPoint(x: 566, y: 300),
           controlPoint2: NSPoint(x: 612, y: 150))
road.close()
rgb(0.28, 0.22, 0.18).setFill()
road.fill()

// dashed centre line (perspective: dashes shrink toward horizon)
rgb(1.0, 0.85, 0.42).setFill()
let dashes: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    // x, y, width, height
    (512, 25, 34, 66),
    (512, 145, 26, 50),
    (512, 250, 19, 38),
    (512, 335, 13, 27),
    (512, 400, 9, 18)
]
for d in dashes {
    NSBezierPath(roundedRect: NSRect(x: d.0 - d.2/2, y: d.1, width: d.2, height: d.3),
                 xRadius: d.2/2, yRadius: d.2/2).fill()
}

// --- Soft cloud to balance the sky ----------------------------------------
func cloud(x: CGFloat, y: CGFloat, s: CGFloat) {
    rgb(1, 1, 1, 0.85).setFill()
    for (dx, dy, r) in [(-58.0, 0.0, 46.0), (0.0, 14.0, 60.0), (58.0, 0.0, 48.0), (18.0, -6.0, 50.0)] {
        let rr = CGFloat(r) * s
        NSBezierPath(ovalIn: NSRect(x: x + CGFloat(dx)*s - rr, y: y + CGFloat(dy)*s - rr,
                                    width: rr*2, height: rr*2)).fill()
    }
}
cloud(x: 815, y: 830, s: 0.85)

// --- Plane with dashed vapour trail (air travel) --------------------------
// dashed arc trail
let trail = NSBezierPath()
trail.move(to: NSPoint(x: 150, y: 690))
trail.curve(to: NSPoint(x: 430, y: 880),
            controlPoint1: NSPoint(x: 250, y: 720),
            controlPoint2: NSPoint(x: 330, y: 780))
trail.lineWidth = 16
trail.lineCapStyle = .round
let pattern: [CGFloat] = [4, 34]
trail.setLineDash(pattern, count: 2, phase: 0)
rgb(1, 1, 1, 0.92).setStroke()
trail.stroke()

// paper plane (simple bold glyph) at trail end, pointing up-right
func planeGlyph(at p: CGPoint, scale s: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: p.x, y: p.y)
    ctx.rotate(by: .pi / 6) // tilt up-right
    let body = NSBezierPath()
    body.move(to: NSPoint(x: -70*s, y: 0))
    body.line(to: NSPoint(x: 78*s, y: 40*s))
    body.line(to: NSPoint(x: 30*s, y: 0))
    body.line(to: NSPoint(x: 78*s, y: -40*s))
    body.close()
    rgb(1, 1, 1, 1).setFill()
    body.fill()
    // inner fold shadow
    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 30*s, y: 0))
    fold.line(to: NSPoint(x: 78*s, y: 40*s))
    fold.line(to: NSPoint(x: 12*s, y: 12*s))
    fold.close()
    rgb(0.86, 0.90, 0.95, 1).setFill()
    fold.fill()
    ctx.restoreGState()
}
planeGlyph(at: CGPoint(x: 445, y: 885), scale: 1.0)

NSGraphicsContext.restoreGraphicsState()

// --- Flatten onto opaque background (marketing icon: no alpha) -------------
let cg = rep.cgImage!
let outCtx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
outCtx.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: W))
let out = NSBitmapImageRep(cgImage: outCtx.makeImage()!)
let png = out.representation(using: .png, properties: [:])!
let path = CommandLine.arguments[1]
try! png.write(to: URL(fileURLWithPath: path))
print("wrote \(path)")
