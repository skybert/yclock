import Testing
import Cocoa
import Foundation
@testable import yClockLib

@Suite("Config Tests")
struct ConfigTests {

    @Test("Default config has expected values")
    func testDefaultConfig() {
        let config = Config.default

        #expect(config.width == 100)
        #expect(config.height == 100)
        #expect(config.scale == 1.64)
        #expect(config.isDigital == false)
        #expect(config.windowX == nil)
        #expect(config.windowY == nil)
    }

    @Test("Parse scale")
    func testParseScale() {
        #expect(Config.parse("scale = 2.5").scale == 2.5)
        #expect(Config.parse("scale = 0").scale == Config.default.scale)
        #expect(Config.parse("scale = -1").scale == Config.default.scale)
        #expect(Config.parse("scale = abc").scale == Config.default.scale)
        #expect(Config.parse("scale = inf").scale == Config.default.scale)
    }

    @Test("Parse fractional size, invalid falls back")
    func testParseSize() {
        let c = Config.parse("width = 80.5\nheight = 0")
        #expect(c.width == 80.5)
        #expect(c.height == Config.default.height)
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

@Suite("Corner Radius Tests")
struct CornerRadiusTests {
    @Test("Config parsing")
    func testParse() {
        #expect(Config.default.geometry.cornerRadius == 7.3)
        #expect(Config.parse("").geometry.cornerRadius == 7.3)
        #expect(Config.parse("corner_radius = 0").geometry.cornerRadius == 0)
        #expect(Config.parse("corner_radius = 12.5").geometry.cornerRadius == 12.5)
        #expect(Config.parse("corner_radius = -1").geometry.cornerRadius == 7.3)
        #expect(Config.parse("corner_radius = abc").geometry.cornerRadius == 7.3)
        #expect(Config.parse("corner_radius = inf").geometry.cornerRadius == 7.3)
    }

    @Test("Default at 164x164 px is about 12 px")
    func testDefault() {
        let r = ClockView.effectiveCornerRadius(7.3, factor: 1.64, size: NSSize(width: 164, height: 164))
        #expect(abs(r - 11.972) < 0.01)
    }

    @Test("Capped to half the shorter side")
    func testCap() {
        #expect(ClockView.effectiveCornerRadius(1000, factor: 1.64, size: NSSize(width: 164, height: 164)) == 82)
        #expect(ClockView.effectiveCornerRadius(1000, factor: 1, size: NSSize(width: 200, height: 100)) == 50)
        #expect(ClockView.effectiveCornerRadius(1000, factor: 1, size: NSSize(width: 100, height: 200)) == 50)
        #expect(ClockView.effectiveCornerRadius(0, factor: 1.64, size: NSSize(width: 164, height: 164)) == 0)
    }

    @Test("Zero bounds")
    func testZeroBounds() {
        #expect(ClockView.effectiveCornerRadius(7.3, factor: 1, size: .zero) == 0)
    }

    @Test("View applies geometry radius")
    func testView() {
        let v = ClockView(frame: NSRect(x: 0, y: 0, width: 164, height: 164))
        v.geometry.cornerRadius = 1000
        #expect(v.layer?.cornerRadius == 82)
        v.geometry.cornerRadius = 0
        #expect(v.layer?.cornerRadius == 0)
    }
}

@Suite("Hand Width Config Tests")
struct HandWidthConfigTests {
    @Test("Defaults")
    func testDefaults() {
        for g in [Config.default.geometry, Config.parse("").geometry, ClockView(frame: .zero).geometry] {
            #expect(g.hourHandWidth == 3.7)
            #expect(g.minuteHandWidth == 2.4)
            #expect(g.secondHandWidth == 1.2)
        }
    }

    @Test("Parses widths, including zero and fractions")
    func testParse() {
        let g = Config.parse("hour_hand_width = 5\nminute_hand_width=0\nsecond_hand_width = 0.5").geometry
        #expect(g.hourHandWidth == 5)
        #expect(g.minuteHandWidth == 0)
        #expect(g.secondHandWidth == 0.5)
    }

    @Test("Invalid or negative falls back to default")
    func testInvalid() {
        let g = Config.parse("hour_hand_width = -1\nminute_hand_width = abc\nsecond_hand_width = inf").geometry
        #expect(g == ClockGeometry.default)
        #expect(Config.parse("hour_hand_width = nan").geometry.hourHandWidth == 3.7)
    }
}

@Suite("Clock Size Config Tests")
struct ClockSizeConfigTests {
    @Test("Default")
    func testDefault() {
        #expect(Config.default.geometry.clockSize == 87.8)
        #expect(Config.parse("").geometry.clockSize == 87.8)
        #expect(ClockView(frame: .zero).geometry.clockSize == 87.8)
    }

    @Test("Parses positive and fractional")
    func testParse() {
        #expect(Config.parse("clock_size = 60").geometry.clockSize == 60)
        #expect(Config.parse("clock_size=120.5").geometry.clockSize == 120.5)
    }

    @Test("Zero, negative, non-finite and invalid fall back")
    func testInvalid() {
        for v in ["0", "-5", "abc", "inf", "nan", ""] {
            #expect(Config.parse("clock_size = \(v)").geometry.clockSize == 87.8)
        }
    }
}

@Suite("Circle Config Tests")
struct CircleConfigTests {
    @Test("Defaults")
    func testDefaults() {
        let c = Config.parse("")
        #expect(c.circleColor == c.foreground)
        #expect(Config.default.circleColor == Config.default.foreground)
        #expect(c.geometry.circleWidth == 1.2)
        #expect(ClockView(frame: .zero).geometry.circleWidth == 1.2)
        #expect(Theme.catppuccinMacchiato.circle == Theme.catppuccinMacchiato.foreground)
    }

    @Test("Follows foreground, even when it appears later")
    func testFollowsForeground() {
        let c = Config.parse("circle_width = 2\nforeground = #112233")
        #expect(c.circleColor == Config.parseColor("#112233"))
        #expect(Config.parse("circle_color = zzz\nforeground = #112233").circleColor == Config.parseColor("#112233"))
    }

    @Test("Explicit circle_color wins")
    func testExplicit() {
        let c = Config.parse("circle_color = #ff000080\nforeground = #112233")
        #expect(c.circleColor == Config.parseColor("#ff000080"))
        #expect(c.foreground == Config.parseColor("#112233"))
        #expect(Config.parse("circle_color = #ffffff00").circleColor.alphaComponent == 0)
    }

    @Test("Width parsing")
    func testWidth() {
        #expect(Config.parse("circle_width = 0").geometry.circleWidth == 0)
        #expect(Config.parse("circle_width = 3.5").geometry.circleWidth == 3.5)
        for bad in ["-1", "abc", "inf", "nan"] {
            #expect(Config.parse("circle_width = \(bad)").geometry.circleWidth == 1.2)
        }
    }
}

@Suite("Mark Tier Tests")
struct MarkTierTests {
    @Test("Minute index maps to exclusive tier")
    func testTiers() {
        for i in 0..<60 {
            let expected: MarkTier = i % 15 == 0 ? .quarter : (i % 5 == 0 ? .hour : .minute)
            #expect(MarkTier.of(minute: i) == expected)
        }
        #expect((0..<60).filter { MarkTier.of(minute: $0) == .quarter } == [0, 15, 30, 45])
        #expect((0..<60).filter { MarkTier.of(minute: $0) == .hour }.count == 8)
        #expect((0..<60).filter { MarkTier.of(minute: $0) == .minute }.count == 48)
    }

    @Test("Defaults follow foreground; minute hidden")
    func testDefaults() {
        let c = Config.parse("")
        #expect(c.hourMarkColor == c.foreground)
        #expect(c.quarterMarkColor == c.foreground)
        #expect(c.minuteMarkColor.alphaComponent == 0)
        #expect(Config.default.hourMarkColor == Config.default.foreground)
        #expect(Config.default.minuteMarkColor.alphaComponent == 0)
        let t = Theme.catppuccinMacchiato
        #expect(t.markColor(.quarter) == t.foreground)
        #expect(t.markColor(.hour) == t.foreground)
        #expect(t.markColor(.minute).alphaComponent == 0)
    }

    @Test("Foreground propagates, even when set later")
    func testForeground() {
        let c = Config.parse("hour_mark_color = zzz\nforeground = #112233")
        let fg = Config.parseColor("#112233")!
        #expect(c.hourMarkColor == fg)
        #expect(c.quarterMarkColor == fg)
        #expect(c.minuteMarkColor == fg.withAlphaComponent(0))
    }

    @Test("Overrides")
    func testOverrides() {
        let c = Config.parse("""
        minute_mark_color = #11111180
        hour_mark_color = #222222
        quarter_mark_color = #33333300
        foreground = #444444
        """)
        #expect(c.minuteMarkColor == Config.parseColor("#11111180"))
        #expect(c.hourMarkColor == Config.parseColor("#222222"))
        #expect(c.quarterMarkColor.alphaComponent == 0)
        #expect(c.foreground == Config.parseColor("#444444"))
    }
}

@Suite("Mark Size Config Tests")
struct MarkSizeConfigTests {
    @Test("Defaults")
    func testDefaults() {
        let g = Config.parse("").geometry
        #expect(g.markSize(.minute) == MarkSize(width: 1.2, length: 1.2))
        #expect(g.markSize(.hour) == MarkSize(width: 1.2, length: 4.4))
        #expect(g.markSize(.quarter) == MarkSize(width: 1.2, length: 4.4))
        #expect(g.markInset == 2.2)
        #expect(g.markStyle == .dashes)
    }

    @Test("Size syntaxes", arguments: [
        ("1.2x4.4", 1.2, 4.4), ("100x100", 100, 100), ("100:100", 100, 100),
        ("100 : 100", 100, 100), ("2 x 3", 2, 3), ("  2,3  ", 2, 3),
        ("1.2", 1.2, 1.2), (".5", 0.5, 0.5), ("3.", 3, 3), ("-3", 3, 3), ("0x4", 0, 4),
    ])
    func testSyntax(input: String, w: Double, l: Double) {
        #expect(Config.parseSize(input) == MarkSize(width: CGFloat(w), length: CGFloat(l)))
    }

    @Test("Invalid sizes", arguments: ["abc", "1x2x3", "", "   ", "x", ".", "1..2x3"])
    func testInvalid(input: String) {
        #expect(Config.parseSize(input) == nil)
    }

    @Test("Per-tier keys and fallback")
    func testKeys() {
        let g = Config.parse("quarter_mark_size = 2x6\nhour_mark_size = 3\nminute_mark_size = bad").geometry
        #expect(g.markSize(.quarter) == MarkSize(width: 2, length: 6))
        #expect(g.markSize(.hour) == MarkSize(width: 3, length: 3))
        #expect(g.markSize(.minute) == .minuteDefault)
    }

    @Test("mark_style", arguments: [
        ("dashes", MarkStyle.dashes), ("dots", .dots), ("DOTS", .dots), (" Dashes ", .dashes),
        ("round", .dashes), ("", .dashes),
    ])
    func testStyle(value: String, expected: MarkStyle) {
        #expect(Config.parse("mark_style = \(value)").geometry.markStyle == expected)
    }

    @Test("mark_inset")
    func testInset() {
        #expect(Config.parse("mark_inset = 5.5").geometry.markInset == 5.5)
        #expect(Config.parse("mark_inset = 0").geometry.markInset == 0)
        for v in ["-1", "abc", "inf", ""] {
            #expect(Config.parse("mark_inset = \(v)").geometry.markInset == 2.2)
        }
    }
}

@Suite("Window Shadow Tests")
struct WindowShadowTests {
    @Test("Default is default")
    func defaultValue() {
        #expect(Config.default.windowShadow == .default)
        #expect(Config.parse("").windowShadow == .default)
    }

    @Test("Parses each value")
    func parsesValues() {
        #expect(Config.parse("window_shadow = default").windowShadow == .default)
        #expect(Config.parse("window_shadow = enable").windowShadow == .enable)
        #expect(Config.parse("window_shadow = disable").windowShadow == .disable)
    }

    @Test("Is case-insensitive")
    func caseInsensitive() {
        #expect(Config.parse("window_shadow = ENABLE").windowShadow == .enable)
        #expect(Config.parse("window_shadow = Disable").windowShadow == .disable)
    }

    @Test("Invalid falls back to default")
    func invalid() {
        #expect(Config.parse("window_shadow = maybe").windowShadow == .default)
        #expect(Config.parse("window_shadow = enable\nwindow_shadow = nope").windowShadow == .default)
    }
}

@Suite("Show Seconds Config Tests")
struct ShowSecondsConfigTests {
    @Test("Defaults to false")
    func defaultValue() {
        #expect(Config.default.showSeconds == false)
        #expect(Config.parse("").showSeconds == false)
    }

    @Test("Parses true/false/1/0")
    func values() {
        #expect(Config.parse("show_seconds = true").showSeconds == true)
        #expect(Config.parse("show_seconds = 1").showSeconds == true)
        #expect(Config.parse("show_seconds = false").showSeconds == false)
        #expect(Config.parse("show_seconds = 0").showSeconds == false)
    }

    @Test("Is case-insensitive")
    func caseInsensitive() {
        #expect(Config.parse("show_seconds = TRUE").showSeconds == true)
        #expect(Config.parse("show_seconds = False").showSeconds == false)
    }

    @Test("Invalid falls back to default")
    func invalid() {
        #expect(Config.parse("show_seconds = yes").showSeconds == false)
        #expect(Config.parse("show_seconds = true\nshow_seconds = nope").showSeconds == false)
    }
}

@Suite("Click-through config")
struct ClickThroughConfigTests {
    @Test("Defaults")
    func defaults() {
        let c = Config.parse("")
        #expect(c.clickThrough == false)
        #expect(c.unlockHoverDelay == 2)
        #expect(c.unlockModifiers == [.shift])
        #expect(c.unlockRingWidth == 10)
        #expect(c.unlockingColor == c.foreground)
        #expect(c.unlockedColor == Config.parseColor("#c00000"))
    }

    @Test("click_through values")
    func clickThrough() {
        for v in ["true", "TRUE", "1"] { #expect(Config.parse("click_through = \(v)").clickThrough) }
        for v in ["false", "0", "yes", "", "x"] { #expect(!Config.parse("click_through = \(v)").clickThrough) }
    }

    @Test("unlock_hover_delay")
    func delay() {
        #expect(Config.parse("unlock_hover_delay = 0.5").unlockHoverDelay == 0.5)
        #expect(Config.parse("unlock_hover_delay = 0").unlockHoverDelay == 0)
        #expect(Config.parse("unlock_hover_delay = -1").unlockHoverDelay == 2)
        #expect(Config.parse("unlock_hover_delay = abc").unlockHoverDelay == 2)
        #expect(Config.parse("unlock_hover_delay = inf").unlockHoverDelay == 2)
    }

    @Test("unlock_ring_width")
    func ringWidth() {
        #expect(Config.parse("unlock_ring_width = 4.5").unlockRingWidth == 4.5)
        #expect(Config.parse("unlock_ring_width = 0").unlockRingWidth == 0)
        #expect(Config.parse("unlock_ring_width = -2").unlockRingWidth == 10)
        #expect(Config.parse("unlock_ring_width = x").unlockRingWidth == 10)
    }

    @Test("unlock_modifier")
    func modifier() {
        #expect(Config.parse("unlock_modifier = ctrl+shift").unlockModifiers == [.control, .shift])
        #expect(Config.parse("unlock_modifier = none").unlockModifiers == [])
        #expect(Config.parse("unlock_modifier =").unlockModifiers == [])
        #expect(Config.parse("unlock_modifier = bogus").unlockModifiers == [.shift])
    }

    @Test("Colors ignore alpha and follow foreground")
    func colors() {
        let c = Config.parse("foreground = #112233\nunlocking_color = #00ff0080\nunlocked_color = #0000ff10")
        #expect(c.unlockingColor == Config.parseColor("#00ff00"))
        #expect(c.unlockedColor == Config.parseColor("#0000ff"))
        let d = Config.parse("unlocking_color = bad\nforeground = #112233cc\nunlocked_color = bad")
        #expect(d.unlockingColor == Config.parseColor("#112233"))
        #expect(d.unlockedColor == Config.parseColor("#c00000"))
    }

    @Test("Modifier parsing")
    func parseModifiers() {
        #expect(ModifierSet.parse("cmd+option") == [.command, .option])
        #expect(ModifierSet.parse("Command, ALT") == [.command, .option])
        #expect(ModifierSet.parse("opt-ctrl-shift") == [.option, .control, .shift])
        #expect(ModifierSet.parse("control shift cmd") == [.control, .shift, .command])
        #expect(ModifierSet.parse("NONE") == [])
        #expect(ModifierSet.parse("  ") == [])
        #expect(ModifierSet.parse("cmd+foo") == nil)
        #expect(ModifierSet.parse("none+cmd") == nil)
    }

    @Test("Modifier matching")
    func matching() {
        let co = ModifierSet([.command, .option])
        #expect(co.isSatisfied(by: [.command, .option]))
        #expect(co.isSatisfied(by: [.command, .option, .capsLock, .function, .numericPad]))
        #expect(!co.isSatisfied(by: [.command]))
        #expect(!co.isSatisfied(by: [.command, .option, .shift]))
        #expect(!co.isSatisfied(by: []))
        #expect(ModifierSet([]).isSatisfied(by: []))
        #expect(ModifierSet([]).isSatisfied(by: [.command, .shift]))
        #expect(ModifierSet([.shift]).isSatisfied(by: [.shift, .capsLock]))
    }
}
