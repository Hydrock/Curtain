// Render the real AppKit views and cloth simulation for documentation.
// Run from the project root. Requires a graphical macOS session.
import AppKit
let app = NSApplication.shared
Localization.shared.language = .english
let width = 900, height = 620, titleHeight: CGFloat = 38
let demo = DemoView(frame: NSRect(x:0,y:0,width:width,height:height-Int(titleHeight)))
let fabric = FabricView(frame: demo.frame)
fabric.tint = NSColor(calibratedRed:0.43, green:0.16, blue:0.23, alpha:1)
let manager = FileManager.default
try manager.createDirectory(atPath: ".build/demo-frames", withIntermediateDirectories:true)
try manager.createDirectory(atPath: "docs/assets", withIntermediateDirectories:true)
func render() -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    let original = NSGraphicsContext(bitmapImageRep:bitmap)!
    let ctx = original.cgContext
    NSGraphicsContext.saveGraphicsState()
    ctx.translateBy(x:0,y:CGFloat(height)); ctx.scaleBy(x:1,y:-1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext:ctx, flipped:true)
    NSColor(calibratedWhite:0.97,alpha:1).setFill(); NSRect(x:0,y:0,width:width,height:height).fill()
    for (x,color) in [(CGFloat(18),NSColor.systemRed),(CGFloat(40),NSColor.systemYellow),(CGFloat(62),NSColor.systemGreen)] {
        color.setFill(); NSBezierPath(ovalIn:NSRect(x:x,y:12,width:13,height:13)).fill()
    }
    (L("Curtain · pull the fabric", "Curtain · потяните за ткань") as NSString).draw(at:CGPoint(x:94,y:10),withAttributes:[.font:NSFont.systemFont(ofSize:14,weight:.semibold),.foregroundColor:NSColor.darkGray])
    ctx.translateBy(x:0,y:titleHeight)
    demo.draw(demo.bounds)
    // Transparent panels are composited over the demo; clearing the fabric's
    // backing store must not erase the window beneath it.
    ctx.beginTransparencyLayer(auxiliaryInfo:nil)
    fabric.draw(fabric.bounds)
    ctx.endTransparencyLayer()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using:.png,properties:[:])!
}
for frame in 0..<150 {
    if frame == 15 { fabric.setOpen(true) }
    if frame >= 65 && frame < 90 {
        let t = CGFloat(frame-65)/24
        let point = CGPoint(x:45+t*270,y:280+t*60)
        if frame == 65, let index = fabric.left.nearest(to:point) { fabric.left.grab(index:index,at:point) }
        else { fabric.left.moveHand(point) }
    }
    if frame == 90 { fabric.left.release(); fabric.left.open = false }
    if frame == 110 { fabric.right.open = false }
    fabric.tick(); fabric.tick()
    let png = render()
    try png.write(to:URL(fileURLWithPath:String(format:".build/demo-frames/frame%03d.png",frame)))
    if frame == 20 { try png.write(to:URL(fileURLWithPath:"docs/assets/curtain.png")) }
}
print("Rendered native AppKit preview and 150 cloth animation frames")
