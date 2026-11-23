import Cocoa
import yClockLib

func activateOtherInstance() -> Bool {
    let ownPID = ProcessInfo.processInfo.processIdentifier
    let bundleID = Bundle.main.bundleIdentifier
    var apps: [NSRunningApplication] = []
    if let bundleID = bundleID {
        apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    }
    if apps.isEmpty {
        apps = NSWorkspace.shared.runningApplications
    }
    let candidates = apps.map {
        RunningInstance(pid: $0.processIdentifier, bundleID: $0.bundleIdentifier, executableName: $0.executableURL?.lastPathComponent)
    }
    guard let other = selectOtherInstance(from: candidates, ownPID: ownPID, bundleID: bundleID),
          let app = apps.first(where: { $0.processIdentifier == other.pid }) else {
        return false
    }
    // LaunchServices activation counts as user-initiated; NSRunningApplication.activate() may be refused on macOS 14+.
    if let url = app.bundleURL {
        let done = DispatchSemaphore(value: 0)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in done.signal() }
        _ = done.wait(timeout: .now() + 3)
    } else {
        app.activate(options: [.activateIgnoringOtherApps])
    }
    return true
}

do {
    let options = try parseCommandLine(arguments: CommandLine.arguments)

    if !options.newInstance && activateOtherInstance() {
        exit(0)
    }

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

