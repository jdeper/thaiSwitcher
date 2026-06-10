import Carbon

enum InputSourceManager {

    // After converting Thai→English, switch to English; English→Thai, switch to Thai.
    static func switchTo(thai: Bool) {
        let filter = [kTISPropertyInputSourceIsEnabled: true] as CFDictionary
        guard let unmanaged = TISCreateInputSourceList(filter, false) else { return }
        let cfArray = unmanaged.takeRetainedValue()
        let count = CFArrayGetCount(cfArray)

        for i in 0..<count {
            guard let rawPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            let source = Unmanaged<TISInputSource>.fromOpaque(rawPtr).takeUnretainedValue()

            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String

            // Only consider keyboard layouts, not emoji / dictation / etc.
            if let catPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) {
                let cat = Unmanaged<CFString>.fromOpaque(catPtr).takeUnretainedValue() as String
                guard cat == (kTISCategoryKeyboardInputSource as String) else { continue }
            }

            let isThai = id.lowercased().contains("thai")
            guard isThai == thai else { continue }

            TISSelectInputSource(source)
            return
        }
    }
}
