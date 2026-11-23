import Testing
import Foundation
@testable import yClockLib

@Suite struct UnlockedDimmingTests {
    typealias A = UnlockedDimming.Appearance

    private func appearance(_ phase: PresenterPhase, key: Bool, opacity: CGFloat, bg: CGFloat = 0.9) -> A {
        UnlockedDimming.appearance(phase: phase, isKey: key, configOpacity: opacity, backgroundAlpha: bg)
    }

    @Test func idleUsesConfigOpacity() {
        for key in [true, false] {
            #expect(appearance(.idle, key: key, opacity: 0.5) == A(windowAlpha: 0.5, contentAlpha: 1, opaqueBackground: false))
        }
    }

    @Test func unlockingHasFloor() {
        #expect(appearance(.unlocking, key: false, opacity: 0.5) == A(windowAlpha: 0.5, contentAlpha: 1, opaqueBackground: false))
        #expect(appearance(.unlocking, key: false, opacity: 0.1) == A(windowAlpha: 0.2, contentAlpha: 1, opaqueBackground: false))
    }

    @Test func unlockedKeyIsOpaque() {
        #expect(appearance(.unlocked, key: true, opacity: 0.3) == A(windowAlpha: 1, contentAlpha: 1, opaqueBackground: true))
    }

    @Test func unlockedKeyKeepsInvisibleBackground() {
        #expect(appearance(.unlocked, key: true, opacity: 0.3, bg: 0) == A(windowAlpha: 1, contentAlpha: 1, opaqueBackground: false))
    }

    @Test func unlockedNotKeyDimsContentWithFloor() {
        #expect(appearance(.unlocked, key: false, opacity: 1) == A(windowAlpha: 1, contentAlpha: 0.5, opaqueBackground: false))
        #expect(appearance(.unlocked, key: false, opacity: 0.2) == A(windowAlpha: 1, contentAlpha: 0.2, opaqueBackground: false))
    }
}
