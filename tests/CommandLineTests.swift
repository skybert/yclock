import Testing
@testable import yClockLib

@Suite("Command Line Parsing Tests")
struct CommandLineTests {
    
    @Test("Parse no arguments returns default options")
    func testNoArguments() throws {
        let options = try parseCommandLine(arguments: ["yclock"])
        
        #expect(options.isDigital == nil)
        #expect(options.showSeconds == nil)
    }
    
    @Test("Parse --new-instance")
    func testNewInstanceFlag() throws {
        #expect(try parseCommandLine(arguments: ["yclock"]).newInstance == false)
        #expect(try parseCommandLine(arguments: ["yclock", "--new-instance", "--digital"]).newInstance == true)
    }

    @Test("Select other instance by bundle ID, excluding own PID")
    func testSelectByBundleID() {
        let me = RunningInstance(pid: 1, bundleID: "net.skybert.yclock", executableName: "yclock")
        let other = RunningInstance(pid: 2, bundleID: "net.skybert.yclock", executableName: "yclock")
        let unrelated = RunningInstance(pid: 3, bundleID: "com.apple.finder", executableName: "Finder")
        #expect(selectOtherInstance(from: [me, unrelated, other], ownPID: 1, bundleID: "net.skybert.yclock") == other)
        #expect(selectOtherInstance(from: [me, unrelated], ownPID: 1, bundleID: "net.skybert.yclock") == nil)
    }

    @Test("Select other instance by executable name without bundle ID")
    func testSelectByExecutableName() {
        let other = RunningInstance(pid: 5, bundleID: nil, executableName: "yclock")
        let unrelated = RunningInstance(pid: 6, bundleID: nil, executableName: "other")
        #expect(selectOtherInstance(from: [unrelated, other], ownPID: 1, bundleID: nil) == other)
        #expect(selectOtherInstance(from: [unrelated], ownPID: 1, bundleID: nil) == nil)
    }

    @Test("Parse --digital sets isDigital to true")
    func testDigitalFlag() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--digital"])
        
        #expect(options.isDigital == true)
        #expect(options.showSeconds == nil)
    }
    
    @Test("Parse --analog sets isDigital to false")
    func testAnalogFlag() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--analog"])
        
        #expect(options.isDigital == false)
        #expect(options.showSeconds == nil)
    }
    
    @Test("Parse --analogue sets isDigital to false")
    func testAnalogueFlag() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--analogue"])
        
        #expect(options.isDigital == false)
        #expect(options.showSeconds == nil)
    }
    
    @Test("Parse --seconds sets showSeconds to true")
    func testSecondsFlag() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--seconds"])
        
        #expect(options.isDigital == nil)
        #expect(options.showSeconds == true)
    }
    
    @Test("Parse multiple flags")
    func testMultipleFlags() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--digital", "--seconds"])
        
        #expect(options.isDigital == true)
        #expect(options.showSeconds == true)
    }
    
    @Test("Parse --analog --seconds")
    func testAnalogWithSeconds() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--analog", "--seconds"])
        
        #expect(options.isDigital == false)
        #expect(options.showSeconds == true)
    }
    
    @Test("Parse --help throws helpRequested error")
    func testHelpFlag() {
        #expect(throws: CommandLineError.helpRequested) {
            _ = try parseCommandLine(arguments: ["yclock", "--help"])
        }
    }
    
    @Test("Parse -h throws helpRequested error")
    func testShortHelpFlag() {
        #expect(throws: CommandLineError.helpRequested) {
            _ = try parseCommandLine(arguments: ["yclock", "-h"])
        }
    }
    
    @Test("Parse unknown option throws unknownOption error")
    func testUnknownOption() {
        do {
            _ = try parseCommandLine(arguments: ["yclock", "--invalid"])
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as CommandLineError {
            #expect(error == CommandLineError.unknownOption("--invalid"))
        } catch {
            #expect(Bool(false), "Wrong error type thrown")
        }
    }
    
    @Test("Last option wins for conflicting flags")
    func testConflictingFlags() throws {
        let options1 = try parseCommandLine(arguments: ["yclock", "--digital", "--analog"])
        #expect(options1.isDigital == false)
        
        let options2 = try parseCommandLine(arguments: ["yclock", "--analog", "--digital"])
        #expect(options2.isDigital == true)
    }
    
    @Test("Parse --font-name sets fontName")
    func testFontNameFlag() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--font-name", "Menlo"])
        
        #expect(options.fontName == "Menlo")
        #expect(options.isDigital == nil)
        #expect(options.showSeconds == nil)
    }
    
    @Test("Parse --font-name with spaces")
    func testFontNameWithSpaces() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--font-name", "Courier New"])
        
        #expect(options.fontName == "Courier New")
    }
    
    @Test("Parse --font-name with multiple options")
    func testFontNameWithOtherFlags() throws {
        let options = try parseCommandLine(arguments: ["yclock", "--digital", "--font-name", "Monaco", "--seconds"])
        
        #expect(options.isDigital == true)
        #expect(options.showSeconds == true)
        #expect(options.fontName == "Monaco")
    }
    
    @Test("Parse --font-name without value throws error")
    func testFontNameWithoutValue() {
        do {
            _ = try parseCommandLine(arguments: ["yclock", "--font-name"])
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as CommandLineError {
            #expect(error == CommandLineError.unknownOption("--font-name requires a value"))
        } catch {
            #expect(Bool(false), "Wrong error type thrown")
        }
    }
}
