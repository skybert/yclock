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

enum FollowDrag {
    static func shouldStart(
        hasModifiers: Bool, modifiersMatch: Bool, previouslyMatched: Bool, pointerInside: Bool
    ) -> Bool {
        hasModifiers && modifiersMatch && !previouslyMatched && pointerInside
    }

    /// All rects are in global coordinates (y up); screens are visibleFrames.
    static func origin(
        startOrigin: CGPoint, startMouse: CGPoint, mouse: CGPoint, windowSize: CGSize, screens: [CGRect]
    ) -> CGPoint {
        let desired = CGPoint(x: startOrigin.x + mouse.x - startMouse.x, y: startOrigin.y + mouse.y - startMouse.y)
        let desiredFrame = CGRect(origin: desired, size: windowSize)
        if screens.contains(where: { $0.contains(desiredFrame) }) { return desired }
        guard let screen = screens.first(where: { $0.contains(mouse) })
            ?? screens.max(by: { area($0.intersection(desiredFrame)) < area($1.intersection(desiredFrame)) })
        else { return desired }
        return CGPoint(
            x: clamp(desired.x, lower: screen.minX, upper: screen.maxX - windowSize.width, fallback: screen.minX),
            y: clamp(desired.y, lower: screen.minY, upper: screen.maxY - windowSize.height,
                     fallback: screen.maxY - windowSize.height))
    }

    private static func area(_ r: CGRect) -> CGFloat { r.isNull ? 0 : r.width * r.height }

    private static func clamp(_ v: CGFloat, lower: CGFloat, upper: CGFloat, fallback: CGFloat) -> CGFloat {
        upper < lower ? fallback : min(max(v, lower), upper)
    }
}

enum RoundedHitTest {
    static func contains(_ p: CGPoint, in rect: CGRect, radius: CGFloat) -> Bool {
        guard rect.contains(p) else { return false }
        let r = max(0, min(radius, min(rect.width, rect.height) / 2))
        let cx = min(max(p.x, rect.minX + r), rect.maxX - r)
        let cy = min(max(p.y, rect.minY + r), rect.maxY - r)
        let dx = p.x - cx, dy = p.y - cy
        return dx * dx + dy * dy <= r * r
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
    private var followTimer: Timer?
    private var followStartOrigin = CGPoint.zero
    private var followStartMouse = CGPoint.zero
    private var modifiersMatched = false
    private var locking = false

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
        followTimer?.invalidate()
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
        let radius = ClockView.effectiveCornerRadius(
            clockView.geometry.cornerRadius, factor: clockView.renderFactor, size: clockView.bounds.size)
        let mouseIn = RoundedHitTest.contains(NSEvent.mouseLocation, in: window.frame, radius: radius)
        let match = config.unlockModifiers.isSatisfied(by: NSEvent.modifierFlags)
        handle(.tick(mouseIn: mouseIn, modifiersMatch: match))
        updateFollow(mouseIn: mouseIn, match: match)
    }

    private func updateFollow(mouseIn: Bool, match: Bool) {
        guard phase == .unlocked, !locking else {
            modifiersMatched = false
            return
        }
        if followTimer == nil,
           FollowDrag.shouldStart(
               hasModifiers: !config.unlockModifiers.isEmpty, modifiersMatch: match,
               previouslyMatched: modifiersMatched, pointerInside: mouseIn) {
            startFollowing()
        }
        modifiersMatched = match
    }

    private func startFollowing() {
        followStartOrigin = window.frame.origin
        followStartMouse = NSEvent.mouseLocation
        followTimer = scheduled(interval: 1.0 / 60) { [weak self] in self?.followStep() }
        handle(.dragStarted)
    }

    private func followStep() {
        guard config.unlockModifiers.isSatisfied(by: NSEvent.modifierFlags) else {
            stopFollowing()
            handle(.dragEnded)
            return
        }
        let origin = FollowDrag.origin(
            startOrigin: followStartOrigin, startMouse: followStartMouse, mouse: NSEvent.mouseLocation,
            windowSize: window.frame.size, screens: NSScreen.screens.map { $0.visibleFrame })
        if origin != window.frame.origin { window.setFrameOrigin(origin) }
    }

    private func stopFollowing() {
        followTimer?.invalidate()
        followTimer = nil
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
        stopFollowing()
        locking = false
        modifiersMatched = false
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
        locking = false
        modifiersMatched = false
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
        stopFollowing()
        locking = true
        phase = .unlocked
        applyAppearance()
        clockView.eraseRing(color: config.unlockedColor, duration: duration)
        finish(after: duration, id: id)
    }
}
