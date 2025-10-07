import Cocoa

class ClockView: NSView {
    var timer: Timer?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTimer()
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
        
        NSColor.white.setFill()
        bounds.fill()
        
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        
        // Draw clock face
        NSColor.black.setStroke()
        let circlePath = NSBezierPath(ovalIn: NSRect(x: center.x - radius,
                                                      y: center.y - radius,
                                                      width: radius * 2,
                                                      height: radius * 2))
        circlePath.lineWidth = 2
        circlePath.stroke()
        
        // Draw hour markers
        for hour in 0..<12 {
            let angle = CGFloat(hour) * .pi / 6 - .pi / 2
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
        
        // Get current time
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        // Draw hour hand
        let hourAngle = (CGFloat(hour % 12) + CGFloat(minute) / 60) * .pi / 6 - .pi / 2
        drawHand(at: center, angle: hourAngle, length: radius * 0.5, width: 6)
        
        // Draw minute hand
        let minuteAngle = (CGFloat(minute) + CGFloat(second) / 60) * .pi / 30 - .pi / 2
        drawHand(at: center, angle: minuteAngle, length: radius * 0.7, width: 4)
        
        // Draw second hand
        let secondAngle = CGFloat(second) * .pi / 30 - .pi / 2
        NSColor.red.setStroke()
        drawHand(at: center, angle: secondAngle, length: radius * 0.9, width: 2)
        
        // Draw center dot
        NSColor.black.setFill()
        let dotRadius: CGFloat = 5
        let dotRect = NSRect(x: center.x - dotRadius,
                            y: center.y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2)
        NSBezierPath(ovalIn: dotRect).fill()
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
