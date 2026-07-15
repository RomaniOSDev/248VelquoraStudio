import SwiftUI

/// Lightweight depth tokens — gradients + one shadow max. No blur, no animated backgrounds.
enum AppDepth {
    static let cardCorner: CGFloat = 20
    static let controlCorner: CGFloat = 14

    static let cardShadowColor = Color("AppBackground").opacity(0.40)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 6

    static let elevatedShadowColor = Color("AppBackground").opacity(0.48)
    static let elevatedShadowRadius: CGFloat = 16
    static let elevatedShadowY: CGFloat = 8

    static var screenBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("AppSurface").opacity(0.42),
                Color("AppBackground")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.98),
                Color("AppSurface").opacity(0.82),
                Color("AppBackground").opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardAccentFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppPrimary").opacity(0.12),
                Color("AppSurface").opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var insetFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground").opacity(0.55),
                Color("AppBackground").opacity(0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryFill: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primarySoftFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary").opacity(0.28),
                Color("AppAccent").opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var edgeHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppTextPrimary").opacity(0.14),
                Color("AppTextSecondary").opacity(0.04),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentEdge: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary").opacity(0.55),
                Color("AppAccent").opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    /// Single soft drop shadow — use only on outer cards / floating chrome.
    func cardElevation(_ elevated: Bool = false) -> some View {
        shadow(
            color: elevated ? AppDepth.elevatedShadowColor : AppDepth.cardShadowColor,
            radius: elevated ? AppDepth.elevatedShadowRadius : AppDepth.cardShadowRadius,
            x: 0,
            y: elevated ? AppDepth.elevatedShadowY : AppDepth.cardShadowY
        )
    }

    /// Cheap volume rim: light top edge without a second shadow.
    func volumeStroke(accent: Bool = false, corner: CGFloat = AppDepth.cardCorner) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(
                    accent ? AppDepth.accentEdge : AppDepth.edgeHighlight,
                    lineWidth: accent ? 1.2 : 1
                )
        )
    }
}
