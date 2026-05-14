# Taskbarra

Reemplazo del Dock de macOS con una barra de tareas compacta estilo Windows que muestra cada ventana como una entrada individual.

## Problema

macOS agrupa todas las ventanas de una app bajo un solo icono en el Dock. No hay forma nativa de ver y navegar entre ventanas individuales sin Mission Control o clic derecho. Taskbarra resuelve esto mostrando cada ventana abierta como una entrada separada con icono y título.

## Decisiones de diseño

| Decisión | Resolución |
|---|---|
| **Alcance** | Reemplazar solo el Dock (la Menu Bar se mantiene intacta) |
| **Modelo de ventanas** | Una entrada por ventana, sin agrupación por app |
| **Info por entrada** | Icono de la app + título de la ventana |
| **Posición** | Borde inferior, siempre visible |
| **Reserva de espacio** | NSWindow con level alto + Accessibility API (`CGDisplaySetWorkArea` o equivalente) para que ventanas maximizadas no la cubran |
| **Detección de ventanas** | `CGWindowListCopyWindowInfo` para snapshot + `AXUIElement` para eventos en tiempo real y acciones |
| **Clic izquierdo** | Toggle: activa la ventana si no está al frente, minimiza si ya lo está |
| **Clic derecho** | Menú contextual (minimizar, cerrar, mover, etc.) |
| **Indicadores visuales** | Línea inferior de color (activa vs inactiva) + opacidad reducida para ventanas minimizadas |
| **Spaces** | Solo ventanas del Space activo |
| **Monitores** | Una sola barra en el monitor principal |
| **Apps ancladas** | No — solo ventanas abiertas |
| **Tema** | Siempre oscuro (dark mode forzado en la ventana) |
| **UI framework** | SwiftUI para contenido + AppKit para la ventana (`NSHostingView`) |
| **Distribución** | DMG directo + Sparkle auto-update + Homebrew cask |
| **macOS mínimo** | 14 (Sonoma) |

## Stack

- **Lenguaje**: Swift
- **UI**: SwiftUI (contenido) + AppKit (ventana/sistema)
- **APIs de sistema**: Accessibility API (`AXUIElement`, `AXObserver`), Core Graphics (`CGWindowListCopyWindowInfo`)
- **Permisos requeridos**: Accessibility (System Preferences > Privacy & Security)
- **Auto-update**: Sparkle framework
- **Build**: Xcode / xcodegen
