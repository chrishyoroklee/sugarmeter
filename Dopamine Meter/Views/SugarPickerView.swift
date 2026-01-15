import SwiftUI

struct SugarPickerView: View {
    let items: [SugarItem]
    var onSelect: (SugarItem, SugarItemSize) -> Void

    @State private var selectedItem: SugarItem?

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        SugarPickerItemCard(
                            item: item,
                            isSelected: selectedItem?.id == item.id
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedItem = item
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            Text("Tap a treat to pick a size.")
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .sheet(item: $selectedItem, onDismiss: {
            selectedItem = nil
        }) { item in
            SugarPickerSizeSheet(item: item) { size in
                onSelect(item, size)
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct SugarPickerItemCard: View {
    let item: SugarItem
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AppTheme.primaryLight.opacity(0.85) : AppTheme.secondary.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? AppTheme.primary : AppTheme.primary.opacity(0.35), lineWidth: 1)
                        )

                    VStack(spacing: 6) {
                        if let imageName = item.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 46)
                                .shadow(color: AppTheme.textPrimary.opacity(0.15), radius: 4, x: 0, y: 2)
                        }

                        Text(item.name)
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .frame(width: 100, height: 100)

                Text("\(item.sugarGrams)g")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SugarPickerSizeSheet: View {
    let item: SugarItem
    var onSelect: (SugarItemSize) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(item.name)
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 10) {
                ForEach(SugarItemSize.allCases) { size in
                    Button {
                        onSelect(size)
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Text(size.label)
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                            Text("\(grams(for: size))g")
                                .font(.custom("AvenirNext-Medium", size: 10))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.primaryLight.opacity(0.6))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func grams(for size: SugarItemSize) -> Int {
        Int((Double(item.sugarGrams) * size.multiplier).rounded())
    }
}
