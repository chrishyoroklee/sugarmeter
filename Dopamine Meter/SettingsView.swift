import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer
    var onReset: () -> Void = {}
    @AppStorage("dailySugarLimit") private var dailySugarLimit = 36
    @AppStorage("thresholdMultiplierL2") private var thresholdMultiplierL2 = 1.0
    @AppStorage("thresholdMultiplierL3") private var thresholdMultiplierL3 = 2.0
    @AppStorage("thresholdMultiplierL4") private var thresholdMultiplierL4 = 4.0
    @AppStorage("thresholdMultiplierL5") private var thresholdMultiplierL5 = 5.0
    @AppStorage("musicVolume") private var musicVolume = 0.7

    var body: some View {
        NavigationStack {
            Form {
                musicSection
                thresholdSection
                resetSection
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
            normalizeThresholds()
            musicPlayer.volume = musicVolume
        }
        .onChange(of: thresholdMultiplierL2) { _, _ in
            normalizeThresholds()
        }
        .onChange(of: thresholdMultiplierL3) { _, _ in
            normalizeThresholds()
        }
        .onChange(of: thresholdMultiplierL4) { _, _ in
            normalizeThresholds()
        }
        .onChange(of: thresholdMultiplierL5) { _, _ in
            normalizeThresholds()
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
    private var thresholdSection: some View {
        Section {
            ThresholdSliderRow(
                title: "L2 - Caution",
                value: $thresholdMultiplierL2,
                limit: dailySugarLimit,
                color: SugarLevel.l2.color,
                range: 1...6
            )
            ThresholdSliderRow(
                title: "L3 - Warning",
                value: $thresholdMultiplierL3,
                limit: dailySugarLimit,
                color: SugarLevel.l3.color,
                range: 1...8
            )
            ThresholdSliderRow(
                title: "L4 - High",
                value: $thresholdMultiplierL4,
                limit: dailySugarLimit,
                color: SugarLevel.l4.color,
                range: 1...10
            )
            ThresholdSliderRow(
                title: "L5 - OMG",
                value: $thresholdMultiplierL5,
                limit: dailySugarLimit,
                color: SugarLevel.l5.color,
                range: 1...12
            )
        } header: {
            Text("Thresholds")
        } footer: {
            Text("Thresholds are multipliers of your daily limit.")
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

    private func normalizeThresholds() {
        if thresholdMultiplierL2 < 1 {
            thresholdMultiplierL2 = 1
        }
        if thresholdMultiplierL3 < thresholdMultiplierL2 {
            thresholdMultiplierL3 = thresholdMultiplierL2
        }
        if thresholdMultiplierL4 < thresholdMultiplierL3 {
            thresholdMultiplierL4 = thresholdMultiplierL3
        }
        if thresholdMultiplierL5 < thresholdMultiplierL4 {
            thresholdMultiplierL5 = thresholdMultiplierL4
        }
    }
}

private struct ThresholdSliderRow: View {
    let title: String
    @Binding var value: Double
    let limit: Int
    let color: Color
    let range: ClosedRange<Double>
    private let step = 0.25

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                Spacer()
                Text("\(value, specifier: "%.2f")x")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text("\(gramsForLimit())g boundary")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
            Slider(value: $value, in: range, step: step)
        }
        .padding(.vertical, 4)
    }

    private func gramsForLimit() -> Int {
        Int((Double(limit) * value).rounded())
    }
}
