import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer
    var onReset: () -> Void = {}
    @AppStorage("dailySugarLimit", store: AppGroup.userDefaults) private var dailySugarLimit = 36
    @AppStorage(AppGroup.unitKey, store: AppGroup.userDefaults) private var sugarUnitRaw = SugarUnit.grams.rawValue
    @AppStorage("musicVolume") private var musicVolume = 0.7
    @State private var limitSelection: DailyLimitOption = .balanced
    @State private var customLimitText: String = ""

    var body: some View {
        NavigationStack {
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

                Form {
                    musicSection
                    dailyLimitSection
                    unitSection
                    widgetSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            musicPlayer.volume = musicVolume
            limitSelection = DailyLimitOption.selection(for: dailySugarLimit)
            customLimitText = sugarUnit.formattedValue(from: dailySugarLimit)
        }
        .onChange(of: limitSelection) { _, newValue in
            applyDailyLimitSelection(newValue)
        }
        .onChange(of: customLimitText) { _, newValue in
            updateCustomLimit(from: newValue)
        }
        .onChange(of: sugarUnitRaw) { _, _ in
            limitSelection = DailyLimitOption.selection(for: dailySugarLimit)
            customLimitText = sugarUnit.formattedValue(from: dailySugarLimit)
        }
    }

    @ViewBuilder
    private var musicSection: some View {
        Section("Music") {
            if musicPlayer.tracks.count > 1 {
                Picker("Track", selection: $musicPlayer.selectedTrackID) {
                    ForEach(musicPlayer.tracks) { track in
                        Text(track.displayName)
                            .tag(track.id)
                    }
                }
                .pickerStyle(.segmented)
            } else if let track = musicPlayer.tracks.first {
                HStack {
                    Text("Track")
                    Spacer()
                    Text(track.displayName)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(musicVolume * 100))%")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Slider(value: volumeBinding, in: 0...1)
            }
        }
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { musicVolume },
            set: { newValue in
                musicVolume = newValue
                musicPlayer.volume = newValue
            }
        )
    }

    @ViewBuilder
    private var dailyLimitSection: some View {
        Section {
            Picker("Baseline", selection: $limitSelection) {
                ForEach(DailyLimitOption.allCases) { option in
                    Text(option.title(for: sugarUnit))
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)

            if limitSelection == .custom {
                HStack {
                    Text("Custom \(sugarUnit.label)")
                    Spacer()
                    TextField("Enter amount", text: $customLimitText)
                        .keyboardType(sugarUnit == .ounces ? .decimalPad : .numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }
        } header: {
            Text("Daily Target")
        } footer: {
            Text("Baseline sets the recommended max. Levels scale from it.")
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var unitSection: some View {
        Section {
            Picker("Units", selection: $sugarUnitRaw) {
                ForEach(SugarUnit.allCases) { unit in
                    Text(unit.title)
                        .tag(unit.rawValue)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Units")
        }
    }

    @ViewBuilder
    private var widgetSection: some View {
        Section {
            Button {
#if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
#endif
            } label: {
                Text("Refresh Widget")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(AppTheme.primary)
            }
        } header: {
            Text("Widgets")
        } footer: {
            Text("Use after logging if the widget lags.")
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button {
                onReset()
            } label: {
                Text("Reset Daily Log")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(AppTheme.primary)
            }
        } footer: {
            Text("Clears today's sugar total and level.")
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func applyDailyLimitSelection(_ selection: DailyLimitOption) {
        if let limit = selection.limit {
            dailySugarLimit = limit
            customLimitText = sugarUnit.formattedValue(from: limit)
        }
    }

    private func updateCustomLimit(from text: String) {
        guard limitSelection == .custom else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value > 0 else { return }
        dailySugarLimit = sugarUnit.grams(from: value)
    }

    private var sugarUnit: SugarUnit {
        SugarUnit(rawValue: sugarUnitRaw) ?? .grams
    }
}

private enum DailyLimitOption: String, CaseIterable, Identifiable {
    case balanced
    case strict
    case custom

    var id: String { rawValue }

    func title(for unit: SugarUnit) -> String {
        switch self {
        case .balanced:
            return unit.formattedWithUnit(from: 36)
        case .strict:
            return unit.formattedWithUnit(from: 22)
        case .custom:
            return "Custom"
        }
    }

    var limit: Int? {
        switch self {
        case .balanced:
            return 36
        case .strict:
            return 22
        case .custom:
            return nil
        }
    }

    static func selection(for limit: Int) -> DailyLimitOption {
        if limit == 36 {
            return .balanced
        }
        if limit == 22 {
            return .strict
        }
        return .custom
    }
}
