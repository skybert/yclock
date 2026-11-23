import Testing
import Foundation
@testable import yClockLib

@Suite struct FollowDragTests {
    let size = CGSize(width: 100, height: 50)
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private func origin(_ start: CGPoint, _ mouse: CGPoint, _ screens: [CGRect], size: CGSize? = nil) -> CGPoint {
        FollowDrag.origin(
            startOrigin: start, startMouse: CGPoint(x: 150, y: 125), mouse: mouse,
            windowSize: size ?? self.size, screens: screens)
    }

    @Test func insideFollowsDelta() {
        #expect(origin(CGPoint(x: 100, y: 100), CGPoint(x: 250, y: 225), [screen]) == CGPoint(x: 200, y: 200))
    }

    @Test func clampsEachEdge() {
        let s = CGPoint(x: 100, y: 100)
        #expect(origin(s, CGPoint(x: 10, y: 125), [screen]).x == 0)
        #expect(origin(s, CGPoint(x: 990, y: 125), [screen]).x == 900)
        #expect(origin(s, CGPoint(x: 150, y: 5), [screen]).y == 0)
        #expect(origin(s, CGPoint(x: 150, y: 795), [screen]).y == 750)
    }

    @Test func sideBySideDifferentHeights() {
        let a = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let b = CGRect(x: 1000, y: 200, width: 800, height: 600)
        let s = CGPoint(x: 100, y: 100)
        #expect(origin(s, CGPoint(x: 1300, y: 210), [a, b]) == CGPoint(x: 1250, y: 200))
        #expect(origin(s, CGPoint(x: 1300, y: 790), [a, b]) == CGPoint(x: 1250, y: 750))
    }

    @Test func movingToSecondScreenLandsFullyInside() {
        let a = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let b = CGRect(x: 1000, y: 0, width: 1000, height: 800)
        let p = origin(CGPoint(x: 100, y: 100), CGPoint(x: 1010, y: 125), [a, b])
        #expect(p == CGPoint(x: 1000, y: 100))
        #expect(b.contains(CGRect(origin: p, size: size)))
    }

    @Test func verticallyStacked() {
        let lower = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let upper = CGRect(x: 0, y: 800, width: 1000, height: 700)
        let s = CGPoint(x: 100, y: 700)
        let p = origin(s, CGPoint(x: 150, y: 830), [lower, upper])
        #expect(upper.contains(CGRect(origin: p, size: size)))
        #expect(origin(s, CGPoint(x: 150, y: 1490), [lower, upper]).y == 1450)
    }

    @Test func negativeCoordinates() {
        let left = CGRect(x: -1200, y: -100, width: 1200, height: 900)
        let main = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let s = CGPoint(x: 100, y: 100)
        #expect(origin(s, CGPoint(x: -1190, y: 125), [left, main]) == CGPoint(x: -1200, y: 100))
        #expect(origin(s, CGPoint(x: -600, y: -90), [left, main]) == CGPoint(x: -650, y: -100))
    }

    @Test func largerThanScreenAlignsTopLeft() {
        let big = CGSize(width: 1200, height: 900)
        let p = origin(CGPoint(x: 0, y: 0), CGPoint(x: 500, y: 500), [screen], size: big)
        #expect(p == CGPoint(x: 0, y: -100))
    }

    @Test func mouseOutsideAllScreensUsesLargestIntersection() {
        let a = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let b = CGRect(x: 1000, y: 0, width: 1000, height: 800)
        let p = origin(CGPoint(x: 1100, y: 100), CGPoint(x: 150, y: 805), [a, b])
        #expect(p == CGPoint(x: 1100, y: 750))
        let q = origin(CGPoint(x: 100, y: 100), CGPoint(x: 150, y: 900), [a, b])
        #expect(q == CGPoint(x: 100, y: 750))
    }

    @Test func startCondition() {
        func f(_ m: Bool, prev: Bool, inside: Bool, has: Bool = true) -> Bool {
            FollowDrag.shouldStart(hasModifiers: has, modifiersMatch: m, previouslyMatched: prev, pointerInside: inside)
        }
        #expect(f(true, prev: false, inside: true))
        #expect(!f(true, prev: true, inside: true))
        #expect(!f(true, prev: false, inside: false))
        #expect(!f(false, prev: false, inside: true))
        #expect(!f(true, prev: false, inside: true, has: false))
    }
}
