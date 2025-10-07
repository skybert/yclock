import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: ClockView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        let windowRect = NSRect(x: 100, y: 100, width: 164, height: 164)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered,
                         defer: false)
        window.title = "yclock"
        window.center()
        window.level = .floating
        
        clockView = ClockView(frame: window.contentView!.bounds)
        clockView.autoresizingMask = [.width, .height]
        window.contentView = clockView
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        setupMenu()
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        let quitMenuItem = NSMenuItem(title: "Quit yclock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)
        
        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

