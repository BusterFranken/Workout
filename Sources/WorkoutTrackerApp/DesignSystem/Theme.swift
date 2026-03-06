import SwiftUI

enum Theme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let surface = Color.white
    static let mutedSurface = Color(red: 0.92, green: 0.94, blue: 0.96)
    static let primaryText = Color.black
    static let secondaryText = Color(red: 0.35, green: 0.38, blue: 0.43)
    static let accent = Color(red: 0.92, green: 0.23, blue: 0.54)
    static let warning = Color(red: 0.84, green: 0.24, blue: 0.24)
    static let border = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.06)
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
