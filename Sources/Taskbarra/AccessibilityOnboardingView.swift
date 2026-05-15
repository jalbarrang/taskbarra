import SwiftUI

struct AccessibilityOnboardingView: View {
    let openSystemSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("accessibility.onboarding.title"))
                    .font(.system(size: 22, weight: .semibold))

                Text(L10n.text("accessibility.onboarding.body"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label(L10n.text("accessibility.onboarding.step.open"), systemImage: "1.circle")
                Label(L10n.text("accessibility.onboarding.step.enable"), systemImage: "2.circle")
                Label(L10n.text("accessibility.onboarding.step.return"), systemImage: "3.circle")
            }
            .font(.system(size: 13))

            HStack(spacing: 10) {
                Button(L10n.text("accessibility.onboarding.open_settings")) {
                    openSystemSettings()
                }
                .keyboardShortcut(.defaultAction)

                Button(L10n.text("accessibility.onboarding.quit")) {
                    quit()
                }

                Spacer()

                ProgressView()
                    .controlSize(.small)
                Text(L10n.text("accessibility.onboarding.waiting"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
