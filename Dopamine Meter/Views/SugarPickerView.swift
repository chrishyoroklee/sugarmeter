import SwiftUI

struct SugarPickerView: View {
    let items: [SugarItem]
    var onSelect: (SugarItem, SugarItemSize) -> Void
    var onAddCustom: (String, Int) -> Void
    var onRemoveCustom: (SugarItem) -> Void

    @State private var selectedItem: SugarItem?
    @State private var isAddCustomPresented = false
    @State private var itemPendingRemoval: SugarItem?

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        SugarPickerItemCard(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onLongPress: {
                                guard item.isCustom else { return }
                                itemPendingRemoval = item
                            }
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedItem = item
                            }
                        }
                    }

                    AddCustomTreatCard {
                        isAddCustomPresented = true
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
        .sheet(isPresented: $isAddCustomPresented) {
            CustomTreatForm(
                existingNames: Set(items.map { $0.name.lowercased() })
            ) { name, grams in
                onAddCustom(name, grams)
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Remove custom treat?", isPresented: Binding(
            get: { itemPendingRemoval != nil },
            set: { if !$0 { itemPendingRemoval = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let item = itemPendingRemoval {
                    onRemoveCustom(item)
                }
                itemPendingRemoval = nil
            }
            Button("Cancel", role: .cancel) {
                itemPendingRemoval = nil
            }
        } message: {
            if let item = itemPendingRemoval {
                Text("Delete \(item.name)?")
            }
        }
    }
}

private struct SugarPickerItemCard: View {
    let item: SugarItem
    let isSelected: Bool
    var onLongPress: () -> Void
    var onTap: () -> Void

    var body: some View {
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
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.35, perform: onLongPress)
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

private struct AddCustomTreatCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.primary.opacity(0.35), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    )
                    .frame(width: 100, height: 100)

                Text("Add")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CustomTreatForm: View {
    let existingNames: Set<String>
    var onSave: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var nameText = ""
    @State private var selectedGrams = 15

    private let gramOptions = Array(1...70)

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Custom Treat")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Enter treat name", text: $nameText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Sugar grams")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)

                Picker("Sugar grams", selection: $selectedGrams) {
                    ForEach(gramOptions, id: \.self) { grams in
                        Text("\(grams)g")
                            .tag(grams)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, minHeight: 120)
                .clipped()

                Text("Selected: \(selectedGrams)g")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if shouldShowDuplicateWarning {
                Text("That name already exists.")
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(AppTheme.primary)
            }

            Button(action: save) {
                Text("Save Treat")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(canSave ? AppTheme.primary : AppTheme.primary.opacity(0.5))
                    )
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var trimmedName: String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !existingNames.contains(trimmedName.lowercased())
    }

    private var shouldShowDuplicateWarning: Bool {
        !trimmedName.isEmpty && existingNames.contains(trimmedName.lowercased())
    }

    private func save() {
        guard canSave else { return }
        onSave(trimmedName, selectedGrams)
        dismiss()
    }
}
