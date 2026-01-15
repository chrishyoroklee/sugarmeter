//
//  ContentView.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailySugarLimit") private var storedDailyLimit = 36
    @StateObject private var viewModel: SugarMeterViewModel
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSettingsPresented = false
    @StateObject private var sfxPlayer = SoundEffectPlayer(soundName: "SFX1.wav")

    init() {
        let stored = UserDefaults.standard.integer(forKey: "dailySugarLimit")
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
                    Text("Track your sugar!")
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

                    Menu {
                        ForEach(viewModel.items) { item in
                            Button("\(item.name) - \(item.sugarGrams)g") {
                                sfxPlayer.play()
                                viewModel.logSugar(item)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Log Sugar")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary)
                        )
                    }

                    Button {
                        sfxPlayer.play()
                        viewModel.reset()
                    } label: {
                        Text("Reset")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
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
            SettingsView()
                .environmentObject(musicPlayer)
        }
        .alert(item: $viewModel.levelMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.body),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.ensureDailyReset()
            viewModel.startDailyResetTimer()
        }
        .onChange(of: storedDailyLimit) { newValue in
            viewModel.updateDailyLimit(newValue)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.ensureDailyReset()
                viewModel.startDailyResetTimer()
            }
        }
    }
}
