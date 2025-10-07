import Cocoa

public struct CommandLineOptions {
    public var isDigital: Bool?
    public var showSeconds: Bool?
    
    public init(isDigital: Bool? = nil, showSeconds: Bool? = nil) {
        self.isDigital = isDigital
        self.showSeconds = showSeconds
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: ClockView!
    var options: CommandLineOptions
    
    public init(options: CommandLineOptions = CommandLineOptions()) {
        self.options = options
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let config = Config.load()
        let windowRect = NSRect(x: 100, y: 100, width: config.width, height: config.height)

        NSApp.setActivationPolicy(.accessory)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.titled, .fullSizeContentView],
                         backing: .buffered,
                         defer: false)
        window.title = "yclock"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.center()
        window.level = .floating
        window.isOpaque = false
        window.alphaValue = 0.85
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = true

        clockView = ClockView(frame: window.contentView!.bounds)
        clockView.autoresizingMask = [.width, .height]
        
        // Use command line options if provided, otherwise fall back to config
        clockView.isDigital = options.isDigital ?? config.isDigital
        clockView.showSeconds = options.showSeconds ?? false
        
        clockView.theme = Theme(
            background: config.background,
            foreground: config.foreground,
            secondHand: config.secondHand
        )
        window.contentView = clockView
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        setupMenu()

        // Listen for wake from sleep notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeFromSleep),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc func handleWakeFromSleep() {
        clockView.needsDisplay = true
    }

    func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let toggleMenuItem = NSMenuItem(title: "Toggle Digital/Analog", action: #selector(toggleClockMode), keyEquivalent: "d")
        appMenu.addItem(toggleMenuItem)
        let toggleSecondsMenuItem = NSMenuItem(title: "Toggle Seconds", action: #selector(toggleSeconds), keyEquivalent: "s")
        appMenu.addItem(toggleSecondsMenuItem)
        appMenu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "Quit yclock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)

        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    @objc func toggleClockMode() {
        clockView.toggleClockMode()
    }

    @objc func toggleSeconds() {
        clockView.toggleSeconds()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

