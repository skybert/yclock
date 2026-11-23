import Testing
import Cocoa
@testable import yClockLib

@Suite("ClockView Tests")
struct ClockViewTests {
    
    @Test("ClockView initializes with expected defaults")
    func testClockViewInitialization() {
        let frame = NSRect(x: 0, y: 0, width: 200, height: 200)
        let clockView = ClockView(frame: frame)
        
        #expect(clockView.isDigital == false)
        #expect(clockView.showSeconds == false)
        #expect(clockView.timer != nil)
    }
    
    @Test("Toggle clock mode switches between digital and analog")
    func testToggleClockMode() {
        let clockView = ClockView(frame: .zero)
        
        #expect(clockView.isDigital == false)
        clockView.toggleClockMode()
        #expect(clockView.isDigital == true)
        clockView.toggleClockMode()
        #expect(clockView.isDigital == false)
    }
    
    @Test("Toggle seconds switches visibility")
    func testToggleSeconds() {
        let clockView = ClockView(frame: .zero)
        
        #expect(clockView.showSeconds == false)
        clockView.toggleSeconds()
        #expect(clockView.showSeconds == true)
        clockView.toggleSeconds()
        #expect(clockView.showSeconds == false)
    }
    
    @Test("isFlipped returns true")
    func testIsFlipped() {
        let clockView = ClockView(frame: .zero)
        #expect(clockView.isFlipped == true)
    }

    @Test("Render factor for square, non-square and zero bounds")
    func testRenderFactor() {
        let square = ClockView(frame: NSRect(x: 0, y: 0, width: 164, height: 164))
        #expect(abs(square.renderFactor - 1.64) < 1e-9)

        let wide = ClockView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        #expect(abs(wide.renderFactor - 2.0) < 1e-9)

        wide.designSize = NSSize(width: 200, height: 100)
        #expect(abs(wide.renderFactor - 2.0) < 1e-9)
        wide.setFrameSize(NSSize(width: 100, height: 300))
        #expect(abs(wide.renderFactor - 0.5) < 1e-9)
        #expect(abs((wide.layer?.cornerRadius ?? 0) - Metrics.cornerRadius * 0.5) < 1e-9)

        #expect(ClockView(frame: .zero).renderFactor == 0)
    }
}
