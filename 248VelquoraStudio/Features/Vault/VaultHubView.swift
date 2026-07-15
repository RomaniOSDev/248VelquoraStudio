import SwiftUI

struct VaultHubView: View {
    let bottomInset: CGFloat
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    CustomSegmentedControl(titles: ["Quotes", "Goals"], selection: $segment)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    Group {
                        if segment == 0 {
                            QuotesVaultView(bottomInset: bottomInset)
                        } else {
                            GoalsView(bottomInset: bottomInset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(segment == 0 ? "Quotes" : "Goals")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
            .toolbar {
                if segment == 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            SensoryFeedback.lightTap()
                            NotificationCenter.default.post(name: .openQuoteAdd, object: nil)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color("AppPrimary"))
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
        .transparentScreenChrome()
    }
}

extension Notification.Name {
    static let openQuoteAdd = Notification.Name("openQuoteAdd")
    static let openSessionAdd = Notification.Name("openSessionAdd")
    static let openPlannerAdd = Notification.Name("openPlannerAdd")
}
