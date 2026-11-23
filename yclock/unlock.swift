// Click-through unlock state machine.
// idle -> animateUnlocking: pointer hovers over the clock (with the unlock modifier, if any).
// animateUnlocking -> unlocked: the ring completes, or the app gets activated.
// unlocked -> animateLocking: pointer leaves without a click, or the app deactivates.
// animateLocking -> idle when the animation ends; the pointer re-entering or a click cancels it.
// While dragging (unlock modifier held), leaving or deactivation is deferred until release.
// Activation during launch is ignored. After locking, unlocking is re-armed only once
// the pointer has left the clock.

import Foundation

enum UnlockState: Equatable {
    case disabled, idle, animateUnlocking, unlocked, animateLocking
}

enum UnlockEvent: Equatable {
    case tick(mouseIn: Bool, modifiersMatch: Bool)
    case appActivated
    case appDeactivated
    case mouseDown
    case dragStarted
    case dragEnded
    case animationFinished(Int)
}

protocol UnlockPresenter: AnyObject {
    func showIdle()
    func startUnlocking(duration: TimeInterval, id: Int)
    func showUnlocked(pulse: Bool)
    func startLocking(duration: TimeInterval, id: Int)
}

final class UnlockController {
    private(set) var state: UnlockState
    private weak var presenter: UnlockPresenter?
    private let unlockDuration: TimeInterval

    private var launching = true
    private var armed = true
    private var prevMouseIn = false
    private var seenMouse = false
    private var interacted = false
    private var dragging = false
    private var pendingLock = false
    private var animationID = 0

    var wantsFastTicks: Bool { (state != .idle && state != .disabled) || (state == .idle && !armed) }

    init(clickThrough: Bool, unlockDuration: TimeInterval, presenter: UnlockPresenter) {
        self.unlockDuration = unlockDuration
        self.presenter = presenter
        state = .disabled
        if clickThrough { transition(to: .idle) }
    }

    func handle(_ event: UnlockEvent) {
        guard state != .disabled else { return }

        var mouseEntered = false
        if case .tick(let mouseIn, _) = event {
            mouseEntered = mouseIn && !prevMouseIn
            if state == .unlocked && mouseIn { seenMouse = true }
        }
        if event == .mouseDown && state == .unlocked { interacted = true }
        if state == .unlocked {
            switch event {
            case .dragStarted: dragging = true
            case .dragEnded: dragging = false
            case .appDeactivated where dragging: pendingLock = true
            case .appActivated: pendingLock = false
            default: break
            }
        }

        if let next = nextState(for: event, mouseEntered: mouseEntered) {
            transition(to: next)
        }

        if case .tick(let mouseIn, _) = event {
            prevMouseIn = mouseIn
            launching = false
            if !mouseIn { armed = true }
        }
    }

    private func nextState(for event: UnlockEvent, mouseEntered: Bool) -> UnlockState? {
        switch (state, event) {
        case (.idle, .tick(let mouseIn, let match)):
            return mouseIn && match && unlockDuration > 0 && armed ? .animateUnlocking : nil
        case (.animateUnlocking, .tick(let mouseIn, let match)):
            return mouseIn && match ? nil : .idle
        case (.animateUnlocking, .animationFinished(let id)):
            return id == animationID ? .unlocked : nil
        case (.idle, .appActivated), (.animateUnlocking, .appActivated):
            return launching ? nil : .unlocked
        case (.unlocked, .tick(let mouseIn, _)):
            return !dragging && !mouseIn && seenMouse && !interacted ? lockTarget : nil
        case (.unlocked, .appDeactivated):
            return dragging ? nil : lockTarget
        case (.unlocked, .dragEnded):
            return pendingLock ? lockTarget : nil
        case (.animateLocking, .tick):
            return mouseEntered ? .unlocked : nil
        case (.animateLocking, .appActivated), (.animateLocking, .mouseDown):
            return .unlocked
        case (.animateLocking, .animationFinished(let id)):
            return id == animationID ? .idle : nil
        default:
            return nil
        }
    }

    private var lockTarget: UnlockState {
        unlockDuration > 0 ? .animateLocking : .idle
    }

    private func transition(to next: UnlockState) {
        let previous = state
        state = next
        dragging = false
        pendingLock = false
        switch next {
        case .disabled:
            break
        case .idle:
            if previous == .animateLocking || previous == .unlocked { armed = !prevMouseIn }
            presenter?.showIdle()
        case .animateUnlocking:
            animationID += 1
            presenter?.startUnlocking(duration: unlockDuration, id: animationID)
        case .unlocked:
            seenMouse = false
            interacted = false
            presenter?.showUnlocked(pulse: previous != .animateLocking)
        case .animateLocking:
            animationID += 1
            presenter?.startLocking(duration: unlockDuration, id: animationID)
        }
    }
}
