import Foundation

enum AppLink: String {
    case privacyPolicy = "https://velquora248studio.site/privacy/325"
    case termsOfUse = "https://velquora248studio.site/terms/325"

    var url: URL? {
        URL(string: rawValue)
    }
}
