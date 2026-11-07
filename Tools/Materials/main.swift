// Render the actual material renderer over the actual demo view.
import AppKit
let app = NSApplication.shared
Localization.shared.language = .english
let width = 1240, height = 620
let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
let ctx = NSGraphicsContext(bitmapImageRep:bitmap)!.cgContext
NSGraphicsContext.saveGraphicsState()
ctx.translateBy(x:0,y:CGFloat(height)); ctx.scaleBy(x:1,y:-1)
NSGraphicsContext.current = NSGraphicsContext(cgContext:ctx,flipped:true)
NSColor(calibratedRed:0.955,green:0.94,blue:0.90,alpha:1).setFill(); NSRect(x:0,y:0,width:width,height:height).fill()
for (index,material) in FabricMaterial.allCases.enumerated() {
    ctx.saveGState(); ctx.translateBy(x:CGFloat(20+index*410),y:0)
    (material.englishName as NSString).draw(at:CGPoint(x:8,y:14),withAttributes:[.font:NSFont.systemFont(ofSize:19,weight:.medium),.foregroundColor:NSColor.darkGray])
    ctx.translateBy(x:0,y:48)
    let demo = DemoView(frame:NSRect(x:0,y:0,width:390,height:550))
    let fabric = FabricView(frame:demo.frame); fabric.material = material
    fabric.tint = NSColor(calibratedRed:0.43,green:0.16,blue:0.23,alpha:1)
    for _ in 0..<180 { fabric.tick() }
    demo.draw(demo.bounds)
    ctx.beginTransparencyLayer(auxiliaryInfo:nil); fabric.draw(fabric.bounds); ctx.endTransparencyLayer()
    ctx.restoreGState()
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"docs/assets/materials.png"))
print("Rendered material comparison")
