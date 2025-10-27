import Foundation

public enum CommandLineError: Error, Equatable {
    case unknownOption(String)
    case helpRequested
}

public func parseCommandLine(arguments: [String]) throws -> CommandLineOptions {
    var isDigital: Bool?
    var showSeconds: Bool?
    var fontName: String?
    var showInDock: Bool?
    var i = 1 // Start from 1 to skip program name
    
    while i < arguments.count {
        let arg = arguments[i]
        
        switch arg {
        case "--digital":
            isDigital = true
            i += 1
        case "--analog", "--analogue":
            isDigital = false
            i += 1
        case "--seconds":
            showSeconds = true
            i += 1
        case "--show-in-dock":
            showInDock = true
            i += 1
        case "--font-name":
            // Check if there's a next argument
            guard i + 1 < arguments.count else {
                throw CommandLineError.unknownOption("--font-name requires a value")
            }
            fontName = arguments[i + 1]
            i += 2
        case "--help", "-h":
            throw CommandLineError.helpRequested
        default:
            throw CommandLineError.unknownOption(arg)
        }
    }
    
    return CommandLineOptions(isDigital: isDigital, showSeconds: showSeconds, fontName: fontName, showInDock: showInDock)
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
      --show-in-dock    Show app in Dock and Cmd+Tab switcher
      --font-name NAME  Specify font name for digital clock
      --help            Show this help message
    
    Examples:
      yclock --digital --seconds
      yclock --analog
      yclock --digital --font-name Menlo
      yclock --font-name "Courier New" --seconds
      yclock --show-in-dock
    """)
}
