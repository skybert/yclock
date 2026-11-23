import Testing
import Foundation
@testable import yClockLib

private final class FakePresenter: UnlockPresenter {
    enum Call: Equatable {
        case idle
        case unlocking(Int)
        case unlocked(pulse: Bool)
        case locking(Int)
    }
    var calls: [Call] = []
    var lastID = 0

    func showIdle() { calls.append(.idle) }
    func startUnlocking(duration: TimeInterval, id: Int) { lastID = id; calls.append(.unlocking(id)) }
    func showUnlocked(pulse: Bool) { calls.append(.unlocked(pulse: pulse)) }
    func startLocking(duration: TimeInterval, id: Int) { lastID = id; calls.append(.locking(id)) }
}

private let hover = UnlockEvent.tick(mouseIn: true, modifiersMatch: true)
private let away = UnlockEvent.tick(mouseIn: false, modifiersMatch: true)

private func make(clickThrough: Bool = true, duration: TimeInterval = 1, launched: Bool = true)
    -> (UnlockController, FakePresenter) {
    let p = FakePresenter()
    let c = UnlockController(clickThrough: clickThrough, unlockDuration: duration, presenter: p)
    if launched { c.handle(away) }
    return (c, p)
}

@Suite("Unlock State Machine Tests")
struct UnlockTests {

    @Test("Starts idle and calls showIdle when click-through is on")
    func initIdle() {
        let (c, p) = make(launched: false)
        #expect(c.state == .idle)
        #expect(p.calls == [.idle])
    }

    @Test("Disabled ignores everything and never touches presenter")
    func disabled() {
        let (c, p) = make(clickThrough: false)
        for e: UnlockEvent in [hover, away, .appActivated, .appDeactivated, .mouseDown, .animationFinished(1)] {
            c.handle(e)
        }
        #expect(c.state == .disabled)
        #expect(p.calls.isEmpty)
        #expect(!c.wantsFastTicks)
    }

