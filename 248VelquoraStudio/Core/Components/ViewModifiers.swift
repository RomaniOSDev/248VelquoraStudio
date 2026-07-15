import SwiftUI
import UIKit

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

/// Clears UIHostingController / UIKit ancestor backgrounds so SwiftUI AppBackgroundView shows through.
struct HostingBackgroundClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            var ancestor: UIView? = uiView.superview
            while let current = ancestor {
                current.backgroundColor = .clear
                if let table = current as? UITableView {
                    table.backgroundColor = .clear
                    table.separatorColor = UIColor(named: "AppTextSecondary")?.withAlphaComponent(0.25)
                }
                ancestor = current.superview
            }
        }
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func transparentScreenChrome() -> some View {
        background(Color.clear)
    }

    /// Tab-root / screen chrome: transparent nav bar + clear hosting UIKit layers.
    func appScreenChrome() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.clear)
            .background(HostingBackgroundClearer())
    }

    func clearHostingBackground() -> some View {
        background(HostingBackgroundClearer())
    }
}
