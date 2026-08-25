import Cocoa
import SwiftUI

public final class HUDPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false
    }

    public func positionNear(caretRect: CGRect?) {
        updateFrameToFitContent(caretRect: caretRect)
    }

    public func updateFrameToFitContent(caretRect: CGRect? = nil) {
        guard let contentView = self.contentView else { return }
        let fittingSize = contentView.fittingSize
        guard fittingSize.width > 50 && fittingSize.height > 50 else { return }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        var targetOrigin: CGPoint
        if self.frame.size.width <= 10 || !self.isVisible {
            if let caret = caretRect, caret != .zero {
                targetOrigin = CGPoint(
                    x: caret.origin.x - 20,
                    y: caret.origin.y - fittingSize.height - 10
                )
            } else {
                targetOrigin = CGPoint(
                    x: screenFrame.midX - (fittingSize.width / 2),
                    y: screenFrame.midY - (fittingSize.height / 2)
                )
            }
        } else {
            // Anchor top edge so panel expands smoothly downwards
            let currentTop = self.frame.origin.y + self.frame.size.height
            targetOrigin = CGPoint(
                x: self.frame.origin.x,
                y: currentTop - fittingSize.height
            )
        }

        targetOrigin.x = max(screenFrame.minX + 16, min(targetOrigin.x, screenFrame.maxX - fittingSize.width - 16))
        targetOrigin.y = max(screenFrame.minY + 16, min(targetOrigin.y, screenFrame.maxY - fittingSize.height - 16))

        self.setFrame(NSRect(origin: targetOrigin, size: fittingSize), display: true, animate: false)
    }
}
