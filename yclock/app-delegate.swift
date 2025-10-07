import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: ClockView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        let windowRect = NSRect(x: 100, y: 100, width: 164, height: 164)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.borderless],
                         backing: .buffered,
                         defer: false)
        window.title = "yclock"
        window.center()
        window.level = .floating
        window.isOpaque = false
        window.alphaValue = 0.85
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = true
        
        clockView = ClockView(frame: window.contentView!.bounds)
        clockView.autoresizingMask = [.width, .height]
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
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

