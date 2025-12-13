import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                loadingView
            } else if !appState.isAuthorized {
                authorizationView
            } else {
                DashboardView()
            }
        }
        .task {
            await appState.initialize()
        }
    }

    private var loadingView: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading StrainLab...")
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .strainLabBackground()
    }

    private var authorizationView: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(StrainLabTheme.recoveryGreen)

            Text("Health Access Required")
                .font(StrainLabTheme.titleFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Text("StrainLab needs access to your health data to calculate Recovery, Strain, and Sleep scores.")
                .font(StrainLabTheme.bodyFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, StrainLabTheme.paddingXL)

            if let error = appState.errorMessage {
                Text(error)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.recoveryRed)
                    .padding()
            }

            Button {
                Task {
                    await appState.initialize()
                }
            } label: {
                Text("Grant Access")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(StrainLabTheme.recoveryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            }
            .padding(.horizontal, StrainLabTheme.paddingXL)
            .padding(.top, StrainLabTheme.paddingM)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .strainLabBackground()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
