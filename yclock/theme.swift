import Cocoa

public enum WindowShadow: String {
    case `default`, enable, disable
}

public struct Config {
    let background: NSColor
    let foreground: NSColor
    let secondHand: NSColor
    let circleColor: NSColor
    let minuteMarkColor: NSColor
    let hourMarkColor: NSColor
    let quarterMarkColor: NSColor
    let isDigital: Bool
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let fontName: String?
    let windowX: CGFloat?
    let windowY: CGFloat?
    let showInDock: Bool
    let showSeconds: Bool
    let opacity: CGFloat
    let windowShadow: WindowShadow
    let geometry: ClockGeometry

    public static let `default` = Config(
        background: NSColor(red: 36/255, green: 39/255, blue: 58/255, alpha: 0.95),
        foreground: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        secondHand: NSColor(red: 237/255, green: 135/255, blue: 150/255, alpha: 1.0),
        circleColor: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        minuteMarkColor: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 0),
        hourMarkColor: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        quarterMarkColor: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        isDigital: false,
        width: 100,
        height: 100,
        scale: 1.64,
        fontName: nil,
        windowX: nil,
        windowY: nil,
        showInDock: false,
        showSeconds: false,
        opacity: 0.85,
        windowShadow: .default,
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
        var circleColor: NSColor?
        var minuteMarkColor: NSColor?
        var hourMarkColor: NSColor?
        var quarterMarkColor: NSColor?
        var isDigital: Bool?
        var width: CGFloat?
        var height: CGFloat?
        var scale: CGFloat?
        var fontName: String?
        var windowX: CGFloat?
        var windowY: CGFloat?
        var showInDock: Bool?
        var showSeconds: Bool?
        var opacity: CGFloat?
        var windowShadow = WindowShadow.default
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
            case "circle_color":
                circleColor = parseColor(value)
            case "minute_mark_color":
                minuteMarkColor = parseColor(value)
            case "hour_mark_color":
                hourMarkColor = parseColor(value)
            case "quarter_mark_color":
                quarterMarkColor = parseColor(value)
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
            case "show_seconds":
                switch value.lowercased() {
                case "true", "1": showSeconds = true
                case "false", "0": showSeconds = false
                default: showSeconds = nil
                }
            case "opacity":
                if let o = Double(value), o.isFinite {
                    opacity = CGFloat(min(max(o, 0), 1))
                }
            case "window_shadow":
                windowShadow = WindowShadow(rawValue: value.lowercased()) ?? .default
            case "hour_hand_width":
                if let v = parseNonNegative(value) { geometry.hourHandWidth = v }
            case "minute_hand_width":
                if let v = parseNonNegative(value) { geometry.minuteHandWidth = v }
            case "second_hand_width":
                if let v = parseNonNegative(value) { geometry.secondHandWidth = v }
            case "corner_radius":
                if let v = parseNonNegative(value) { geometry.cornerRadius = v }
            case "circle_width":
                if let v = parseNonNegative(value) { geometry.circleWidth = v }
            case "clock_size":
                if let v = parseNonNegative(value), v > 0 { geometry.clockSize = v }
            case "minute_mark_size":
                if let v = parseSize(value) { geometry.minuteMarkSize = v }
            case "hour_mark_size":
                if let v = parseSize(value) { geometry.hourMarkSize = v }
            case "quarter_mark_size":
                if let v = parseSize(value) { geometry.quarterMarkSize = v }
            case "mark_style":
                if let v = MarkStyle(rawValue: value.lowercased()) { geometry.markStyle = v }
            case "mark_inset":
                if let v = parseNonNegative(value) { geometry.markInset = v }
            default:
                break
            }
        }

        // Optional colours default to the foreground, resolved after the whole file is parsed
        let resolvedForeground = foreground ?? Config.default.foreground

        return Config(
            background: background ?? Config.default.background,
            foreground: resolvedForeground,
            secondHand: secondHand ?? Config.default.secondHand,
            circleColor: circleColor ?? resolvedForeground,
            minuteMarkColor: minuteMarkColor ?? resolvedForeground.withAlphaComponent(0),
            hourMarkColor: hourMarkColor ?? resolvedForeground,
            quarterMarkColor: quarterMarkColor ?? resolvedForeground,
            isDigital: isDigital ?? Config.default.isDigital,
            width: width ?? Config.default.width,
            height: height ?? Config.default.height,
            scale: scale ?? Config.default.scale,
            fontName: fontName ?? Config.default.fontName,
            windowX: windowX,
            windowY: windowY,
            showInDock: showInDock ?? Config.default.showInDock,
            showSeconds: showSeconds ?? Config.default.showSeconds,
            opacity: opacity ?? Config.default.opacity,
            windowShadow: windowShadow,
            geometry: geometry
        )
    }

    static func parseNonNegative(_ value: String) -> CGFloat? {
        guard let v = Double(value), v.isFinite, v >= 0 else { return nil }
        return CGFloat(v)
    }

    /// Parses "W", or "W<sep>L" with any run of non-numeric characters as separator.
    public static func parseSize(_ value: String) -> MarkSize? {
        let tokens = value.split(whereSeparator: { !($0.isASCII && ($0.isNumber || $0 == ".")) })
        guard tokens.count == 1 || tokens.count == 2 else { return nil }
        var nums: [CGFloat] = []
        for t in tokens {
            guard let v = Double(t), v.isFinite, v >= 0 else { return nil }
            nums.append(CGFloat(v))
        }
        return MarkSize(width: nums[0], length: nums.last!)
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
    static let markWidth: CGFloat = 1.2
    static let markLength: CGFloat = 4.4
    static let markInset: CGFloat = 2.2
    static let hourHandWidth: CGFloat = 3.7
    static let minuteHandWidth: CGFloat = 2.4
    static let secondHandWidth: CGFloat = 1.2
    static let centerDotRadius: CGFloat = 3.0
    static let cornerRadius: CGFloat = 7.3
}

