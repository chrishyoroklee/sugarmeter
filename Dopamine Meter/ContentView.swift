//
//  ContentView.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SugarMeterViewModel()

    private var fillLevel: Double {
        viewModel.fillLevel
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.9),
                    Color(red: 0.88, green: 0.9, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.55).opacity(0.35),
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
                    Text("Sugar Meter")
                        .font(.custom("AvenirNext-Heavy", size: 34))
                        .foregroundStyle(Color(red: 0.2, green: 0.18, blue: 0.18))
                    Text("Every log sweetens the cup")
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(Color(red: 0.35, green: 0.32, blue: 0.32))
                }

                SugarMeterView(fillLevel: fillLevel)
                    .frame(height: 320)

                VStack(spacing: 10) {
                    Text("\(viewModel.sugarLogs) sugar logs · \(Int(fillLevel * 100))% full")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(Color(red: 0.32, green: 0.28, blue: 0.26))

                    HStack(spacing: 12) {
                        Button {
                            viewModel.logSugar(.donut)
                        } label: {
                            Text("Log Donut")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.93, green: 0.45, blue: 0.2))
                                )
                        }
                        .disabled(viewModel.isFull)
                        .opacity(viewModel.isFull ? 0.6 : 1)

                        Button {
                            viewModel.logSugar(.candy)
                        } label: {
                            Text("Log Candy")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                                .foregroundStyle(Color(red: 0.62, green: 0.26, blue: 0.14))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.98, green: 0.82, blue: 0.65))
                                )
                        }
                        .disabled(viewModel.isFull)
                        .opacity(viewModel.isFull ? 0.6 : 1)
                    }

                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Reset")
                            .font(.custom("AvenirNext-Medium", size: 14))
                            .foregroundStyle(Color(red: 0.4, green: 0.35, blue: 0.32))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color(red: 0.78, green: 0.72, blue: 0.68), lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
        }
    }
}
