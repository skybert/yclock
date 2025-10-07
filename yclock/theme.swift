import Cocoa

struct Theme {
    let background: NSColor
    let foreground: NSColor
    let secondHand: NSColor
    
    static let catppuccinMacchiato = Theme(
        background: NSColor(red: 36/255, green: 39/255, blue: 58/255, alpha: 0.7),
        foreground: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        secondHand: NSColor(red: 237/255, green: 135/255, blue: 150/255, alpha: 1.0)
    )
    
    static func load() -> Theme {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        // Check ~/.yclock.conf first, then ~/.config, then XDG_CONFIG_HOME
        var configPath: URL?
        
        let homePath = homeDir.appendingPathComponent(".yclock.conf")
        if FileManager.default.fileExists(atPath: homePath.path) {
            configPath = homePath
        }
        
        if configPath == nil {
            let defaultXdgPath = homeDir.appendingPathComponent(".config/yclock/yclock.conf")
            if FileManager.default.fileExists(atPath: defaultXdgPath.path) {
                configPath = defaultXdgPath
            }
        }
        
        if configPath == nil, let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            let xdgPath = URL(fileURLWithPath: xdgConfigHome).appendingPathComponent("yclock/yclock.conf")
            if FileManager.default.fileExists(atPath: xdgPath.path) {
                configPath = xdgPath
            }
        }
        
        guard let configPath = configPath,
              let contents = try? String(contentsOf: configPath, encoding: .utf8) else {
            return .catppuccinMacchiato
        }
        
        var background: NSColor?
        var foreground: NSColor?
        var secondHand: NSColor?
        
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "background":
                background = parseColor(value)
            case "foreground":
                foreground = parseColor(value)
            case "second_hand":
                secondHand = parseColor(value)
            default:
                break
            }
        }
        
        return Theme(
            background: background ?? catppuccinMacchiato.background,
            foreground: foreground ?? catppuccinMacchiato.foreground,
            secondHand: secondHand ?? catppuccinMacchiato.secondHand
        )
    }
    
    static func parseColor(_ value: String) -> NSColor? {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        
        guard hex.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
