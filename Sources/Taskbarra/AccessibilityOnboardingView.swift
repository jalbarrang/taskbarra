import SwiftUI

struct AccessibilityOnboardingView: View {
    let openSystemSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Permiso de Accessibility requerido")
                    .font(.system(size: 22, weight: .semibold))

                Text(
                    "Taskbarra necesita este permiso para detectar, activar, minimizar y "
                        + "acomodar ventanas. Sin él no puede reemplazar correctamente el Dock."
                )
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Abre Privacy & Security > Accessibility", systemImage: "1.circle")
                Label("Activa Taskbarra en la lista", systemImage: "2.circle")
                Label("Vuelve aquí; la app continuará automáticamente", systemImage: "3.circle")
            }
            .font(.system(size: 13))

            HStack(spacing: 10) {
                Button("Abrir System Settings") {
                    openSystemSettings()
                }
                .keyboardShortcut(.defaultAction)

                Button("Salir") {
                    quit()
                }

                Spacer()

                ProgressView()
                    .controlSize(.small)
                Text("Esperando permiso…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
