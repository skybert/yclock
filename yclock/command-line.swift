import Foundation

public enum CommandLineError: Error, Equatable {
    case unknownOption(String)
    case helpRequested
}

public func parseCommandLine(arguments: [String]) throws -> CommandLineOptions {
    var isDigital: Bool?
    var showSeconds: Bool?
    
    for arg in arguments.dropFirst() {
        switch arg {
        case "--digital":
            isDigital = true
        case "--analog", "--analogue":
            isDigital = false
        case "--seconds":
            showSeconds = true
        case "--help", "-h":
            throw CommandLineError.helpRequested
        default:
            throw CommandLineError.unknownOption(arg)
        }
    }
    
    return CommandLineOptions(isDigital: isDigital, showSeconds: showSeconds)
}

public func printHelp() {
    print("""
    yclock - A simple clock for macOS
    
    Usage: yclock [OPTIONS]
    
    Options:
      --digital         Start in digital mode
      --analog          Start in analog mode (default)
      --analogue        Same as --analog
      --seconds         Show seconds hand/display
      --help            Show this help message
    
    Examples:
      yclock --digital --seconds
      yclock --analog
    """)
}
