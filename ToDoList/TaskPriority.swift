import Foundation
import UIKit

public enum TaskPriority: Int16, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    public var title: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    public var color: UIColor {
        switch self {
        case .low:
            return .systemGreen
        case .medium:
            return .systemYellow
        case .high:
            return .systemRed
        }
    }
}