    @Test("Hover with matching modifiers starts unlocking, finish unlocks with pulse")
    func hoverUnlock() {
        let (c, p) = make()
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .unlocked)
        #expect(p.calls.last == .unlocked(pulse: true))
    }

    @Test("Modifiers mismatch does not start unlocking")
    func modifiersMismatch() {
        let (c, _) = make()
        c.handle(.tick(mouseIn: true, modifiersMatch: false))
        #expect(c.state == .idle)
    }

    @Test("Leaving or losing modifiers aborts unlocking immediately")
    func abortUnlocking() {
        let (c, p) = make()
        c.handle(hover)
        c.handle(away)
        #expect(c.state == .idle)
        #expect(p.calls.last == .idle)

        c.handle(hover)
        #expect(c.state == .animateUnlocking)
        c.handle(.tick(mouseIn: true, modifiersMatch: false))
        #expect(c.state == .idle)
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
    }

    @Test("Stale animationFinished is ignored")
    func staleFinish() {
        let (c, p) = make()
        c.handle(hover)
        let first = p.lastID
        c.handle(away)
        c.handle(hover)
        c.handle(.animationFinished(first))
        #expect(c.state == .animateUnlocking)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .unlocked)
    }

    @Test("Launch activation is ignored; later activation unlocks with pulse")
    func launchActivation() {
        let (c, p) = make(launched: false)
        c.handle(.appActivated)
        #expect(c.state == .idle)
        c.handle(away)
        c.handle(.appActivated)
        #expect(c.state == .unlocked)
        #expect(p.calls.last == .unlocked(pulse: true))
    }

    @Test("Activation during unlocking animation unlocks")
    func activateWhileUnlocking() {
        let (c, _) = make()
        c.handle(hover)
        c.handle(.appActivated)
        #expect(c.state == .unlocked)
    }

    @Test("Unlocked locks after mouse leaves, once mouse was seen and no click happened")
    func lockAfterLeave() {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(away)
        #expect(c.state == .unlocked)
        c.handle(hover)
        c.handle(away)
        #expect(c.state == .animateLocking)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .idle)
    }

    @Test("Click prevents lock on mouse leave")
    func interactedStaysUnlocked() {
        let (c, _) = make()
        c.handle(.appActivated)
        c.handle(hover)
        c.handle(.mouseDown)
        c.handle(away)
        #expect(c.state == .unlocked)
    }

    @Test("Unlocked entry resets seenMouse and interacted")
    func entryResets() {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(hover)
        c.handle(.mouseDown)
        c.handle(.appDeactivated)
        c.handle(.appActivated)
        #expect(c.state == .unlocked)
        c.handle(away)
        #expect(c.state == .unlocked)
        c.handle(hover)
        c.handle(away)
        #expect(c.state == .animateLocking)
        #expect(p.calls.last == .locking(p.lastID))
    }

    @Test("Deactivation locks")
    func deactivateLocks() {
        let (c, _) = make()
        c.handle(.appActivated)
        c.handle(.appDeactivated)
        #expect(c.state == .animateLocking)
    }

    @Test("Locking is cancelled without pulse by mouse entering, activation or click")
    func cancelLocking() {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(.appDeactivated)
        c.handle(hover)
        #expect(c.state == .unlocked)
        #expect(p.calls.last == .unlocked(pulse: false))

        c.handle(.appDeactivated)
        c.handle(.appActivated)
        #expect(c.state == .unlocked)
        #expect(p.calls.last == .unlocked(pulse: false))

        c.handle(.appDeactivated)
        c.handle(.mouseDown)
        #expect(c.state == .unlocked)
        #expect(p.calls.last == .unlocked(pulse: false))
    }

    @Test("Mouse staying inside does not abort locking")
    func stayingInDoesNotAbort() {
        let (c, _) = make()
        c.handle(.appActivated)
        c.handle(hover)
        c.handle(.appDeactivated)
        c.handle(hover)
        c.handle(hover)
        #expect(c.state == .animateLocking)
    }

    @Test("Stale finish during locking is ignored")
    func staleLockFinish() {
        let (c, p) = make()
        c.handle(hover)
        let unlockID = p.lastID
        c.handle(.animationFinished(unlockID))
        c.handle(.appDeactivated)
        c.handle(.animationFinished(unlockID))
        #expect(c.state == .animateLocking)
    }

    @Test("Cmd+Tab away with pointer over clock: no immediate re-unlock until mouse-out tick")
    func rearm() {
        let (c, p) = make()
        c.handle(hover)
        c.handle(.animationFinished(p.lastID))
        c.handle(.appDeactivated)
        c.handle(hover)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .idle)
        c.handle(hover)
        c.handle(hover)
        #expect(c.state == .idle)
        c.handle(away)
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
    }

    @Test("Instant lock when duration is 0")
    func instantLock() {
        let (c, p) = make(duration: 0)
        c.handle(.appActivated)
        c.handle(.appDeactivated)
        #expect(c.state == .idle)
        #expect(p.calls.last == .idle)
        #expect(!p.calls.contains { if case .locking = $0 { return true } else { return false } })

        c.handle(.appActivated)
        c.handle(hover)
        c.handle(away)
        #expect(c.state == .idle)
    }

    @Test("Instant lock re-arms only after mouse-out tick")
    func instantLockRearm() {
        let (c, p) = make(duration: 1)
        c.handle(.appActivated)
        c.handle(hover)
        c.handle(.appDeactivated)
        c.handle(.animationFinished(p.lastID))
        c.handle(hover)
        #expect(c.state == .idle)
    }

    @Test("Hover unlock disabled when duration is 0, activation still unlocks")
    func hoverDisabled() {
        let (c, _) = make(duration: 0)
        c.handle(hover)
        #expect(c.state == .idle)
        c.handle(.appActivated)
        #expect(c.state == .unlocked)
    }

    @Test("wantsFastTicks per state")
    func fastTicks() {
        let (c, p) = make()
        #expect(!c.wantsFastTicks)
        c.handle(hover)
        #expect(c.wantsFastTicks)
        c.handle(.animationFinished(p.lastID))
        #expect(c.wantsFastTicks)
        c.handle(.appDeactivated)
        #expect(c.wantsFastTicks)
        c.handle(away)
        c.handle(.animationFinished(p.lastID))
        #expect(!c.wantsFastTicks)
    }

    @Test("Pulse only on fresh unlock")
    func pulseOnlyFresh() {
        let (c, p) = make()
        c.handle(hover)
        c.handle(.animationFinished(p.lastID))
        c.handle(.appDeactivated)
        c.handle(.mouseDown)
        let pulses = p.calls.compactMap { call -> Bool? in
            if case .unlocked(let pulse) = call { return pulse } else { return nil }
        }
        #expect(pulses == [true, false])
    }
}

@Suite("Relaunch re-entry")
struct RelaunchReentryTests {

    private func relaunchedAndLocked() -> (UnlockController, FakePresenter) {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(.appActivated)
        c.handle(.appDeactivated)
        #expect(c.state == .animateLocking)
        return (c, p)
    }

    @Test("Duplicate activation events produce a single unlock")
    func duplicateActivation() {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(.appActivated)
        let unlocks = p.calls.filter { if case .unlocked = $0 { return true } else { return false } }
        #expect(unlocks.count == 1)
    }

    @Test("Mouse outside during lock animation: immediate hover after lock starts unlocking")
    func hoverRightAfterLock() {
        let (c, p) = relaunchedAndLocked()
        c.handle(away)
        c.handle(away)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .idle)
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
    }

    @Test("Mouse outside at lock finish: only slow ticks follow, hover on the next tick must unlock")
    func hoverOnFirstSlowTick() {
        let (c, p) = relaunchedAndLocked()
        c.handle(away)
        c.handle(.animationFinished(p.lastID))
        #expect(!c.wantsFastTicks)
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
    }

    @Test("Mouse inside at lock finish: fast ticks continue until mouse leaves, so a quick out-in is seen")
    func quickOutInAfterLock() {
        let (c, p) = make()
        c.handle(.appActivated)
        c.handle(hover)
        c.handle(.appDeactivated)
        c.handle(hover)
        c.handle(.animationFinished(p.lastID))
        #expect(c.state == .idle)
        #expect(c.wantsFastTicks)
        c.handle(away)
        c.handle(hover)
        #expect(c.state == .animateUnlocking)
        c.handle(away)
        #expect(!c.wantsFastTicks)
    }
}
