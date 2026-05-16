import SwiftUI

struct PermissionsOnboardingView: View {
    let hasAccessibilityPermission: Bool
    let hasFullDiskAccess: Bool
    let openAccessibilitySettings: () -> Void
    let openFullDiskAccessSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("permissions.onboarding.title"))
                    .font(.system(size: 22, weight: .semibold))

                Text(L10n.text("permissions.onboarding.body"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                permissionRow(
                    title: L10n.text("permissions.onboarding.accessibility.title"),
                    body: L10n.text("permissions.onboarding.accessibility.body"),
                    isGranted: hasAccessibilityPermission,
                    buttonTitle: L10n.text("permissions.onboarding.accessibility.open_settings"),
                    action: openAccessibilitySettings
                )

                Divider()

                permissionRow(
                    title: L10n.text("permissions.onboarding.full_disk_access.title"),
                    body: L10n.text("permissions.onboarding.full_disk_access.body"),
                    isGranted: hasFullDiskAccess,
                    buttonTitle: L10n.text("permissions.onboarding.full_disk_access.open_settings"),
                    action: openFullDiskAccessSettings
                )
            }

            HStack(spacing: 10) {
                Button(L10n.text("permissions.onboarding.quit")) {
                    quit()
                }

                Spacer()

                ProgressView()
                    .controlSize(.small)
                Text(L10n.text("permissions.onboarding.waiting"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 620)
    }

    private func permissionRow(
        title: String,
        body: String,
        isGranted: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(isGranted ? .green : .orange)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(buttonTitle) {
                action()
            }
            .disabled(isGranted)
        }
    }
}
