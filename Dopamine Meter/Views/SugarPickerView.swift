import SwiftUI

struct SugarPickerView: View {
    let items: [SugarItem]
    let libraryItems: [SugarItem]
    var onSelect: (SugarItem, SugarItemSize) -> Void
    var onSelectCustom: (SugarItem, Int) -> Void
    var onAddCustom: (String, Int, SugarItemCategory) -> Void
    var onRemoveCustom: (SugarItem) -> Void

    @State private var selectedItem: SugarItem?
    @State private var isAddCustomPresented = false
    @State private var isLibraryPresented = false
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

            HStack {
                Spacer(minLength: 0)
                Button {
                    isLibraryPresented = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.primary)
                        Text("More Options")
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                Spacer(minLength: 0)
            }
        }
        .sheet(item: $selectedItem, onDismiss: {
            selectedItem = nil
        }) { item in
            SugarPickerSizeSheet(item: item) { size in
                onSelect(item, size)
            } onSelectCustom: { grams in
                onSelectCustom(item, grams)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddCustomPresented) {
            CustomTreatForm(
                existingNames: Set(libraryItems.map { $0.name.lowercased() })
            ) { name, grams, category in
                onAddCustom(name, grams, category)
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isLibraryPresented) {
            SugarPickerLibraryView(
                items: libraryItems,
                onSelect: onSelect,
                onSelectCustom: onSelectCustom,
                onAddCustom: onAddCustom,
                onRemoveCustom: onRemoveCustom
            )
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
    var onSelectCustom: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var customGrams: Double

    init(
        item: SugarItem,
        onSelect: @escaping (SugarItemSize) -> Void,
        onSelectCustom: @escaping (Int) -> Void
    ) {
        self.item = item
        self.onSelect = onSelect
        self.onSelectCustom = onSelectCustom
        _customGrams = State(initialValue: Double(item.sugarGrams))
    }

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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Custom")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(customGrams))g")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Slider(value: $customGrams, in: customRange, step: 1)

                Button {
                    onSelectCustom(Int(customGrams))
                    dismiss()
                } label: {
                    Text("Log Custom")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private func grams(for size: SugarItemSize) -> Int {
        Int((Double(item.sugarGrams) * size.multiplier).rounded())
    }

    private var customRange: ClosedRange<Double> {
        let maxValue = max(Double(item.sugarGrams) * 2.0, 50)
        return 1...min(maxValue, 120)
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
    var onSave: (String, Int, SugarItemCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var nameText = ""
    @State private var selectedGrams = 15
    @State private var selectedCategory: SugarItemCategory = .other

    private let gramOptions = Array(1...70)
    private let categoryOptions = SugarItemCategory.allCases.filter { $0 != .custom }

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categoryOptions) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
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
        onSave(trimmedName, selectedGrams, selectedCategory)
        dismiss()
    }
}

struct SugarPickerLibraryView: View {
    let items: [SugarItem]
    var onSelect: (SugarItem, SugarItemSize) -> Void
    var onSelectCustom: (SugarItem, Int) -> Void
    var onAddCustom: (String, Int, SugarItemCategory) -> Void
    var onRemoveCustom: (SugarItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: SugarItemCategory?
    @State private var isFilterPresented = false
    @State private var selectedItem: SugarItem?
    @State private var itemPendingRemoval: SugarItem?
    @State private var isAddCustomPresented = false
    @State private var showConfirmation = false
    @State private var confirmationItem: SugarItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(sectionedItems, id: \.category) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.category.title)
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.horizontal, 6)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(section.items) { item in
                                    LibraryItemCard(item: item) {
                                        selectedItem = item
                                    } onLongPress: {
                                        guard item.isCustom else { return }
                                        itemPendingRemoval = item
                                    }
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        LibraryAddCard {
                            isAddCustomPresented = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.backgroundTop,
                        AppTheme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Treat Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFilterPresented = true
                    } label: {
                        Label(filterTitle, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search treats")
        }
        .overlay(alignment: .bottom) {
            if showConfirmation, let item = confirmationItem {
                LibraryConfirmationView(item: item)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedItem, onDismiss: {
            selectedItem = nil
        }) { item in
            SugarPickerSizeSheet(item: item) { size in
                handleLibrarySelection(item: item, size: size)
            } onSelectCustom: { grams in
                handleLibraryCustomSelection(item: item, grams: grams)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddCustomPresented) {
            CustomTreatForm(
                existingNames: Set(items.map { $0.name.lowercased() })
            ) { name, grams, category in
                onAddCustom(name, grams, category)
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Filter treats", isPresented: $isFilterPresented) {
            Button("All") {
                selectedCategory = nil
            }
            ForEach(availableCategories) { category in
                Button(category.title) {
                    selectedCategory = category
                }
            }
        } message: {
            Text("Pick a treat type to filter.")
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

    private var filterTitle: String {
        selectedCategory?.title ?? "All"
    }

    private var availableCategories: [SugarItemCategory] {
        SugarItemCategory.allCases.filter { category in
            items.contains(where: { $0.category == category })
        }
    }

    private var visibleItems: [SugarItem] {
        let base = selectedCategory == nil ? items : items.filter { $0.category == selectedCategory }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var sectionedItems: [LibrarySection] {
        let grouped = Dictionary(grouping: visibleItems, by: { $0.category })
        let orderedCategories = SugarItemCategory.allCases.filter { grouped[$0]?.isEmpty == false }
        return orderedCategories.map { category in
            LibrarySection(category: category, items: grouped[category] ?? [])
        }
    }

    private func handleLibrarySelection(item: SugarItem, size: SugarItemSize) {
        onSelect(item, size)
        confirmationItem = item
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                showConfirmation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        }
    }

    private func handleLibraryCustomSelection(item: SugarItem, grams: Int) {
        onSelectCustom(item, grams)
        confirmationItem = item
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                showConfirmation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        }
    }
}

private struct LibrarySection: Identifiable {
    let category: SugarItemCategory
    let items: [SugarItem]

    var id: String { category.rawValue }
}

private struct LibraryConfirmationView: View {
    let item: SugarItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Logged")
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(item.name)
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
    }
}

private struct LibraryItemCard: View {
    let item: SugarItem
    var onTap: () -> Void
    var onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                    )

                VStack(spacing: 6) {
                    if let imageName = item.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 46)
                    }
                    Text(item.name)
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                }
            }
            .aspectRatio(1, contentMode: .fit)

            Text("\(item.sugarGrams)g")
                .font(.custom("AvenirNext-Medium", size: 11))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.35, perform: onLongPress)
    }
}

private struct LibraryAddCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    )
                    .aspectRatio(1, contentMode: .fit)

                Text("Add")
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
