import UIKit

class IconGenerator {
    static func generateAppIcons() {
        let iconSizes = [
            (size: CGSize(width: 40, height: 40), scale: 2, name: "40x40@2x"),
            (size: CGSize(width: 60, height: 60), scale: 3, name: "60x60@3x"),
            (size: CGSize(width: 58, height: 58), scale: 2, name: "58x58@2x"),
            (size: CGSize(width: 87, height: 87), scale: 3, name: "87x87@3x"),
            (size: CGSize(width: 80, height: 80), scale: 2, name: "80x80@2x"),
            (size: CGSize(width: 120, height: 120), scale: 3, name: "120x120@3x"),
            (size: CGSize(width: 120, height: 120), scale: 2, name: "120x120@2x"),
            (size: CGSize(width: 180, height: 180), scale: 3, name: "180x180@3x"),
            (size: CGSize(width: 1024, height: 1024), scale: 1, name: "1024x1024@1x")
        ]
        
        for iconSpec in iconSizes {
            generateIcon(size: iconSpec.size, scale: iconSpec.scale, name: iconSpec.name)
        }
    }
    
    private static func generateIcon(size: CGSize, scale: Int, name: String) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // 背景颜色
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 绘制文字 "ToDoList"
            let text = "ToDoList"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.15, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        if let data = image.pngData() {
            let fileManager = FileManager.default
            let projectDir = fileManager.currentDirectoryPath
            let assetsPath = "\(projectDir)/ToDoList/Assets.xcassets/AppIcon.appiconset"
            let fileURL = URL(fileURLWithPath: assetsPath).appendingPathComponent("\(name).png")
            try? data.write(to: fileURL)
            print("Generated icon: \(fileURL.path)")
        }
    }
}