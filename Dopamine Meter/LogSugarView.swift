import SwiftUI

struct LogSugarView: View {
    let items: [SugarItem]
    var onSelect: (SugarItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Log Sugar")
                            .font(.custom("AvenirNext-Heavy", size: 26))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Pick a treat")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            )
                    }
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(items) { item in
                            LogSugarItemCard(item: item) {
                                onSelect(item)
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
    }
}

private struct LogSugarItemCard: View {
    let item: SugarItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.secondary.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.primary.opacity(0.45), lineWidth: 1)
                        )

                    Text(item.name)
                        .font(.custom("AvenirNext-DemiBold", size: 15))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .aspectRatio(1, contentMode: .fit)

                Text("\(item.sugarGrams)g")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
