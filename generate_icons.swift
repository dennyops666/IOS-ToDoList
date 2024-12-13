import Foundation
import CoreGraphics
import CoreText
import CoreFoundation
import ImageIO

let iconSizes = [
    (size: (width: 40.0, height: 40.0), scale: 2, name: "40x40@2x"),
    (size: (width: 60.0, height: 60.0), scale: 3, name: "60x60@3x"),
    (size: (width: 58.0, height: 58.0), scale: 2, name: "58x58@2x"),
    (size: (width: 87.0, height: 87.0), scale: 3, name: "87x87@3x"),
    (size: (width: 80.0, height: 80.0), scale: 2, name: "80x80@2x"),
    (size: (width: 120.0, height: 120.0), scale: 3, name: "120x120@3x"),
    (size: (width: 120.0, height: 120.0), scale: 2, name: "120x120@2x"),
    (size: (width: 180.0, height: 180.0), scale: 3, name: "180x180@3x"),
    (size: (width: 1024.0, height: 1024.0), scale: 1, name: "1024x1024@1x")
]

func generateIcon(width: Double, height: Double, scale: Int, name: String) {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil,
        width: Int(width),
        height: Int(height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    
    // Fill background with blue color (RGB: 0, 122, 255)
    context.setFillColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Draw text "ToDoList"
    let text = "ToDoList" as CFString
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, width * 0.15, nil)
    let attributes = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(colorSpace: colorSpace, components: [1.0, 1.0, 1.0, 1.0])!
    ] as CFDictionary
    
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, text, attributes))
    let lineBounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
    
    let xOffset = (width - lineBounds.width) / 2
    let yOffset = (height + lineBounds.height) / 2
    
    context.textPosition = CGPoint(x: xOffset, y: yOffset)
    CTLineDraw(line, context)
    
    guard let image = context.makeImage() else { return }
    
    let fileManager = FileManager.default
    let projectDir = fileManager.currentDirectoryPath
    let assetsPath = "\(projectDir)/ToDoList/Assets.xcassets/AppIcon.appiconset"
    let fileURL = URL(fileURLWithPath: assetsPath).appendingPathComponent("\(name).png")
    
    if let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        print("Generated icon: \(fileURL.path)")
    }
}

// Generate all icons
for iconSpec in iconSizes {
    generateIcon(
        width: iconSpec.size.width,
        height: iconSpec.size.height,
        scale: iconSpec.scale,
        name: iconSpec.name
    )
}

print("Icon generation complete!")
