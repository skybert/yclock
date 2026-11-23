import Cocoa
import yClockLib

func findOtherInstance() -> NSRunningApplication? {
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
    guard let other = selectOtherInstance(from: candidates, ownPID: ownPID, bundleID: bundleID) else {
        return nil
    }
    return apps.first { $0.processIdentifier == other.pid }
}

func activateOtherInstance() -> Bool {
    guard let app = findOtherInstance() else {
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

func quitOtherInstance() -> Never {
    guard let app = findOtherInstance() else {
        FileHandle.standardError.write(Data("yclock: no running instance\n".utf8))
        exit(0)
    }
    app.terminate()
    let deadline = Date().addingTimeInterval(3)
    while !app.isTerminated && Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    if app.isTerminated {
        exit(0)
    }
    FileHandle.standardError.write(Data("yclock: instance did not quit in time\n".utf8))
    exit(1)
}

do {
    let options = try parseCommandLine(arguments: CommandLine.arguments)

    if options.quit {
        quitOtherInstance()
    }

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

