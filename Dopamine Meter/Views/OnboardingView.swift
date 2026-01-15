import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var step = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("dailySugarLimit", store: AppGroup.userDefaults) private var dailySugarLimit = 36
    @AppStorage("sugarStyle") private var sugarStyle = SugarStyle.balanced.rawValue
    @AppStorage(AppGroup.unitKey, store: AppGroup.userDefaults) private var sugarUnitRaw = SugarUnit.grams.rawValue

    var body: some View {
        TabView(selection: $step) {
            OnboardingWelcomeView {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = 1
                }
            }
            .tag(0)

            OnboardingUnitView(selectedUnitRaw: $sugarUnitRaw) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = 2
                }
            }
            .tag(1)

            OnboardingStyleView(viewModel: viewModel) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = 3
                }
            }
            .tag(2)

            OnboardingInfoView {
                completeOnboarding()
            }
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
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
    }

    private func completeOnboarding() {
        guard let limit = viewModel.resolvedLimit else { return }
        dailySugarLimit = limit
        sugarStyle = viewModel.selectedStyle.rawValue
        hasCompletedOnboarding = true
    }
}

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Text("Welcome")
                    .font(.custom("AvenirNext-Heavy", size: 34))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            HStack(alignment: .top, spacing: 12) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .shadow(color: AppTheme.textPrimary.opacity(0.2), radius: 10, x: 0, y: 6)

                Text("Track added sugar easily")
                    .font(.custom("AvenirNext-Medium", size: 15))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.secondary.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: 180, alignment: .leading)
            }
            .padding(.top, 8)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(AppTheme.primary)
                    )
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingStyleView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Text("Pick experience")
                    .font(.custom("AvenirNext-Heavy", size: 28))
                    .foregroundStyle(AppTheme.textPrimary)
//                Text("Optional but powerful")
//                    .font(.custom("AvenirNext-Medium", size: 14))
//                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(alignment: .top, spacing: 12) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .shadow(color: AppTheme.textPrimary.opacity(0.18), radius: 8, x: 0, y: 4)

                Text("Optional but powerful")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.secondary.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1)
                            )
                    )
            }

            VStack(spacing: 12) {
                ForEach(SugarStyle.allCases) { style in
                    Button {
                        viewModel.selectedStyle = style
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: viewModel.selectedStyle == style ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.title)
                                    .font(.custom("AvenirNext-DemiBold", size: 16))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(style.detail)
                                    .font(.custom("AvenirNext-Medium", size: 13))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(viewModel.selectedStyle == style ? AppTheme.secondary.opacity(0.7) : Color.white.opacity(0.6))
                        )
                    }
                }
            }

            if viewModel.selectedStyle == .custom {
                VStack(spacing: 8) {
                    Text("Custom daily limit")
                        .font(.custom("AvenirNext-Medium", size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Enter grams per day", text: $viewModel.customGramsText)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(AppTheme.primary)
                    )
            }
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.6)
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingUnitView: View {
    @Binding var selectedUnitRaw: String
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Text("Choose units")
                    .font(.custom("AvenirNext-Heavy", size: 28))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Pick your preferred sugar metric")
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(alignment: .top, spacing: 12) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .shadow(color: AppTheme.textPrimary.opacity(0.18), radius: 8, x: 0, y: 4)

                Text("You can change this anytime in Settings.")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.secondary.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1)
                            )
                    )
            }

            Picker("Units", selection: $selectedUnitRaw) {
                ForEach(SugarUnit.allCases) { unit in
                    Text(unit.title)
                        .tag(unit.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(AppTheme.primary)
                    )
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingInfoView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Text("You’re all set")
                    .font(.custom("AvenirNext-Heavy", size: 28))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Log your daily sugar treats and keep your streak!")
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            HStack(alignment: .top, spacing: 12) {
                Image("sugapanda")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .shadow(color: AppTheme.textPrimary.opacity(0.18), radius: 8, x: 0, y: 4)

                Text("Tap a treat, log your sugar, and watch the meter fill.")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.secondary.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            Button(action: onContinue) {
                Text("Start")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(AppTheme.primary)
                    )
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }
}
