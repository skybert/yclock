import Cocoa

class ClockView: NSView {
    var timer: Timer?
    var isDigital: Bool = false
    var showSeconds: Bool = false
    var theme: Theme = Theme.catppuccinMacchiato

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTimer()
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
        self.layer?.masksToBounds = true
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

    override var isFlipped: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
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
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium),
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
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: dateFontSize, weight: .regular),
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
        let radius = min(bounds.width, bounds.height) / 2 - 10

        // Draw clock face
        theme.foreground.setStroke()
        let circlePath = NSBezierPath(ovalIn: NSRect(x: center.x - radius,
                                                      y: center.y - radius,
                                                      width: radius * 2,
                                                      height: radius * 2))
        circlePath.lineWidth = 2
        circlePath.stroke()

        // Draw hour markers
        for h in 0..<12 {
            let angle = CGFloat(h) * .pi / 6 - .pi / 2
            let innerRadius = radius * 0.85
            let outerRadius = radius * 0.95

            let x1 = center.x + cos(angle) * innerRadius
            let y1 = center.y + sin(angle) * innerRadius
            let x2 = center.x + cos(angle) * outerRadius
            let y2 = center.y + sin(angle) * outerRadius

            let markerPath = NSBezierPath()
            markerPath.move(to: NSPoint(x: x1, y: y1))
            markerPath.line(to: NSPoint(x: x2, y: y2))
            markerPath.lineWidth = 2
            markerPath.stroke()
        }

        // Draw hour hand
        let hourAngle = (CGFloat(hour % 12) + CGFloat(minute) / 60) * .pi / 6 - .pi / 2
        drawHand(at: center, angle: hourAngle, length: radius * 0.5, width: 6)

        // Draw minute hand
        let minuteAngle = (CGFloat(minute) + CGFloat(second) / 60) * .pi / 30 - .pi / 2
        drawHand(at: center, angle: minuteAngle, length: radius * 0.7, width: 4)

        // Draw second hand
        if showSeconds {
            let secondAngle = CGFloat(second) * .pi / 30 - .pi / 2
            theme.secondHand.setStroke()
            drawHand(at: center, angle: secondAngle, length: radius * 0.9, width: 2)
        }

        // Draw center dot
        theme.foreground.setFill()
        let dotRadius: CGFloat = 5
        let dotRect = NSRect(x: center.x - dotRadius,
                            y: center.y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2)
        NSBezierPath(ovalIn: dotRect).fill()
    }

    func toggleClockMode() {
        isDigital.toggle()
        needsDisplay = true
    }

    func toggleSeconds() {
        showSeconds.toggle()
        needsDisplay = true
    }

    func drawHand(at center: NSPoint, angle: CGFloat, length: CGFloat, width: CGFloat) {
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
