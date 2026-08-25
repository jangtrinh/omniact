import SwiftUI

enum SettingsDesignMetrics {
    static let windowWidth: CGFloat = 900
    static let windowHeight: CGFloat = 600
    static let nativeTitlebarHeight: CGFloat = 32
    static let contentLayoutHeight: CGFloat = 568
    static let sidebarWidth: CGFloat = 240
    static let contentWidth: CGFloat = 660
    static let toolbarHeight: CGFloat = 52
    static let contentHeight: CGFloat = 548

    static let navigationRowWidth: CGFloat = 212
    static let navigationRowHeight: CGFloat = 30
    static let formWidth: CGFloat = 604
    static let formHeight: CGFloat = 300
    static let controlHeight: CGFloat = 28
    static let actionHeight: CGFloat = 30
}

enum SettingsPalette {
    static let sidebar = Color(red: 23 / 255, green: 23 / 255, blue: 25 / 255)
    static let content = Color(red: 30 / 255, green: 30 / 255, blue: 30 / 255)
    static let surface = Color(red: 36 / 255, green: 36 / 255, blue: 38 / 255)
    static let field = Color(red: 21 / 255, green: 21 / 255, blue: 23 / 255)
    static let control = Color(red: 52 / 255, green: 52 / 255, blue: 56 / 255)
    static let primary = Color(red: 242 / 255, green: 242 / 255, blue: 244 / 255)
    static let label = Color(red: 231 / 255, green: 231 / 255, blue: 234 / 255)
    static let secondary = Color(red: 146 / 255, green: 146 / 255, blue: 152 / 255)
    static let tertiary = Color(red: 119 / 255, green: 119 / 255, blue: 126 / 255)
    static let blue = Color(red: 10 / 255, green: 132 / 255, blue: 1)
    static let connected = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
    static let separator = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.08)
}
