import SwiftUI

struct HaneyOverlayView: View {
    let quote: HaneyQuote
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(alignment: .trailing, spacing: 0) {
                Spacer()

                // Speech bubble
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\"\(quote.text)\"")
                            .font(.body.bold())
                            .multilineTextAlignment(.leading)

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(quote.attribution)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Haney cutout
                Image("HaneyImage")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)
                    .padding(.trailing, 8)
            }
            .offset(x: isVisible ? 0 : 300, y: isVisible ? 0 : 200)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                isVisible = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
