import AppKit
let directory = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath:directory,withIntermediateDirectories:true)
for (name,size) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    let context = NSGraphicsContext(bitmapImageRep:rep)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    context.cgContext.scaleBy(x:CGFloat(size)/1024,y:CGFloat(size)/1024)
    NSColor(calibratedRed:0.94,green:0.91,blue:0.83,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:32,y:32,width:960,height:960),xRadius:210,yRadius:210).fill()
    NSColor(calibratedRed:0.14,green:0.23,blue:0.22,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:157,y:160,width:710,height:700),xRadius:25,yRadius:25).fill()
    for side in 0...1 {
        for i in 0..<245 {
            let x = side == 0 ? CGFloat(157+i) : CGFloat(867-i)
            let light = 0.75+0.24*cos(CGFloat(i)*0.08)
            NSColor(calibratedRed:0.51*light,green:0.18*light,blue:0.25*light,alpha:1).setFill()
            let hem = 165 + 10*sin(CGFloat(i)*0.08)
            NSRect(x:x,y:hem,width:1.5,height:860-hem).fill()
        }
    }
    NSColor(calibratedRed:0.77,green:0.63,blue:0.38,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:129,y:846,width:766,height:21),xRadius:10,yRadius:10).fill()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:directory+"/"+name+".png"))
}
