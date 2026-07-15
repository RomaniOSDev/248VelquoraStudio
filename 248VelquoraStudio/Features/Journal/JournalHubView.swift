import SwiftUI

struct JournalHubView: View {
    let bottomInset: CGFloat
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    CustomSegmentedControl(titles: ["Sessions", "Planner"], selection: $segment)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    Group {
                        if segment == 0 {
                            SessionsLogView(bottomInset: bottomInset)
                        } else {
                            ReadingPlannerView(bottomInset: bottomInset, embedsNavigation: false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(segment == 0 ? "Reading Journal" : "Reading Planner")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        SensoryFeedback.lightTap()
                        if segment == 0 {
                            NotificationCenter.default.post(name: .openSessionAdd, object: nil)
                        } else {
                            NotificationCenter.default.post(name: .openPlannerAdd, object: nil)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .transparentScreenChrome()
    }
}
