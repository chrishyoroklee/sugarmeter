import SwiftUI

struct LogSugarView: View {
    let items: [SugarItem]
    var onSelect: (SugarItem, SugarItemSize) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItemID: UUID?

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
                            LogSugarItemCard(
                                item: item,
                                isExpanded: expandedItemID == item.id,
                                onExpand: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        expandedItemID = expandedItemID == item.id ? nil : item.id
                                    }
                                },
                                onSelect: { size in
                                    onSelect(item, size)
                                    dismiss()
                                }
                            )
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
    let isExpanded: Bool
    var onExpand: () -> Void
    var onSelect: (SugarItemSize) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onExpand) {
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
            }
            .buttonStyle(.plain)

            Text("\(item.sugarGrams)g")
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(AppTheme.textSecondary)

            if isExpanded {
                VStack(spacing: 8) {
                    Text("Pick a size")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        ForEach(SugarItemSize.allCases) { size in
                            Button {
                                onSelect(size)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(size.shortLabel)
                                        .font(.custom("AvenirNext-DemiBold", size: 12))
                                    Text("\(grams(for: size))g")
                                        .font(.custom("AvenirNext-Medium", size: 10))
                                }
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.primaryLight.opacity(0.6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func grams(for size: SugarItemSize) -> Int {
        Int((Double(item.sugarGrams) * size.multiplier).rounded())
    }
}
