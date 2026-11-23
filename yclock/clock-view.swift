import Cocoa

public class ClockView: NSView {
    var timer: Timer?
    var isDigital: Bool = false
    var showSeconds: Bool = false
    public var theme: Theme = Theme.catppuccinMacchiato
    public var fontName: String?
    public var geometry = Config.default.geometry { didSet { updateCornerRadius(); needsDisplay = true } }
    public var designSize = NSSize(width: Config.default.width, height: Config.default.height) {
        didSet { updateCornerRadius(); needsDisplay = true }
    }

    public var unlockRingWidth: CGFloat = Config.default.unlockRingWidth { didSet { updateRing() } }
    let ringLayer = CAShapeLayer()
    let flashLayer = CALayer()

    var renderFactor: CGFloat {
        guard designSize.width > 0, designSize.height > 0 else { return 1 }
        return min(bounds.width / designSize.width, bounds.height / designSize.height)
    }

    public override init(frame: NSRect) {
        super.init(frame: frame)
        setupTimer()
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        setupOverlayLayers()
        updateCornerRadius()
    }

    private func setupOverlayLayers() {
        ringLayer.fillColor = nil
        ringLayer.lineCap = .butt
        ringLayer.strokeEnd = 0
        ringLayer.isHidden = true
        flashLayer.backgroundColor = NSColor.white.cgColor
        flashLayer.opacity = 0
        for l in [ringLayer, flashLayer] { l.actions = ["bounds": NSNull(), "position": NSNull(), "path": NSNull(), "lineWidth": NSNull(), "strokeColor": NSNull(), "strokeStart": NSNull(), "strokeEnd": NSNull(), "opacity": NSNull(), "hidden": NSNull()] }
        layer?.addSublayer(ringLayer)
        layer?.addSublayer(flashLayer)
    }

    static func ringPath(size: CGSize, radius: CGFloat, flipped: Bool) -> CGPath {
        let top: CGFloat = flipped ? 0 : size.height
        let bottom: CGFloat = flipped ? size.height : 0
        let tr = CGPoint(x: size.width, y: top), br = CGPoint(x: size.width, y: bottom)
        let bl = CGPoint(x: 0, y: bottom), tl = CGPoint(x: 0, y: top)
        let start = CGPoint(x: size.width / 2, y: top)
        let path = CGMutablePath()
        path.move(to: start)
        path.addArc(tangent1End: tr, tangent2End: br, radius: radius)
        path.addArc(tangent1End: br, tangent2End: bl, radius: radius)
        path.addArc(tangent1End: bl, tangent2End: tl, radius: radius)
        path.addArc(tangent1End: tl, tangent2End: start, radius: radius)
        path.addLine(to: start)
        return path
    }

    func updateRing() {
        guard let layer = layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let radius = Self.effectiveCornerRadius(geometry.cornerRadius, factor: renderFactor, size: bounds.size)
        for l in [ringLayer, flashLayer] { l.frame = bounds }
        ringLayer.path = Self.ringPath(size: bounds.size, radius: radius, flipped: layer.isGeometryFlipped)
        ringLayer.lineWidth = max(unlockRingWidth * renderFactor, 2)
        CATransaction.commit()
    }

