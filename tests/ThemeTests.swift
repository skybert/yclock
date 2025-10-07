import Testing
import Cocoa
@testable import yClockLib

@Suite("Config Tests")
struct ConfigTests {
    
    @Test("Default config has expected values")
    func testDefaultConfig() {
        let config = Config.default
        
        #expect(config.width == 164)
        #expect(config.height == 164)
        #expect(config.isDigital == false)
    }
    
    @Test("Parse color with hash")
    func testParseColorWithHash() {
        let color = Config.parseColor("#FF0000")
        #expect(color != nil)
        
        if let color = color {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            #expect(abs(red - 1.0) < 0.01)
            #expect(abs(green - 0.0) < 0.01)
            #expect(abs(blue - 0.0) < 0.01)
        }
    }
    
    @Test("Parse color without hash")
    func testParseColorWithoutHash() {
        let color = Config.parseColor("00FF00")
        #expect(color != nil)
        
        if let color = color {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            #expect(abs(red - 0.0) < 0.01)
            #expect(abs(green - 1.0) < 0.01)
            #expect(abs(blue - 0.0) < 0.01)
        }
    }
    
    @Test("Parse invalid colors returns nil")
    func testParseColorInvalid() {
        #expect(Config.parseColor("invalid") == nil)
        #expect(Config.parseColor("#FF") == nil)
        #expect(Config.parseColor("#FFFFFFF") == nil)
    }
    
    @Test("Parse blue color")
    func testParseBlueColor() {
        let color = Config.parseColor("#0000FF")
        #expect(color != nil)
        
        if let color = color {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            #expect(abs(red - 0.0) < 0.01)
            #expect(abs(green - 0.0) < 0.01)
            #expect(abs(blue - 1.0) < 0.01)
        }
    }
}
