import Testing
import Foundation
@testable import yClockLib

@Suite struct RoundedHitTestTests {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

    private func hit(_ x: CGFloat, _ y: CGFloat, in r: CGRect? = nil, radius: CGFloat) -> Bool {
        RoundedHitTest.contains(CGPoint(x: x, y: y), in: r ?? rect, radius: radius)
    }

    @Test func zeroRadiusMatchesRect() {
        for p in [CGPoint(x: 0, y: 0), CGPoint(x: 99, y: 49), CGPoint(x: 50, y: 25), CGPoint(x: 100, y: 50), CGPoint(x: -1, y: 5)] {
            #expect(RoundedHitTest.contains(p, in: rect, radius: 0) == rect.contains(p))
        }
    }

    @Test func straightEdgesInside() {
        #expect(hit(50, 0, radius: 10))
        #expect(hit(50, 49.9, radius: 10))
        #expect(hit(0, 25, radius: 10))
        #expect(hit(99.9, 25, radius: 10))
    }

    @Test func cornerOutsideArc() {
        #expect(!hit(1, 1, radius: 10))
        #expect(!hit(99, 49, radius: 10))
    }

    @Test func cornerInsideArc() {
        #expect(hit(5, 5, radius: 10))
        #expect(hit(3, 3, radius: 10))
    }

    @Test func exactBoundary() {
        #expect(hit(0, 10, radius: 10))
        #expect(hit(10, 0, radius: 10))
        #expect(hit(6, 2, radius: 10))
    }

    @Test func squareHugeRadiusIsCircle() {
        let sq = CGRect(x: 0, y: 0, width: 100, height: 100)
        #expect(hit(50, 50, in: sq, radius: 1000))
        #expect(!hit(1, 1, in: sq, radius: 1000))
        #expect(!hit(99, 1, in: sq, radius: 1000))
        #expect(hit(50 + 49, 50, in: sq, radius: 1000))
        #expect(hit(50 + 34, 50 + 34, in: sq, radius: 1000))
        #expect(!hit(50 + 36, 50 + 36, in: sq, radius: 1000))
    }

    @Test func capsule() {
        #expect(hit(50, 25, radius: 1000))
        #expect(hit(25, 25, radius: 1000))
        #expect(hit(1, 25, radius: 1000))
        #expect(!hit(1, 1, radius: 1000))
        #expect(!hit(99, 49, radius: 1000))
    }

    @Test func outsideRect() {
        #expect(!hit(-1, 25, radius: 10))
        #expect(!hit(50, 51, radius: 10))
        #expect(!hit(100, 25, radius: 10))
    }

    @Test func negativeCoordinates() {
        let r = CGRect(x: -1920, y: -200, width: 100, height: 50)
        #expect(hit(-1870, -175, in: r, radius: 10))
        #expect(!hit(-1919, -199, in: r, radius: 10))
        #expect(hit(-1915, -195, in: r, radius: 10))
        #expect(!hit(-1800, -175, in: r, radius: 10))
    }

    @Test func negativeRadiusTreatedAsZero() {
        #expect(hit(0, 0, radius: -5))
    }
}
