import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.backgroundTop,
                    AppTheme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: AppTheme.textPrimary.opacity(0.2), radius: 12, x: 0, y: 8)
                    .scaleEffect(pulse ? 1.03 : 0.98)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                Text("SugaMeter")
                    .font(.custom("AvenirNext-Heavy", size: 36))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .onAppear {
            pulse = true
        }
    }
}
