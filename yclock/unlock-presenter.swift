import Cocoa

struct ModifierSet: OptionSet, Equatable {
    let rawValue: Int
    static let command = ModifierSet(rawValue: 1)
    static let option = ModifierSet(rawValue: 2)
    static let control = ModifierSet(rawValue: 4)
    static let shift = ModifierSet(rawValue: 8)

    static let defaultUnlock: ModifierSet = [.shift]

    /// Names separated by any non-letters; "none" or empty means no modifier. Invalid names give nil.
    static func parse(_ value: String) -> ModifierSet? {
        let tokens = value.lowercased().split(whereSeparator: { !($0.isASCII && $0.isLetter) })
        if tokens.isEmpty || (tokens.count == 1 && tokens[0] == "none") { return [] }
        var set: ModifierSet = []
        for t in tokens {
            switch t {
            case "cmd", "command": set.insert(.command)
            case "opt", "option", "alt": set.insert(.option)
            case "ctrl", "control": set.insert(.control)
            case "shift": set.insert(.shift)
            default: return nil
            }
        }
        return set
    }

    init(rawValue: Int) { self.rawValue = rawValue }

    init(flags: NSEvent.ModifierFlags) {
        var set: ModifierSet = []
        if flags.contains(.command) { set.insert(.command) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.shift) { set.insert(.shift) }
        self = set
    }

    /// True when exactly the required modifiers are held (always true when none are required).
    func isSatisfied(by flags: NSEvent.ModifierFlags) -> Bool {
        isEmpty || ModifierSet(flags: flags) == self
    }
}

enum ActivationPolicies {
    static func effectiveShowInDock(option: Bool?, config: Config) -> Bool {
        option ?? config.showInDock
    }

    static func startup(showInDock: Bool) -> NSApplication.ActivationPolicy {
        showInDock ? .regular : .accessory
    }

    static func switchesOnUnlock(clickThrough: Bool, unlockedInAppSwitcher: Bool, showInDock: Bool) -> Bool {
        clickThrough && unlockedInAppSwitcher && !showInDock
    }

    static func idle(showInDock: Bool) -> NSApplication.ActivationPolicy {
        startup(showInDock: showInDock)
    }

    static func unlocked(clickThrough: Bool, unlockedInAppSwitcher: Bool, showInDock: Bool) -> NSApplication.ActivationPolicy {
        switchesOnUnlock(clickThrough: clickThrough, unlockedInAppSwitcher: unlockedInAppSwitcher, showInDock: showInDock)
            ? .regular : startup(showInDock: showInDock)
    }
}

enum PresenterPhase { case idle, unlocking, unlocked }

enum UnlockedDimming {
    struct Appearance: Equatable {
        var windowAlpha: CGFloat
        var contentAlpha: CGFloat
        var opaqueBackground: Bool
    }

    static func appearance(phase: PresenterPhase, isKey: Bool, configOpacity: CGFloat, backgroundAlpha: CGFloat) -> Appearance {
        switch phase {
        case .idle: return Appearance(windowAlpha: configOpacity, contentAlpha: 1, opaqueBackground: false)
        case .unlocking: return Appearance(windowAlpha: max(configOpacity, 0.2), contentAlpha: 1, opaqueBackground: false)
        case .unlocked:
            if isKey { return Appearance(windowAlpha: 1, contentAlpha: 1, opaqueBackground: backgroundAlpha > 0) }
            return Appearance(windowAlpha: 1, contentAlpha: max(configOpacity / 2, 0.2), opaqueBackground: false)
        }
    }
}

final class ClickThroughPresenter: UnlockPresenter {
    private let window: NSWindow
    private let clockView: ClockView
    private let config: Config
    private let configuredShadow: Bool
    private var controller: UnlockController!
    private var slowTimer: Timer?
    private var fastTimer: Timer?
    private var animationTimer: Timer?
    private var monitor: Any?
    private let useAppSwitcher: Bool
    private let idlePolicy: NSApplication.ActivationPolicy
    private let unlockedPolicy: NSApplication.ActivationPolicy
    private var switchedToRegular = false
    private var phase = PresenterPhase.idle
    private var keyObservers: [NSObjectProtocol] = []

