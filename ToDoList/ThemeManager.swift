import UIKit

enum ThemeMode: String {
    case light = "light"
    case dark = "dark"
}

class ThemeManager {
    static let shared = ThemeManager()
    
    private let themeKey = "selectedTheme"
    private let defaults = UserDefaults.standard
    
    // 颜色定义
    struct Colors {
        static let primaryLight = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        static let primaryDark = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
        
        static let backgroundLight = UIColor.systemBackground
        static let backgroundDark = UIColor.systemBackground
        
        static let textLight = UIColor.label
        static let textDark = UIColor.label
    }
    
    // 当前主题模式
    var currentTheme: ThemeMode {
        get {
            if let savedTheme = defaults.string(forKey: themeKey),
               let theme = ThemeMode(rawValue: savedTheme) {
                return theme
            }
            return .light
        }
        set {
            defaults.set(newValue.rawValue, forKey: themeKey)
            applyTheme(newValue)
        }
    }
    
    private init() {}
    
    // 应用主题
    func applyTheme(_ theme: ThemeMode) {
        switch theme {
        case .light:
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        case .dark:
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    // 获取当前主题下的颜色
    func color(for style: UIUserInterfaceStyle) -> (primary: UIColor, background: UIColor, text: UIColor) {
        switch style {
        case .dark:
            return (Colors.primaryDark, Colors.backgroundDark, Colors.textDark)
        default:
            return (Colors.primaryLight, Colors.backgroundLight, Colors.textLight)
        }
    }
}