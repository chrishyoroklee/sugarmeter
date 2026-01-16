//
//  ContentView.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailySugarLimit", store: AppGroup.userDefaults) private var storedDailyLimit = 36
    @StateObject private var viewModel: SugarMeterViewModel
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSettingsPresented = false
    @State private var isCalendarPresented = false
    @StateObject private var sfxPlayer = SoundEffectPlayer(soundName: "SFX1.wav")

    init() {
        let stored = AppGroup.userDefaults.integer(forKey: AppGroup.dailyLimitKey)
        let limit = stored > 0 ? stored : 36
        _viewModel = StateObject(wrappedValue: SugarMeterViewModel(dailyLimit: limit))
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
                    .padding(.bottom, 40)

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

                    SugarPickerView(items: viewModel.displayedItems, libraryItems: viewModel.libraryItems) { item, size in
                        sfxPlayer.play()
                        viewModel.logSugar(item, size: size)
                    } onAddCustom: { name, grams, category in
                        sfxPlayer.play()
                        viewModel.addCustomItem(name: name, grams: grams, category: category)
                    } onRemoveCustom: { item in
                        sfxPlayer.play()
                        viewModel.removeCustomItem(item)
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
        .overlay(alignment: .topLeading) {
            Button {
                sfxPlayer.play()
                isCalendarPresented = true
            } label: {
                Image(systemName: "calendar")
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
            .padding(.leading, 16)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(onReset: {
                sfxPlayer.play()
                viewModel.reset()
            })
                .environmentObject(musicPlayer)
        }
        .sheet(isPresented: $isCalendarPresented) {
            CalendarView()
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
        }
        .onChange(of: storedDailyLimit) { _, newValue in
            viewModel.updateDailyLimit(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.ensureDailyReset()
                viewModel.startDailyResetTimer()
            }
        }
    }
}
