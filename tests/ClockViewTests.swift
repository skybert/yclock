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
}
