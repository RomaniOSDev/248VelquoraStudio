import SwiftUI

enum AppTab: Int, CaseIterable {
    case shelf
    case journal
    case vault
    case more

    var title: String {
        switch self {
        case .shelf: return "Home"
        case .journal: return "Journal"
        case .vault: return "Vault"
        case .more: return "More"
        }
    }

    var symbol: String {
        switch self {
        case .shelf: return "house.fill"
        case .journal: return "text.book.closed.fill"
        case .vault: return "quote.bubble.fill"
        case .more: return "square.grid.2x2.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    SensoryFeedback.lightTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 28, height: 28)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == tab ? Color("AppBackground") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppDepth.primaryFill)
                        }
                    }
                }
                .buttonStyle(TabPressStyle())
                .frame(minHeight: 44)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppDepth.cardFill)
                .volumeStroke(corner: 22)
                .cardElevation(true)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selection: AppTab = .shelf

    private let tabBarClearance: CGFloat = 96

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackgroundView()

            Group {
                switch selection {
                case .shelf:
                    HomeView(bottomInset: tabBarClearance)
                case .journal:
                    JournalHubView(bottomInset: tabBarClearance)
                case .vault:
                    VaultHubView(bottomInset: tabBarClearance)
                case .more:
                    HubView(bottomInset: tabBarClearance)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            CustomTabBar(selection: $selection)
        }
        .achievementBannerHost()
        .onReceive(NotificationCenter.default.publisher(for: .switchAppTab)) { note in
            if let raw = note.object as? Int, let tab = AppTab(rawValue: raw) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selection = tab
                }
            }
        }
    }
}
