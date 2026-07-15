import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            AppDepth.screenBackground

            // Static ambient blobs — no Canvas loops, no blur, no animation
            Circle()
                .fill(Color("AppPrimary").opacity(0.07))
                .frame(width: 300, height: 300)
                .offset(x: -110, y: -180)
                .allowsHitTesting(false)

            Circle()
                .fill(Color("AppAccent").opacity(0.05))
                .frame(width: 240, height: 240)
                .offset(x: 130, y: 220)
                .allowsHitTesting(false)

            Ellipse()
                .fill(Color("AppSurface").opacity(0.18))
                .frame(width: 420, height: 160)
                .offset(y: 40)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        SurfaceCard {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.25), Color("AppAccent").opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                    Image(systemName: symbol)
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(Color("AppPrimary"))
                }
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color("AppBackground"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: AppDepth.controlCorner, style: .continuous)
                    .fill(AppDepth.primaryFill)
                    .volumeStroke(corner: AppDepth.controlCorner)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SuccessCheckmarkOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Circle()
                    .fill(Color("AppSurface").opacity(0.92))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("AppAccent"))
            }
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            }
        }
    }
}

struct AchievementBannerView: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color("AppPrimary").opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "star.fill")
                    .foregroundStyle(Color("AppPrimary"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppAccent"))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppDepth.cardFill)
                .volumeStroke(corner: 16)
                .cardElevation(true)
        )
        .padding(.horizontal, 16)
    }
}

struct AchievementBannerHost: ViewModifier {
    @EnvironmentObject private var store: AppDataStore
    @State private var currentId: String?
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if visible, let currentId,
                   let def = AchievementCatalog.all.first(where: { $0.id == currentId }) {
                    AchievementBannerView(title: def.title, detail: def.detail)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { _ in
                presentNextIfNeeded()
            }
            .onChange(of: store.pendingAchievementIds.count) { _ in
                presentNextIfNeeded()
            }
    }

    private func presentNextIfNeeded() {
        guard !visible else { return }
        guard let next = store.consumeNextAchievementBanner() else { return }
        currentId = next
        SensoryFeedback.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            visible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                visible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentId = nil
                presentNextIfNeeded()
            }
        }
    }
}

extension View {
    func achievementBannerHost() -> some View {
        modifier(AchievementBannerHost())
    }
}
