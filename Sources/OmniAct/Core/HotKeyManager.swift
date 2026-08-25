import Cocoa
import Carbon

public final class HotKeyManager: @unchecked Sendable {
    public static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onTrigger: (@Sendable () -> Void)?

    private init() {}

    deinit {
        unregister()
    }

    public func register(
        keyCode: UInt32 = UInt32(kVK_Space),
        modifiers: UInt32 = UInt32(optionKey),
        onTrigger: @escaping @Sendable () -> Void
    ) {
        unregister()
        self.onTrigger = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerCallback: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKeyEvent(event)
            return noErr
        }

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x4F4D4E49), id: 1) // 'OMNI'
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        onTrigger = nil
    }

    private func handleHotKeyEvent(_ event: EventRef?) {
        DispatchQueue.main.async { [weak self] in
            self?.onTrigger?()
        }
    }
}