    func hideRing() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer.removeAnimation(forKey: "ring")
        ringLayer.isHidden = true
        ringLayer.strokeStart = 0
        ringLayer.strokeEnd = 0
        CATransaction.commit()
    }

    func showFullRing(color: NSColor) {
        setRing(color: color, start: 0, end: 1, animating: nil, duration: 0)
    }

    func fillRing(color: NSColor, duration: TimeInterval) {
        setRing(color: color, start: 0, end: 1, animating: "strokeEnd", duration: duration)
    }

    func eraseRing(color: NSColor, duration: TimeInterval) {
        setRing(color: color, start: 1, end: 1, animating: "strokeStart", duration: duration)
    }

    private func setRing(color: NSColor, start: CGFloat, end: CGFloat, animating key: String?, duration: TimeInterval) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer.removeAnimation(forKey: "ring")
        ringLayer.strokeColor = color.cgColor
        ringLayer.strokeStart = start
        ringLayer.strokeEnd = end
        ringLayer.isHidden = false
        if let key, duration > 0 {
            let a = CABasicAnimation(keyPath: key)
            a.fromValue = 0
            a.toValue = 1
            a.duration = duration
            a.timingFunction = CAMediaTimingFunction(name: .linear)
            ringLayer.add(a, forKey: "ring")
        }
        CATransaction.commit()
    }

    func flash() {
        let a = CAKeyframeAnimation(keyPath: "opacity")
        a.values = [0, 1, 0]
        a.keyTimes = [0, 0.5, 1]
        a.duration = 0.2
        flashLayer.add(a, forKey: "flash")
    }

    static func effectiveCornerRadius(_ baseRadius: CGFloat, factor: CGFloat, size: NSSize) -> CGFloat {
        max(0, min(baseRadius * factor, min(size.width, size.height) / 2))
    }

    func updateCornerRadius() {
        layer?.cornerRadius = Self.effectiveCornerRadius(geometry.cornerRadius, factor: renderFactor, size: bounds.size)
        updateRing()
        window?.invalidateShadow()
    }

    public override func layout() {
        super.layout()
        updateCornerRadius()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerRadius()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTimer()
    }

    func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    public override var isFlipped: Bool {
        return true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        theme.background.setFill()
        bounds.fill()

        // Get current time
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)

        if isDigital {
            drawDigitalClock(hour: hour, minute: minute, second: second)
        } else {
            drawAnalogClock(hour: hour, minute: minute, second: second)
        }
    }

    func drawDigitalClock(hour: Int, minute: Int, second: Int) {
        let timeString = showSeconds ?
            String(format: "%02d:%02d:%02d", hour, minute, second) :
            String(format: "%02d:%02d", hour, minute)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let fontSize = min(bounds.width, bounds.height) * 0.3
        
        // Use custom font if specified, otherwise use monospaced digits
        let font: NSFont
        if let fontName = fontName, let customFont = NSFont(name: fontName, size: fontSize) {
            font = customFont
        } else {
            font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.foreground,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: timeString, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = NSRect(x: (bounds.width - textSize.width) / 2,
                             y: (bounds.height - textSize.height) / 2 - textSize.height * 0.3,
                             width: textSize.width,
                             height: textSize.height)

        attributedString.draw(in: textRect)

        // Draw date below the time
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d. MMM"
        let dateString = dateFormatter.string(from: date)

        let dateFontSize = fontSize * 0.4
        
        // Use same custom font for date if specified
        let dateFont: NSFont
        if let fontName = fontName, let customFont = NSFont(name: fontName, size: dateFontSize) {
            dateFont = customFont
        } else {
            dateFont = NSFont.systemFont(ofSize: dateFontSize, weight: .regular)
        }
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: theme.foreground,
            .paragraphStyle: paragraphStyle
        ]

        let dateAttributedString = NSAttributedString(string: dateString, attributes: dateAttributes)
        let dateSize = dateAttributedString.size()
        let dateRect = NSRect(x: (bounds.width - dateSize.width) / 2,
                             y: textRect.maxY + textSize.height * 0.2,
                             width: dateSize.width,
                             height: dateSize.height)

        dateAttributedString.draw(in: dateRect)
    }

    func drawAnalogClock(hour: Int, minute: Int, second: Int) {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let k = renderFactor
        let radius = geometry.clockSize * k / 2

        // Draw clock face
        if theme.circle.alphaComponent > 0 && geometry.circleWidth > 0 {
            theme.circle.setStroke()
            let circlePath = NSBezierPath(ovalIn: NSRect(x: center.x - radius,
                                                          y: center.y - radius,
                                                          width: radius * 2,
                                                          height: radius * 2))
            circlePath.lineWidth = geometry.circleWidth * k
            circlePath.stroke()
        }
        for i in 0..<60 {
            let color = theme.markColor(MarkTier.of(minute: i))
            guard color.alphaComponent > 0 else { continue }
            color.setStroke()
            color.setFill()
            drawMark(at: center, radius: radius, index: i, k: k)
        }
        theme.foreground.setStroke()

        // Draw hour hand
        let hourAngle = (CGFloat(hour % 12) + CGFloat(minute) / 60) * .pi / 6 - .pi / 2
        drawHand(at: center, angle: hourAngle, length: radius * 0.5, width: geometry.hourHandWidth * k)

        // Draw minute hand
        let minuteAngle = (CGFloat(minute) + CGFloat(second) / 60) * .pi / 30 - .pi / 2
        drawHand(at: center, angle: minuteAngle, length: radius * 0.7, width: geometry.minuteHandWidth * k)

        // Draw second hand
        if showSeconds {
            let secondAngle = CGFloat(second) * .pi / 30 - .pi / 2
            theme.secondHand.setStroke()
            drawHand(at: center, angle: secondAngle, length: radius * 0.9, width: geometry.secondHandWidth * k)
        }

        // Draw center dot
        theme.foreground.setFill()
        let dotRadius = Metrics.centerDotRadius * k
        let dotRect = NSRect(x: center.x - dotRadius,
                            y: center.y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2)
        NSBezierPath(ovalIn: dotRect).fill()
    }

    public func toggleClockMode() {
        isDigital.toggle()
        needsDisplay = true
    }

    public func toggleSeconds() {
        showSeconds.toggle()
        needsDisplay = true
    }

    func drawMark(at center: NSPoint, radius: CGFloat, index: Int, k: CGFloat) {
        let size = geometry.markSize(MarkTier.of(minute: index))
        guard size.width > 0, size.length > 0 else { return }
        let angle = CGFloat(index) * .pi / 30 - .pi / 2
        let outer = radius - geometry.markInset * k
        if geometry.markStyle == .dots {
            let dot = NSBezierPath(ovalIn: NSRect(x: -size.length * k / 2, y: -size.width * k / 2,
                                                  width: size.length * k, height: size.width * k))
            var t = AffineTransform(translationByX: center.x + cos(angle) * outer, byY: center.y + sin(angle) * outer)
            t.rotate(byRadians: angle)
            dot.transform(using: t)
            dot.fill()
            return
        }
        let inner = outer - size.length * k
        let path = NSBezierPath()
        path.move(to: NSPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
        path.line(to: NSPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
        path.lineWidth = size.width * k
        path.lineCapStyle = .butt
        path.stroke()
    }

    func drawHand(at center: NSPoint, angle: CGFloat, length: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let handPath = NSBezierPath()
        handPath.move(to: center)
        let endX = center.x + cos(angle) * length
        let endY = center.y + sin(angle) * length
        handPath.line(to: NSPoint(x: endX, y: endY))
        handPath.lineWidth = width
        handPath.stroke()
    }

    deinit {
        timer?.invalidate()
    }
}
