import SwiftUI

struct LevelMessageView: View {
    let message: LevelMessage
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppTheme.textPrimary.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: AppTheme.textPrimary.opacity(0.2), radius: 12, x: 0, y: 6)

                VStack(spacing: 10) {
                    Text(message.title)
                        .font(.custom("AvenirNext-Heavy", size: 20))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(message.body)
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.secondary.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.primary.opacity(0.6), lineWidth: 1)
                        )
                )

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary)
                        )
                }
            }
            .padding(.horizontal, 28)
        }
    }
}
