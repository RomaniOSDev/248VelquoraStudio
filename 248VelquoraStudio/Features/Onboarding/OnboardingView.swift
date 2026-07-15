import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appear = false

    private let pages: [(headline: String, detail: String, image: String, symbol: String)] = [
        (
            "Welcome Aboard",
            "Organize your reading tasks efficiently.",
            "home_shelf",
            "books.vertical.fill"
        ),
        (
            "Track Tasks",
            "Add book-related tasks and schedule them seamlessly.",
            "home_journal",
            "checklist"
        ),
        (
            "Get Started",
            "Begin by adding your first task now.",
            "home_quotes",
            "sparkles"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageCard(index: index)
                            .tag(index)
                            .padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeOut(duration: 0.25), value: page)

                bottomChrome
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appear = true
            }
        }
        .onChange(of: page) { _ in
            appear = false
            withAnimation(.easeOut(duration: 0.3)) {
                appear = true
            }
        }
    }

    private var bottomChrome: some View {
        SurfaceCard(padding: 18) {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? AppDepth.primaryFill : AppDepth.insetFill)
                            .frame(width: index == page ? 24 : 8, height: 8)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        index == page
                                            ? Color("AppAccent").opacity(0.35)
                                            : Color("AppTextSecondary").opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeOut(duration: 0.2), value: page)
                    }
                }

                Button {
                    SensoryFeedback.lightTap()
                    if page < pages.count - 1 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            page += 1
                        }
                    } else {
                        SensoryFeedback.mediumTap()
                        store.hasSeenOnboarding = true
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Get Started" : "Next")
                }
                .buttonStyle(PrimaryButtonStyle())

                if page < pages.count - 1 {
                    Button {
                        SensoryFeedback.lightTap()
                        SensoryFeedback.mediumTap()
                        store.hasSeenOnboarding = true
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pageCard(index: Int) -> some View {
        let item = pages[index]
        return VStack(spacing: 20) {
            Spacer(minLength: 12)

            SurfaceCard(padding: 14, accentBorder: true) {
                VStack(spacing: 18) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(item.image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .drawingGroup()
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color("AppPrimary").opacity(0.18), lineWidth: 1)
                            )
                            .overlay {
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color("AppBackground").opacity(0.15),
                                        Color("AppBackground").opacity(0.55)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .allowsHitTesting(false)
                            }

                        IconBadge(symbol: item.symbol, size: 48)
                            .padding(14)
                    }
                    .scaleEffect(appear && page == index ? 1 : 0.94)
                    .opacity(appear && page == index ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: appear)

                    illustrationAccent(for: index)
                        .frame(height: 56)
                        .opacity(appear && page == index ? 1 : 0)
                        .animation(.easeOut(duration: 0.35).delay(0.05), value: appear)

                    Text(item.headline)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(item.detail)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .scaleEffect(appear && page == index ? 1 : 0.97)
            .opacity(appear && page == index ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appear)

            Spacer(minLength: 8)
        }
    }

    @ViewBuilder
    private func illustrationAccent(for index: Int) -> some View {
        HStack(spacing: 10) {
            switch index {
            case 0:
                OpenBookShape()
                    .fill(AppDepth.primaryFill)
                    .frame(width: 54, height: 42)
                MetaPill(text: "Shelf ready", emphasized: true)
            case 1:
                CalendarShape()
                    .stroke(AppDepth.accentEdge, lineWidth: 2.5)
                    .frame(width: 42, height: 42)
                MetaPill(text: "Plan sessions", emphasized: true)
            default:
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(10)
                    .background(Circle().fill(AppDepth.primarySoftFill))
                MetaPill(text: "Start now", emphasized: true)
            }
        }
    }
}

struct OpenBookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        path.move(to: CGPoint(x: midX, y: rect.minY + 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 8, y: rect.maxY - 10),
            control: CGPoint(x: rect.minX + 10, y: rect.midY - 10)
        )
        path.addLine(to: CGPoint(x: midX, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.maxY - 10))
        path.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY + 8),
            control: CGPoint(x: rect.maxX - 10, y: rect.midY - 10)
        )
        path.move(to: CGPoint(x: midX, y: rect.minY + 8))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY - 4))
        return path
    }
}

struct CalendarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: 8, dy: 12)
        path.addRoundedRect(in: inset, cornerSize: CGSize(width: 10, height: 10))
        path.move(to: CGPoint(x: inset.minX, y: inset.minY + 22))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.minY + 22))
        path.move(to: CGPoint(x: inset.minX + 18, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: inset.minX + 18, y: inset.minY + 10))
        path.move(to: CGPoint(x: inset.maxX - 18, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: inset.maxX - 18, y: inset.minY + 10))
        return path
    }
}
