import Cocoa
import yClockLib

do {
    let options = try parseCommandLine(arguments: CommandLine.arguments)
    
    let app = NSApplication.shared
    let delegate = AppDelegate(options: options)
    app.delegate = delegate
    app.run()
} catch CommandLineError.helpRequested {
    printHelp()
    exit(0)
} catch CommandLineError.unknownOption(let option) {
    print("Unknown option: \(option)")
    printHelp()
    exit(1)
} catch {
    print("Error: \(error)")
    exit(1)
}

