import Foundation
import CoreGraphics

public struct AXContext: Sendable, Equatable {
    public let selectedText: String
    public let caretRect: CGRect?
    public let appName: String?
    public let bundleIdentifier: String?

    public init(
        selectedText: String = "",
        caretRect: CGRect? = nil,
        appName: String? = nil,
        bundleIdentifier: String? = nil
    ) {
        self.selectedText = selectedText
        self.caretRect = caretRect
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
    }
}
