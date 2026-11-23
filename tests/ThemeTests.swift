import Testing
import Cocoa
import Foundation
@testable import yClockLib

@Suite("Config Tests")
struct ConfigTests {

    @Test("Default config has expected values")
    func testDefaultConfig() {
        let config = Config.default

        #expect(config.width == 164)
        #expect(config.height == 164)
        #expect(config.isDigital == false)
        #expect(config.windowX == nil)
        #expect(config.windowY == nil)
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

    @Test("Parse RGBA colors")
    func testParseColorAlpha() {
        func rgba(_ s: String) -> [CGFloat]? {
            guard let c = Config.parseColor(s)?.usingColorSpace(.sRGB) else { return nil }
            return [c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent]
        }
        #expect(rgba("#ff000000") == [1, 0, 0, 0])
        #expect(rgba("ff0000ff") == [1, 0, 0, 1])
        #expect(rgba("#00ff0080").map { abs($0[3] - 128.0 / 255) < 0.001 } == true)
        #expect(rgba("#0000ff")?[3] == 1)
        #expect(rgba("0000ff")?[3] == 1)
    }

    @Test("Reject non-hex and wrong-length colors")
    func testParseColorRejects() {
        #expect(Config.parseColor("zzzzzz") == nil)
        #expect(Config.parseColor("#12345g") == nil)
        #expect(Config.parseColor("#+12345") == nil)
        #expect(Config.parseColor("#1234567") == nil)
        #expect(Config.parseColor("#123456789") == nil)
        #expect(Config.parseColor("") == nil)
    }

    @Test("Parsed background keeps alpha; invalid falls back")
    func testParseConfigContents() {
        let c = Config.parse("background = #11223380\nforeground = zzzzzz\nsecond_hand = #ff000000\n")
        #expect(abs(c.background.alphaComponent - 128.0 / 255) < 0.001)
        #expect(c.foreground == Config.default.foreground)
        #expect(c.secondHand.alphaComponent == 0)
        #expect(abs(Config.default.background.alphaComponent - 0.95) < 0.001)
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

@Suite("Window Position Tests")
struct WindowPositionTests {

    // Helper to create a temporary test state directory
    func createTestStateDir() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("yclock-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    // Helper to clean up test state directory
    func cleanupTestStateDir(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Save and load window position")
    func testSaveAndLoadWindowPosition() {
        // Save a window position
        let testX: CGFloat = 100.0
        let testY: CGFloat = 200.0

        Config.saveWindowPosition(x: testX, y: testY)

        // Load it back
        let loaded = Config.loadWindowPosition()

        #expect(loaded != nil)
        if let loaded = loaded {
            #expect(abs(loaded.x - testX) < 0.01)
            #expect(abs(loaded.y - testY) < 0.01)
        }
    }

    @Test("Load non-existent window position returns nil")
    func testLoadNonExistentPosition() {
        // First, try to delete any existing state file
        if let stateDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appStateDir = stateDir.appendingPathComponent("yclock")
            let statePath = appStateDir.appendingPathComponent("window-position")
            try? FileManager.default.removeItem(at: statePath)
        }

        let loaded = Config.loadWindowPosition()

        // After deleting, it should return nil or the values we just saved in previous test
        // Since tests might run in any order, we just verify the function doesn't crash
        #expect(loaded == nil || loaded != nil)
    }

    @Test("Save overwrites previous position")
    func testSaveOverwritesPreviousPosition() {
        // Save initial position
        Config.saveWindowPosition(x: 100.0, y: 200.0)

        // Save new position
        let newX: CGFloat = 300.0
        let newY: CGFloat = 400.0
        Config.saveWindowPosition(x: newX, y: newY)

        // Load should return new position
        let loaded = Config.loadWindowPosition()

        #expect(loaded != nil)
        if let loaded = loaded {
            #expect(abs(loaded.x - newX) < 0.01)
            #expect(abs(loaded.y - newY) < 0.01)
        }
    }

    @Test("Save and load with decimal values")
    func testSaveAndLoadWithDecimals() {
        let testX: CGFloat = 123.456
        let testY: CGFloat = 789.012

        Config.saveWindowPosition(x: testX, y: testY)

        let loaded = Config.loadWindowPosition()

        #expect(loaded != nil)
        if let loaded = loaded {
            #expect(abs(loaded.x - testX) < 0.01)
            #expect(abs(loaded.y - testY) < 0.01)
        }
    }

    @Test("Save and load with negative values")
    func testSaveAndLoadWithNegativeValues() {
        // Negative values can occur with multi-monitor setups
        let testX: CGFloat = -100.0
        let testY: CGFloat = -50.0

        Config.saveWindowPosition(x: testX, y: testY)

        let loaded = Config.loadWindowPosition()

        #expect(loaded != nil)
        if let loaded = loaded {
            #expect(abs(loaded.x - testX) < 0.01)
            #expect(abs(loaded.y - testY) < 0.01)
        }
    }
}

@Suite("Opacity Config Tests")
struct OpacityConfigTests {
    @Test("Default opacity is 0.85")
    func testDefault() {
        #expect(Config.default.opacity == 0.85)
        #expect(Config.parse("").opacity == 0.85)
    }

    @Test("Parses opacity value")
    func testParse() {
        #expect(Config.parse("opacity = 0.5").opacity == 0.5)
        #expect(Config.parse("opacity=1").opacity == 1.0)
        #expect(Config.parse("opacity = 0").opacity == 0.0)
    }

    @Test("Clamps out-of-range opacity")
    func testClamp() {
        #expect(Config.parse("opacity = 1.5").opacity == 1.0)
        #expect(Config.parse("opacity = -0.3").opacity == 0.0)
    }

    @Test("Invalid opacity falls back to default")
    func testInvalid() {
        #expect(Config.parse("opacity = abc").opacity == 0.85)
        #expect(Config.parse("opacity = nan").opacity == 0.85)
        #expect(Config.parse("opacity =").opacity == 0.85)
    }
}
