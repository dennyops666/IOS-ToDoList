import UIKit

class IconGenerator {
    static func generateIcon(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // 确保使用 1.0 的缩放比例
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024), format: format)
        
        return renderer.image { context in
            // 创建渐变背景
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1024, height: 1024))
            gradientLayer.colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemIndigo.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            // 渲染渐变到上下文
            gradientLayer.render(in: context.cgContext)
            
            // 添加文本
            let text = "ToDoList"
            let fontSize = 1024 * 0.25 // 文字大小为图标尺寸的 25%
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
                .foregroundColor: UIColor.white,
                .strokeWidth: -3.0,
                .strokeColor: UIColor.white.withAlphaComponent(0.3)
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (1024 - textSize.width) / 2,
                y: (1024 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            // 添加阴影
            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 2),
                blur: 4,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    static func generateIcon() {
        // 只生成 1024x1024 的图标
        let size = CGSize(width: 1024, height: 1024)
        let icon = generateIcon(size: size)
        
        // 使用项目目录
        let projectPath = "./ToDoList/Assets.xcassets/AppIcon.appiconset"
        
        do {
            // 确保目录存在
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: projectPath), withIntermediateDirectories: true)
            
            // 生成图标文件
            if let data = icon.pngData() {
                let iconPath = "\(projectPath)/1024x1024@1x.png"
                try data.write(to: URL(fileURLWithPath: iconPath))
                print("✓ 已生成图标：\(iconPath)")
                
                // 创建 Contents.json
                let contentsJSON = """
                {
                  "images" : [
                    {
                      "filename" : "1024x1024@1x.png",
                      "idiom" : "ios-marketing",
                      "scale" : "1x",
                      "size" : "1024x1024"
                    }
                  ],
                  "info" : {
                    "version" : 1,
                    "author" : "xcode"
                  }
                }
                """
                
                let contentsPath = "\(projectPath)/Contents.json"
                try contentsJSON.write(to: URL(fileURLWithPath: contentsPath), atomically: true, encoding: .utf8)
                print("✓ 已生成配置文件：\(contentsPath)")
                
                print("\n图标已直接生成到项目目录：")
                print("\(projectPath)")
            }
        } catch {
            print("\n❌ 错误：\(error.localizedDescription)")
        }
    }
} 