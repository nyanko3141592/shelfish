import Foundation

enum EdgePosition: String, CaseIterable {
    case right
    case left
    case top
    case bottom

    var isVertical: Bool {
        self == .left || self == .right
    }

    var displayName: String {
        switch self {
        case .right: return "Right"
        case .left: return "Left"
        case .top: return "Top"
        case .bottom: return "Bottom"
        }
    }

    private static let key = "ShelfEdgePosition"

    static func load() -> EdgePosition {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let pos = EdgePosition(rawValue: raw) else {
            return .right
        }
        return pos
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: EdgePosition.key)
    }
}
