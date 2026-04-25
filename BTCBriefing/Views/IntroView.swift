import SwiftUI

struct IntroView: View {
    @ObservedObject var settings: AppSettings
    var onDone: () -> Void

    @State private var animateIcon = false
    @State private var showContent = false
    @State private var step = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo BTC animato
                ZStack {
                    Circle()
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
                        .frame(width: 140, height: 140)
                        .shadow(color: Color(red: 0.97, green: 0.58, blue: 0.10).opacity(0.5), radius: animateIcon ? 40 : 20)

                    Text("₿")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))
                        .scaleEffect(animateIcon ? 1.08 : 1.0)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        animateIcon = true
                    }
                    withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                        showContent = true
                    }
                }

                if showContent {
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("intro.title", comment: ""))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text(NSLocalizedString("intro.subtitle", comment: ""))
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(Color(red: 0.97, green: 0.58, blue: 0.10))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    Text(NSLocalizedString("intro.description", comment: ""))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                }

                Spacer()

                // Selezione Provider e Intervallo
                if showContent {
                    VStack(alignment: .leading, spacing: 20) {
                        settingRow(
                            label: NSLocalizedString("intro.provider", comment: ""),
                            content: AnyView(
                                Picker("", selection: $settings.provider) {
                                    ForEach(DataProvider.allCases, id: \.self) {
                                        Text($0.displayName).tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                            )
                        )

                        settingRow(
                            label: NSLocalizedString("intro.interval", comment: ""),
                            content: AnyView(
                                Picker("", selection: $settings.refreshInterval) {
                                    ForEach(RefreshInterval.allCases, id: \.self) {
                                        Text($0.displayName).tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                            )
                        )
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Button(action: {
                        settings.hasCompletedOnboarding = true
                        onDone()
                    }) {
                        Text(NSLocalizedString("intro.start", comment: ""))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.97, green: 0.58, blue: 0.10))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }

                Spacer().frame(height: 24)
            }
        }
    }

    private func settingRow(label: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            content
        }
    }
}
