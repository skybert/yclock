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
}
