//
//  ContentView.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailySugarLimit") private var storedDailyLimit = 36
    @AppStorage("thresholdMultiplierL2") private var thresholdMultiplierL2 = 1.0
    @AppStorage("thresholdMultiplierL3") private var thresholdMultiplierL3 = 2.0
    @AppStorage("thresholdMultiplierL4") private var thresholdMultiplierL4 = 4.0
    @AppStorage("thresholdMultiplierL5") private var thresholdMultiplierL5 = 5.0
    @StateObject private var viewModel: SugarMeterViewModel
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSettingsPresented = false
    @StateObject private var sfxPlayer = SoundEffectPlayer(soundName: "SFX1.wav")

    init() {
        let stored = UserDefaults.standard.integer(forKey: "dailySugarLimit")
        let limit = stored > 0 ? stored : 36
        let l2 = UserDefaults.standard.object(forKey: "thresholdMultiplierL2") as? Double ?? 1.0
        let l3 = UserDefaults.standard.object(forKey: "thresholdMultiplierL3") as? Double ?? 2.0
        let l4 = UserDefaults.standard.object(forKey: "thresholdMultiplierL4") as? Double ?? 4.0
        let l5 = UserDefaults.standard.object(forKey: "thresholdMultiplierL5") as? Double ?? 5.0
        let multipliers = ThresholdMultipliers(l2: l2, l3: l3, l4: l4, l5: l5)
        _viewModel = StateObject(wrappedValue: SugarMeterViewModel(dailyLimit: limit, thresholdMultipliers: multipliers))
    }

    private var fillLevel: Double {
        viewModel.visualFillLevel
    }

    private var limitProgress: Double {
        viewModel.limitProgress
    }

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

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.glow.opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 260
                    )
                )
                .offset(x: -120, y: -220)

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("SugaMeter")
                        .font(.custom("AvenirNext-Heavy", size: 34))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Track your daily sugar intake!")
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                SugarMeterView(
                    fillLevel: fillLevel,
                    recommendedLevel: viewModel.recommendedLevel,
                    ringLines: viewModel.ringLines,
                    liquidPalette: viewModel.liquidPalette
                )
                    .frame(height: 380)

                VStack(spacing: 10) {
                    Text("\(viewModel.totalSugarGrams)g logged - \(Int(limitProgress * 100))% of \(viewModel.dailyLimit)g")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(AppTheme.textMuted)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.currentLevel.color)
                            .frame(width: 8, height: 8)
                        Text("Level \(viewModel.currentLevel.rawValue): \(viewModel.currentLevel.statusLabel)")
                            .font(.custom("AvenirNext-Medium", size: 13))
                            .foregroundStyle(viewModel.currentLevel.color)
                    }

                    SugarPickerView(items: viewModel.items) { item, size in
                        sfxPlayer.play()
                        viewModel.logSugar(item, size: size)
                    }

                }
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                sfxPlayer.play()
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    )
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(onReset: {
                sfxPlayer.play()
                viewModel.reset()
            })
                .environmentObject(musicPlayer)
        }
        .overlay {
            if let message = viewModel.levelMessage {
                LevelMessageView(message: message) {
                    viewModel.clearLevelMessage()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.ensureDailyReset()
            viewModel.startDailyResetTimer()
            viewModel.updateThresholdMultipliers(currentThresholdMultipliers())
        }
        .onChange(of: storedDailyLimit) { _, newValue in
            viewModel.updateDailyLimit(newValue)
        }
        .onChange(of: thresholdMultiplierL2) { _, _ in
            viewModel.updateThresholdMultipliers(currentThresholdMultipliers())
        }
        .onChange(of: thresholdMultiplierL3) { _, _ in
            viewModel.updateThresholdMultipliers(currentThresholdMultipliers())
        }
        .onChange(of: thresholdMultiplierL4) { _, _ in
            viewModel.updateThresholdMultipliers(currentThresholdMultipliers())
        }
        .onChange(of: thresholdMultiplierL5) { _, _ in
            viewModel.updateThresholdMultipliers(currentThresholdMultipliers())
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.ensureDailyReset()
                viewModel.startDailyResetTimer()
            }
        }
    }

    private func currentThresholdMultipliers() -> ThresholdMultipliers {
        ThresholdMultipliers(
            l2: thresholdMultiplierL2,
            l3: thresholdMultiplierL3,
            l4: thresholdMultiplierL4,
            l5: thresholdMultiplierL5
        )
    }
}
