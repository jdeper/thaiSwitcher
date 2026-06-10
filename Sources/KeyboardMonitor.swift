import Cocoa

// Keys that reset the word buffer
private let clearKeyCodes: Set<Int64> = [
    36,  // Return
    48,  // Tab
    49,  // Space (handled separately to allow space→space in output)
    53,  // Escape
    123, // Left arrow
    124, // Right arrow
    125, // Down arrow
    126, // Up arrow
]

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var buffer: [String] = []

    func start() {
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
            return monitor.handle(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            DispatchQueue.main.async { AccessibilityPrompt.show() }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let hasShift   = flags.contains(.maskShift)
        let hasCmd     = flags.contains(.maskCommand)
        let hasCtrl    = flags.contains(.maskControl)
        let hasOption  = flags.contains(.maskAlternate)

        // Cmd/Ctrl shortcuts mutate text fields unpredictably — reset buffer
        if hasCmd || hasCtrl {
            buffer = []
            return Unmanaged.passRetained(event)
        }

        // Shift+Backspace → convert & retype
        if keyCode == 51 && hasShift && !hasCmd && !hasCtrl && !hasOption {
            if !buffer.isEmpty {
                triggerConversion()
            }
            return nil // consume the event
        }

        // Regular Backspace → remove last char from buffer
        if keyCode == 51 && !hasShift {
            if !buffer.isEmpty { buffer.removeLast() }
            return Unmanaged.passRetained(event)
        }

        // Clear-triggering keys
        if clearKeyCodes.contains(keyCode) {
            buffer = []
            return Unmanaged.passRetained(event)
        }

        // Collect printable character
        var actualLen = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &actualLen, unicodeString: &chars)
        if actualLen > 0 {
            let ch = String(utf16CodeUnits: Array(chars.prefix(actualLen)), count: actualLen)
            // Only track printable (non-control) characters
            if let scalar = ch.unicodeScalars.first, scalar.value >= 0x20 {
                buffer.append(ch)
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func triggerConversion() {
        let text = buffer.joined()
        let wasThai = ThaiConverter.isMostlyThai(text)
        let deleteCount = buffer.count
        buffer = []

        let converted = ThaiConverter.convert(text)

        for _ in 0..<deleteCount {
            postKey(virtualKey: 0x33) // backspace
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.pasteString(converted)
            // Switch to the opposite layout after converting
            InputSourceManager.switchTo(thai: !wasThai)
        }
    }

    private func postKey(virtualKey: CGKeyCode, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: virtualKey, keyDown: true),
           let up   = CGEvent(keyboardEventSource: src, virtualKey: virtualKey, keyDown: false) {
            down.flags = flags
            up.flags   = flags
            // Post at annotatedSession so our tap (at session level) won't re-intercept
            down.post(tap: .cgAnnotatedSessionEventTap)
            up.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    private func pasteString(_ text: String) {
        let pb = NSPasteboard.general
        let previous = pb.string(forType: .string)
        pb.clearContents()
        pb.setString(text, forType: .string)

        postKey(virtualKey: 0x09, flags: .maskCommand) // Cmd+V

        // Restore clipboard after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            pb.clearContents()
            if let prev = previous { pb.setString(prev, forType: .string) }
        }
    }
}
