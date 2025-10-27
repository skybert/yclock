import Cocoa

public struct CommandLineOptions {
    public var isDigital: Bool?
    public var showSeconds: Bool?
    public var fontName: String?
    public var showInDock: Bool?

    public init(isDigital: Bool? = nil, showSeconds: Bool? = nil, fontName: String? = nil, showInDock: Bool? = nil) {
        self.isDigital = isDigital
        self.showSeconds = showSeconds
        self.fontName = fontName
        self.showInDock = showInDock
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: ClockView!
    var options: CommandLineOptions
    var savedFrame: NSRect?
    var isMaximized = false

    public init(options: CommandLineOptions = CommandLineOptions()) {
        self.options = options
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let config = Config.load()
        let windowRect = NSRect(x: 100, y: 100, width: config.width, height: config.height)

        // Use command line option if provided, otherwise fall back to config
        let showInDock = options.showInDock ?? config.showInDock
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.titled, .fullSizeContentView],
                         backing: .buffered,
                         defer: false)
        window.title = "yclock"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Restore window position or center if out of bounds
        if let savedPosition = Config.loadWindowPosition() {
            let newOrigin = NSPoint(x: savedPosition.x, y: savedPosition.y)
            let proposedFrame = NSRect(origin: newOrigin, size: window.frame.size)

            // Check if window is visible on any screen
            let isVisible = NSScreen.screens.contains { screen in
                screen.visibleFrame.intersects(proposedFrame)
            }

            if isVisible {
                window.setFrameOrigin(newOrigin)
            } else {
                window.center()
            }
        } else {
            window.center()
        }

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
        clockView.fontName = options.fontName ?? config.fontName

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
        let maximizeMenuItem = NSMenuItem(title: "Maximize Clock", action: #selector(toggleMaximized), keyEquivalent: "f")
        appMenu.addItem(maximizeMenuItem)
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

    @objc func toggleMaximized() {
        if isMaximized {
            // Restore original size
            if let saved = savedFrame {
                window.setFrame(saved, display: true, animate: true)
                isMaximized = false
            }
        } else {
            // Save current frame and maximize
            savedFrame = window.frame

            guard let screen = window.screen else { return }

            // Use the entire visible frame (excludes menu bar and dock)
            let screenFrame = screen.visibleFrame

            window.setFrame(screenFrame, display: true, animate: true)
            isMaximized = true
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Save window position before closing
        let origin = window.frame.origin
        Config.saveWindowPosition(x: origin.x, y: origin.y)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
