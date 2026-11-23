import Cocoa

public struct Config {
    let background: NSColor
    let foreground: NSColor
    let secondHand: NSColor
    let isDigital: Bool
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let fontName: String?
    let windowX: CGFloat?
    let windowY: CGFloat?
    let showInDock: Bool
    let opacity: CGFloat
    let geometry: ClockGeometry

    public static let `default` = Config(
        background: NSColor(red: 36/255, green: 39/255, blue: 58/255, alpha: 0.95),
        foreground: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        secondHand: NSColor(red: 237/255, green: 135/255, blue: 150/255, alpha: 1.0),
        isDigital: false,
        width: 100,
        height: 100,
        scale: 1.64,
        fontName: nil,
        windowX: nil,
        windowY: nil,
        showInDock: false,
        opacity: 0.85,
        geometry: .default
    )

    public static func load() -> Config {
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

            return .default
        }

        return parse(contents)
    }

    public static func parse(_ contents: String) -> Config {
        var background: NSColor?
        var foreground: NSColor?
        var secondHand: NSColor?
        var isDigital: Bool?
        var width: CGFloat?
        var height: CGFloat?
        var scale: CGFloat?
        var fontName: String?
        var windowX: CGFloat?
        var windowY: CGFloat?
        var showInDock: Bool?
        var opacity: CGFloat?
        var geometry = ClockGeometry.default

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
            case "mode":
                isDigital = (value.lowercased() == "digital")
            case "width":
                if let w = Double(value), w.isFinite, w > 0 {
                    width = CGFloat(w)
                }
            case "height":
                if let h = Double(value), h.isFinite, h > 0 {
                    height = CGFloat(h)
                }
            case "scale":
                if let sc = Double(value), sc.isFinite, sc > 0 {
                    scale = CGFloat(sc)
                }
            case "font":
                fontName = value
            case "window_x":
                if let x = Double(value) {
                    windowX = CGFloat(x)
                }
            case "window_y":
                if let y = Double(value) {
                    windowY = CGFloat(y)
                }
            case "show_in_dock":
                showInDock = (value.lowercased() == "true" || value == "1")
            case "opacity":
                if let o = Double(value), o.isFinite {
                    opacity = CGFloat(min(max(o, 0), 1))
                }
            case "hour_hand_width":
                if let v = parseNonNegative(value) { geometry.hourHandWidth = v }
            case "minute_hand_width":
                if let v = parseNonNegative(value) { geometry.minuteHandWidth = v }
            case "second_hand_width":
                if let v = parseNonNegative(value) { geometry.secondHandWidth = v }
            case "corner_radius":
                if let v = parseNonNegative(value) { geometry.cornerRadius = v }
            default:
                break
            }
        }

        return Config(
            background: background ?? Config.default.background,
            foreground: foreground ?? Config.default.foreground,
            secondHand: secondHand ?? Config.default.secondHand,
            isDigital: isDigital ?? Config.default.isDigital,
            width: width ?? Config.default.width,
            height: height ?? Config.default.height,
            scale: scale ?? Config.default.scale,
            fontName: fontName ?? Config.default.fontName,
            windowX: windowX,
            windowY: windowY,
            showInDock: showInDock ?? Config.default.showInDock,
            opacity: opacity ?? Config.default.opacity,
            geometry: geometry
        )
    }

    static func parseNonNegative(_ value: String) -> CGFloat? {
        guard let v = Double(value), v.isFinite, v >= 0 else { return nil }
        return CGFloat(v)
    }

    public static func parseColor(_ value: String) -> NSColor? {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value

        guard hex.count == 6 || hex.count == 8,
              hex.allSatisfy({ $0.isASCII && $0.isHexDigit }),
              let rgba = UInt64(hex, radix: 16) else { return nil }

        let hasAlpha = hex.count == 8
        let v = hasAlpha ? rgba : (rgba << 8) | 0xFF

        return NSColor(
            red: CGFloat((v >> 24) & 0xFF) / 255.0,
            green: CGFloat((v >> 16) & 0xFF) / 255.0,
            blue: CGFloat((v >> 8) & 0xFF) / 255.0,
            alpha: CGFloat(v & 0xFF) / 255.0
        )
    }

    private static func getStateDirectory() -> URL? {
        // Prefer XDG_STATE_HOME if set
        if let xdgStateHome = ProcessInfo.processInfo.environment["XDG_STATE_HOME"] {
            let stateDir = URL(fileURLWithPath: xdgStateHome).appendingPathComponent("yclock")
            try? FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
            return stateDir
        }

        // Fall back to macOS Application Support directory (which is for state data on macOS)
        if let stateDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appStateDir = stateDir.appendingPathComponent("yclock")
            try? FileManager.default.createDirectory(at: appStateDir, withIntermediateDirectories: true)
            return appStateDir
        }

        return nil
    }

    public static func saveWindowPosition(x: CGFloat, y: CGFloat) {
        guard let stateDir = getStateDirectory() else { return }
        let statePath = stateDir.appendingPathComponent("window-position")

        let content = "window_x = \(x)\nwindow_y = \(y)\n"
        try? content.write(to: statePath, atomically: true, encoding: .utf8)
    }

    public static func loadWindowPosition() -> (x: CGFloat, y: CGFloat)? {
        guard let stateDir = getStateDirectory() else { return nil }
        let statePath = stateDir.appendingPathComponent("window-position")

        guard let contents = try? String(contentsOf: statePath, encoding: .utf8) else {
            return nil
        }

        var x: CGFloat?
        var y: CGFloat?

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            let parts = trimmed.components(separatedBy: "=")
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch key {
            case "window_x":
                if let xVal = Double(value) {
                    x = CGFloat(xVal)
                }
            case "window_y":
                if let yVal = Double(value) {
                    y = CGFloat(yVal)
                }
            default:
                break
            }
        }

        if let x = x, let y = y {
            return (x, y)
        }

        return nil
    }
}

/// Analogue clock geometry in base units (design size is width x height).
public enum Metrics {
    static let clockDiameter: CGFloat = 87.8
    static let circleLineWidth: CGFloat = 1.2
    static let tickLineWidth: CGFloat = 1.2
    static let hourHandWidth: CGFloat = 3.7
    static let minuteHandWidth: CGFloat = 2.4
    static let secondHandWidth: CGFloat = 1.2
    static let centerDotRadius: CGFloat = 3.0
    static let cornerRadius: CGFloat = 7.3
}

/// Config-driven geometry in base units; defaults equal `Metrics`.
public struct ClockGeometry: Equatable {
    public var hourHandWidth: CGFloat = Metrics.hourHandWidth
    public var minuteHandWidth: CGFloat = Metrics.minuteHandWidth
    public var secondHandWidth: CGFloat = Metrics.secondHandWidth
    public var cornerRadius: CGFloat = Metrics.cornerRadius

    public static let `default` = ClockGeometry()
}

public struct Theme {
    let background: NSColor
    let foreground: NSColor
    let secondHand: NSColor

    public init(background: NSColor, foreground: NSColor, secondHand: NSColor) {
        self.background = background
        self.foreground = foreground
        self.secondHand = secondHand
    }

    public static let catppuccinMacchiato = Theme(
        background: NSColor(red: 36/255, green: 39/255, blue: 58/255, alpha: 0.95),
        foreground: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        secondHand: NSColor(red: 237/255, green: 135/255, blue: 150/255, alpha: 1.0)
    )
}