/// Mark size in base units: width is tangential, length is radial.
public struct MarkSize: Equatable {
    public var width: CGFloat
    public var length: CGFloat

    public init(width: CGFloat, length: CGFloat) {
        self.width = width
        self.length = length
    }

    public static let `default` = MarkSize(width: Metrics.markWidth, length: Metrics.markLength)
    public static let minuteDefault = MarkSize(width: Metrics.markWidth, length: Metrics.markWidth)
}

public enum MarkStyle: String, Equatable {
    case dashes, dots
}

/// Config-driven geometry in base units; defaults equal `Metrics`.
public struct ClockGeometry: Equatable {
    public var hourHandWidth: CGFloat = Metrics.hourHandWidth
    public var minuteHandWidth: CGFloat = Metrics.minuteHandWidth
    public var secondHandWidth: CGFloat = Metrics.secondHandWidth
    public var cornerRadius: CGFloat = Metrics.cornerRadius
    public var clockSize: CGFloat = Metrics.clockDiameter
    public var circleWidth: CGFloat = Metrics.circleLineWidth
    public var minuteMarkSize = MarkSize.minuteDefault
    public var hourMarkSize = MarkSize.default
    public var quarterMarkSize = MarkSize.default
    public var markInset: CGFloat = Metrics.markInset
    public var markStyle: MarkStyle = .dashes

    public func markSize(_ tier: MarkTier) -> MarkSize {
        switch tier {
        case .minute: return minuteMarkSize
        case .hour: return hourMarkSize
        case .quarter: return quarterMarkSize
        }
    }

    public static let `default` = ClockGeometry()
}

public enum MarkTier: CaseIterable {
    case minute, hour, quarter

    /// Tier owning minute position `index` (0..<60).
    public static func of(minute index: Int) -> MarkTier {
        let i = ((index % 60) + 60) % 60
        if i % 15 == 0 { return .quarter }
        if i % 5 == 0 { return .hour }
        return .minute
    }
}

public struct Theme {
    let background: NSColor
    let foreground: NSColor
    let secondHand: NSColor
    let circle: NSColor
    let minuteMark: NSColor
    let hourMark: NSColor
    let quarterMark: NSColor

    public init(background: NSColor, foreground: NSColor, secondHand: NSColor, circle: NSColor? = nil,
                minuteMark: NSColor? = nil, hourMark: NSColor? = nil, quarterMark: NSColor? = nil) {
        self.background = background
        self.foreground = foreground
        self.secondHand = secondHand
        self.circle = circle ?? foreground
        self.minuteMark = minuteMark ?? foreground.withAlphaComponent(0)
        self.hourMark = hourMark ?? foreground
        self.quarterMark = quarterMark ?? foreground
    }

    func markColor(_ tier: MarkTier) -> NSColor {
        switch tier {
        case .minute: return minuteMark
        case .hour: return hourMark
        case .quarter: return quarterMark
        }
    }

    public static let catppuccinMacchiato = Theme(
        background: NSColor(red: 36/255, green: 39/255, blue: 58/255, alpha: 0.95),
        foreground: NSColor(red: 202/255, green: 211/255, blue: 245/255, alpha: 1.0),
        secondHand: NSColor(red: 237/255, green: 135/255, blue: 150/255, alpha: 1.0)
    )
}
