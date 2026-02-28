import SwiftUI

struct WiggleModifier: ViewModifier {
    let enabled: Bool

    @State private var rotate = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(enabled ? (rotate ? 1.5 : -1.5) : 0))
            .animation(
                enabled
                ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                : .default,
                value: rotate
            )
            .onAppear {
                if enabled { rotate.toggle() }
            }
            .onChange(of: enabled) { _, newValue in
                if newValue {
                    rotate = false
                    rotate.toggle()
                }
            }
    }
}

extension View {
    func wiggle(_ enabled: Bool) -> some View {
        modifier(WiggleModifier(enabled: enabled))
    }
}