    init(window: NSWindow, clockView: ClockView, config: Config, showInDock: Bool = false) {
        useAppSwitcher = ActivationPolicies.switchesOnUnlock(
            clickThrough: true, unlockedInAppSwitcher: config.unlockedInAppSwitcher, showInDock: showInDock)
        idlePolicy = ActivationPolicies.idle(showInDock: showInDock)
        unlockedPolicy = ActivationPolicies.unlocked(
            clickThrough: true, unlockedInAppSwitcher: config.unlockedInAppSwitcher, showInDock: showInDock)
        self.window = window
        self.clockView = clockView
        self.config = config
        configuredShadow = window.hasShadow
        clockView.unlockRingWidth = config.unlockRingWidth
        controller = UnlockController(clickThrough: true, unlockDuration: config.unlockHoverDelay, presenter: self)

        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            keyObservers.append(NotificationCenter.default.addObserver(
                forName: name, object: window, queue: .main) { [weak self] _ in self?.applyAppearance() })
        }

        // Polling instead of global event monitors, which require Accessibility permission.
        slowTimer = scheduled(interval: 1) { [weak self] in self?.tick() }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, event.window === self.window { self.handle(.mouseDown) }
            return event
        }
    }

    deinit {
        slowTimer?.invalidate()
        fastTimer?.invalidate()
        animationTimer?.invalidate()
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
        keyObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func applyAppearance() {
        let a = UnlockedDimming.appearance(
            phase: phase, isKey: window.isKeyWindow, configOpacity: CGFloat(config.opacity),
            backgroundAlpha: config.background.alphaComponent)
        window.alphaValue = a.windowAlpha
        clockView.contentAlpha = a.contentAlpha
        clockView.opaqueBackground = a.opaqueBackground
    }

    func handle(_ event: UnlockEvent) {
        controller.handle(event)
        syncFastTimer()
    }

    private func tick() {
        let mouseIn = window.frame.contains(NSEvent.mouseLocation)
        let match = config.unlockModifiers.isSatisfied(by: NSEvent.modifierFlags)
        handle(.tick(mouseIn: mouseIn, modifiersMatch: match))
    }

    private func scheduled(interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: true) { _ in block() }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func syncFastTimer() {
        if controller.wantsFastTicks {
            if fastTimer == nil { fastTimer = scheduled(interval: 0.05) { [weak self] in self?.tick() } }
        } else {
            fastTimer?.invalidate()
            fastTimer = nil
        }
    }

    // A Timer, not a CATransaction completion block: that also fires when an animation is removed early.
    private func finish(after duration: TimeInterval, id: Int) {
        animationTimer?.invalidate()
        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in self?.handle(.animationFinished(id)) }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func cancelAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func showIdle() {
        cancelAnimation()
        phase = .idle
        applyAppearance()
        if switchedToRegular {
            switchedToRegular = false
            NSApp.setActivationPolicy(idlePolicy)
            window.orderFrontRegardless()
        }
        clockView.hideRing()
        window.hasShadow = configuredShadow
        window.ignoresMouseEvents = true
    }

    func startUnlocking(duration: TimeInterval, id: Int) {
        phase = .unlocking
        applyAppearance()
        clockView.fillRing(color: config.unlockingColor, duration: duration)
        finish(after: duration, id: id)
    }

    func showUnlocked(pulse: Bool) {
        cancelAnimation()
        clockView.showFullRing(color: config.unlockedColor)
        phase = .unlocked
        applyAppearance()
        window.hasShadow = true
        window.ignoresMouseEvents = false
        if useAppSwitcher && !switchedToRegular {
            switchedToRegular = true
            let wasActive = NSApp.isActive
            NSApp.setActivationPolicy(unlockedPolicy)
            window.orderFrontRegardless()
            if wasActive { NSApp.activate(ignoringOtherApps: true) }
        }
        if pulse { clockView.flash() }
    }

    func startLocking(duration: TimeInterval, id: Int) {
        phase = .unlocked
        applyAppearance()
        clockView.eraseRing(color: config.unlockedColor, duration: duration)
        finish(after: duration, id: id)
    }
}
