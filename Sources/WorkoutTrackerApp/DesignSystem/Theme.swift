import SwiftUI

enum AccentColorOption: String, CaseIterable, Identifiable {
    case pink
    case blue
    case green
    case orange
    case red
    case purple
    case teal
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pink: return "Pink"
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .teal: return "Teal"
        case .custom: return "Custom"
        }
    }

    var color: Color {
        switch self {
        case .pink:
            return Theme.defaultAccent
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .red:
            return .red
        case .purple:
            return .purple
        case .teal:
            return .teal
        case .custom:
            return Theme.customAccentColor
        }
    }
}

extension Notification.Name {
    static let themeAccentDidChange = Notification.Name("themeAccentDidChange")
}

enum Theme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let surface = Color.white
    static let mutedSurface = Color(red: 0.92, green: 0.94, blue: 0.96)
    static let primaryText = Color.black
    static let secondaryText = Color(red: 0.35, green: 0.38, blue: 0.43)
    static let defaultAccent = Color(red: 0.92, green: 0.23, blue: 0.54)
    static var accent: Color {
        accentOption.color
    }
    static let warning = Color(red: 0.84, green: 0.24, blue: 0.24)
    static let border = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.06)

    private static let accentOptionKey = "accentOptionRaw"
    private static let customAccentRedKey = "customAccentRed"
    private static let customAccentGreenKey = "customAccentGreen"
    private static let customAccentBlueKey = "customAccentBlue"
    private static let customAccentAlphaKey = "customAccentAlpha"

    static var accentOption: AccentColorOption {
        let raw = UserDefaults.standard.string(forKey: accentOptionKey) ?? AccentColorOption.pink.rawValue
        return AccentColorOption(rawValue: raw) ?? .pink
    }

    static var customAccentColor: Color {
        let defaults = UserDefaults.standard
        let hasCustom =
            defaults.object(forKey: customAccentRedKey) != nil
            && defaults.object(forKey: customAccentGreenKey) != nil
            && defaults.object(forKey: customAccentBlueKey) != nil

        guard hasCustom else { return defaultAccent }

        let red = defaults.double(forKey: customAccentRedKey)
        let green = defaults.double(forKey: customAccentGreenKey)
        let blue = defaults.double(forKey: customAccentBlueKey)
        let alpha = defaults.object(forKey: customAccentAlphaKey) == nil
            ? 1.0
            : defaults.double(forKey: customAccentAlphaKey)
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static func updateAccentOption(_ option: AccentColorOption) {
        UserDefaults.standard.set(option.rawValue, forKey: accentOptionKey)
        NotificationCenter.default.post(name: .themeAccentDidChange, object: nil)
    }

    static func updateCustomAccentColor(_ color: Color) {
        let components = color.rgbaComponents ?? defaultAccent.rgbaComponents ?? (0.92, 0.23, 0.54, 1)
        let defaults = UserDefaults.standard
        defaults.set(components.0, forKey: customAccentRedKey)
        defaults.set(components.1, forKey: customAccentGreenKey)
        defaults.set(components.2, forKey: customAccentBlueKey)
        defaults.set(components.3, forKey: customAccentAlphaKey)
        NotificationCenter.default.post(name: .themeAccentDidChange, object: nil)
    }
}

private extension Color {
    var rgbaComponents: (Double, Double, Double, Double)? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #elseif canImport(AppKit)
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        return (
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent),
            Double(nsColor.alphaComponent)
        )
        #else
        return nil
        #endif
    }
}

extension Font {
    static let dashboardDate = Font.system(size: 14, weight: .medium, design: .rounded)
    static let dashboardTitle = Font.system(size: 38, weight: .black, design: .rounded)
    static let sectionTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let rowTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let rowBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let monoMetric = Font.system(size: 26, weight: .bold, design: .monospaced)
}

extension View {
    func appCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: Theme.shadow, radius: 8, y: 3)
    }
}
