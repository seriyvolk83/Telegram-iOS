//
//  PullToArchiveView.swift
//  SampleApp
//
//  Created by Volkov Alexander on 03.09.2023.
//

import Foundation
import UIKit

/// Some settings that used during layout
struct PullViewSettings {
    static let minHeight: CGFloat = 36
    static let actionMinHeight: CGFloat = 80
    static let releasedHeight: CGFloat = 80
    static let blueCircleSize: CGFloat = 30.5
}

/// Animation settings for the key frames of the box icon
struct BoxPathSettings {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let topCaps: Bool
    let duration: TimeInterval
    
    // blue line settings (appear from arrow)
    var lineWidth: CGFloat = 8
    var lineShift: CGFloat = 0
    
    // Top cap settings
    var capHeight: CGFloat
    var capWidth: CGFloat
    var capOffset: CGFloat = 0
    var capCorner: CGFloat = 3
    
    // Can be set to 5 or 10 to better see the quick box animation in details
    static let aScale: TimeInterval = 1
    
    /// initial circle background for the arrow
    static let circle = BoxPathSettings(width: 20, height: 20, cornerRadius: 10, topCaps: false, duration: -1, capHeight: -1, capWidth: -1, capOffset: 0)
    /// the number of total frames (the values counted for duration are taken from the video).
    static let numberOfFrames: Double = 80
    
    static let animation: [BoxPathSettings] = [
        // duration is not used for the first transform
        BoxPathSettings(width: 22, height: 18, cornerRadius: 5, topCaps: false, duration: -1, capHeight: 4, capWidth: 22, capOffset: 0),
        BoxPathSettings(width: 24, height: 18, cornerRadius: 3, topCaps: false, duration: (2 / numberOfFrames) * aScale, capHeight: 6, capWidth: 24, capOffset: 8),
        BoxPathSettings(width: 24, height: 18, cornerRadius: 3, topCaps: true, duration: (5 / numberOfFrames) * aScale, capHeight: 6, capWidth: 24, capOffset: 9), // cap at the top
        BoxPathSettings(width: 26, height: 17, cornerRadius: 3, topCaps: true, duration: (11 / numberOfFrames) * aScale, lineWidth: 12, lineShift: 2, capHeight: 6, capWidth: 26, capOffset: 7), // smashed
        BoxPathSettings(width: 24, height: 18, cornerRadius: 3, topCaps: true, duration: (8 / numberOfFrames) * aScale, capHeight: 6, capWidth: 26, capOffset: 7.5) // final
    ]
}

/// The pull to archive view
@IBDesignable
class PullToArchiveView: UIView {
    
    /// the possible states for the pull
    enum PositionState {
        case pulling
        case canRelease
        case releasing
        case doneRelease
        
        var isDragging: Bool {
            self == .pulling || self == .canRelease
        }
    }
    
    @IBInspectable var textSwipe: String = NSLocalizedString("Swipe down for archive", comment: "Swipe down for archive") {
        didSet { labelSwipe?.text = textSwipe }
    }
    @IBInspectable var textRelease: String = NSLocalizedString("Release for archive", comment: "Release for archive") {
        didSet { labelRelease?.text = textSwipe }
    }

    @IBInspectable var arrowCircleRadius: CGFloat = 10
    @IBInspectable var leftPadding: CGFloat = 30
    @IBInspectable var bottomPadding: CGFloat = 8
    
    @IBInspectable var pullAnimationDuration: TimeInterval = 0.2
    @IBInspectable var releaseAnimationDuration: TimeInterval = 0.3 // dodo 0.3
    
    @IBInspectable var arrowColorPulling: UIColor = UIColor(0xb0b0b0)
    @IBInspectable var arrowColorRelease: UIColor = UIColor(0x0d8cfe)
    
    var doneReleasingCallback: (() -> Void)?
    private let backgroundColors: [CGColor] = [UIColor(0xb4b9c0).cgColor, UIColor(0xdadada).cgColor]
    private let backgroundReleaseColors: [CGColor] = [UIColor(0x0885f2).cgColor, UIColor(0x75c5fd).cgColor]
    
    // Added views and layers
    private var archiveCell: UIView!
    private var backgroundGrayLayer: CAGradientLayer!
    private var backgroundBlueLayer: CAGradientLayer!
    private var markLayer: CAShapeLayer!
    private var arrowCircleLayer: CAShapeLayer!
    private var stripeLayer: CAShapeLayer!
    private var boxCapLayer: CAShapeLayer!
    private var arrowLayer1: CAShapeLayer!
    private var arrowLayer2: CAShapeLayer!
    private var labelSwipe: UILabel!
    private var labelRelease: UILabel!
    private var labelMaskView: UIView!
    
    /// current state
    private var state: PositionState = .pulling
    private var stateChangedTime: Date = Date()
    
    /// some magic numbers
    private let meanBoxHeight: CGFloat = 25
    private lazy var boxShiftOy: CGFloat = -1 * ((PullViewSettings.releasedHeight - meanBoxHeight) / 2 - bottomPadding)
    private let labelHeight: CGFloat = 44
    
    override func layoutSubviews() {
        super.layoutSubviews()
        initLayersIfNeeded()
        layoutAll()
    }
    
    /// Add all layers for the first time and apply frame changes
    private func initLayersIfNeeded() {
        // Background
        if archiveCell == nil && (state != .doneRelease && state != .releasing) {
            archiveCell = ArchiveCellView()
            addSubview(archiveCell)
        }
        archiveCell?.frame = self.bounds
        if backgroundGrayLayer == nil {
            self.layer.masksToBounds = true
            let l = CAGradientLayer()
            l.frame = self.frame
            l.type = .radial
            l.colors = backgroundColors
            l.locations = [0, 1]
            l.startPoint = CGPoint(x: 0, y: 0)
            l.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer(l)
            backgroundGrayLayer = l
        }
        if backgroundBlueLayer == nil {
            self.layer.masksToBounds = true
            let l = CAGradientLayer()
            l.frame = self.frame
            l.type = .radial
            l.colors = backgroundReleaseColors
            l.locations = [0, 1]
            l.startPoint = CGPoint(x: 0, y: 0)
            l.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer(l)
            markLayer = CAShapeLayer()
            backgroundBlueLayer = l
            backgroundBlueLayer?.mask = markLayer
            markLayer.path = createReleaseMaskLayerPath(circleCenter: calculateGradientCenter(), state: .pulling).cgPath
        }
        do {
            var gradientFrame = bounds
            gradientFrame.size.height = bounds.width
            backgroundBlueLayer?.frame = gradientFrame
            backgroundGrayLayer?.frame = gradientFrame
        }
        
        // Labels
        if labelSwipe == nil {
            labelSwipe = UILabel(frame: .zero)
            labelSwipe.textAlignment = .center
            labelSwipe.text = textSwipe
            labelSwipe.textColor = .white
            labelSwipe.font = .systemFont(ofSize: 16, weight: .semibold)
            labelSwipe?.frame.size.height = labelHeight
            self.addSubview(labelSwipe)
        }
        if labelRelease == nil {
            labelRelease = UILabel(frame: .zero)
            labelRelease.textAlignment = .center
            labelRelease.text = textRelease
            labelRelease.textColor = .white
            labelRelease.font = .systemFont(ofSize: 16, weight: .semibold)
            labelRelease.alpha = 0
            labelRelease?.frame.size.height = labelHeight
            labelRelease?.frame.origin.x = -bounds.width
            
            let mask = UIView()
            mask.backgroundColor = UIColor.clear
            mask.frame.origin.x = leftPadding + arrowCircleRadius
            mask.frame.size.height = 1000
            mask.addSubview(labelRelease)
            mask.layer.masksToBounds = true
            labelMaskView = mask
            addSubview(mask)
        }
        do {
            labelSwipe.frame.size.width = self.bounds.width
            labelRelease.frame.size.width = self.bounds.width
            labelMaskView.frame.size.width = self.bounds.size.width
        }
        
        // Stripe
        if stripeLayer == nil {
            stripeLayer = CAShapeLayer()
            let path = createStripePath(settings: BoxPathSettings.circle)
            stripeLayer.path = path.cgPath
            stripeLayer.fillColor = UIColor.white.cgColor
            stripeLayer.opacity = 0.35
            layer.addSublayer(stripeLayer)
        }
        
        // Circle
        if arrowCircleLayer == nil {
            arrowCircleLayer = CAShapeLayer()
            let path = createBoxPath(settings: BoxPathSettings.circle)
            arrowCircleLayer.path = path.cgPath
            arrowCircleLayer.fillColor = UIColor.white.cgColor
            layer.addSublayer(arrowCircleLayer)
        }
        
        // Arrow
        let arrowShift: CGFloat = -2
        if arrowLayer1 == nil {
            arrowLayer1 = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -4.5, y: 2.5 + arrowShift))
            path.addLine(to: CGPoint(x: 0, y: -2.5 + arrowShift))
            path.addLine(to: CGPoint(x: 4.5, y: 2.5 + arrowShift))
            arrowLayer1.path = path.cgPath
            arrowLayer1.lineWidth = 2
            arrowLayer1.lineCap = .round
            arrowLayer1.lineJoin = .round
            arrowLayer1.strokeColor = arrowColorPulling.cgColor
            arrowLayer1.fillColor = UIColor.clear.cgColor
            arrowLayer1.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: -.pi))
            layer.addSublayer(arrowLayer1)
        }
        if arrowLayer2 == nil {
            arrowLayer2 = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 7 + arrowShift))
            path.addLine(to: CGPoint(x: 0, y: -2.5 + arrowShift))
            arrowLayer2.path = path.cgPath
            arrowLayer2.lineWidth = 2
            arrowLayer2.lineCap = .round
            arrowLayer2.lineJoin = .round
            arrowLayer2.strokeColor = arrowColorPulling.cgColor
            arrowLayer2.fillColor = UIColor.clear.cgColor
            arrowLayer2.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: -.pi))
            layer.addSublayer(arrowLayer2)
        }
    }
    
    /// Add layer for the box cap
    private func initBoxCapIfNeeded() {
        if boxCapLayer == nil {
            boxCapLayer = CAShapeLayer()
            boxCapLayer.fillColor = UIColor.white.cgColor
            boxCapLayer.path = createBoxCapPath(settings: BoxPathSettings.animation[0]).cgPath
            layer.addSublayer(boxCapLayer)
        }
    }
    
    /// Layout all items
    private func layoutAll() {
        guard arrowCircleLayer != nil else { return }

        let p = calculateArrowCirclePositionPulling()
        let circleCenter = CGPoint(x: p.x + arrowCircleRadius, y: p.y + arrowCircleRadius)
        // Text
        
        let textOy = circleCenter.y - labelHeight / 2
        labelSwipe?.frame.origin.y = textOy
        labelRelease?.frame.origin.y = textOy
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Circle
        arrowCircleLayer.position = p
        boxCapLayer?.position = p
        
        // Background mask
        markLayer?.position = circleCenter
                
        // Arrow
        do {
            let relativeArrowPosition = calculateArrowPosition()
            arrowLayer1.position = relativeArrowPosition
            arrowLayer2.position = relativeArrowPosition
        }
        // Stripe
        do {
            stripeLayer.position = p
            let h = self.bounds.height - bottomPadding * 2 - arrowCircleRadius * 2
            if h > 0 {
                if state.isDragging {
                    stripeLayer.path = createStripePath(settings: .circle, height: h).cgPath
                }
            }
            else {
                stripeLayer.path = createStripePath(settings: .circle).cgPath
            }
        }
        CATransaction.commit()
        
        checkStateChangesAndAnimateIfNeeded()
    }
    
    // MARK: - State changes
    
    /// Check if need to change the state and animate
    private func checkStateChangesAndAnimateIfNeeded() {
        if state == .pulling && canRelease(self.bounds.height) {
            if canChangeStateByTime() {
                state = .canRelease
                animateState()
            }
        }
        else if state == .canRelease && canRollbackToPulling(self.bounds.height) {
            if canChangeStateByTime() {
                state = .pulling
                animateState()
            }
        }
    }

    /// Tries to animate the release if it's allowed
    func tryRelease() -> Bool {
        guard state == .canRelease else { return false }
        state = .releasing
        animateState()
        return true
    }
    
    /// Check the offset to match the release area
    /// - Parameter offset: the offset
    private func canRelease(_ offset: CGFloat) -> Bool {
        offset >= PullViewSettings.actionMinHeight
    }
    
    /// Check the offset to match the pulling area
    /// - Parameter offset: the offset
    private func canRollbackToPulling(_ height: CGFloat) -> Bool {
        height < PullViewSettings.actionMinHeight
    }
    
    /// Check if can animate again (debounce)
    private func canChangeStateByTime() -> Bool {
        let now = Date()
        let res = now.timeIntervalSince(stateChangedTime) > 0.5
        if res {
            stateChangedTime = now
        }
        return res
    }
    
    // MARK: - Calculations
    
    /// Calculate base position for the white circle
    private func calculateArrowCirclePositionPulling() -> CGPoint {
        let circleSize = arrowCircleRadius * 2
        let h = self.bounds.height
        let y = h - bottomPadding - circleSize
        return CGPoint(x: leftPadding, y: y)
    }
    
    /// Calculate arrow position
    private func calculateArrowPosition() -> CGPoint {
        let p = calculateArrowCirclePositionPulling()
        return CGPoint(x: p.x + arrowCircleRadius, y: p.y + arrowCircleRadius)
    }
    
    /// Calculate graditent position
    private func calculateGradientCenter() -> CGPoint {
        return .zero
    }
    
    // MARK: - Animation
    
    /// Animate current state
    private func animateState() {
        CATransaction.begin()
        switch state {
        case .pulling, .canRelease:
            CATransaction.setAnimationDuration(pullAnimationDuration)
        default:
            CATransaction.setAnimationDuration(releaseAnimationDuration)
        }
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        CATransaction.setDisableActions(false)
        do {
            let path = createReleaseMaskLayerPath(circleCenter: calculateGradientCenter(), state: state, shiftOy: state.isDragging ? 0 : boxShiftOy)
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = 0.2
            animation.toValue = path.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            markLayer.add(animation, forKey: nil)
        }
        
        switch state {
        case .pulling:
            arrowLayer1?.strokeColor = arrowColorPulling.cgColor
            arrowLayer1?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: -.pi))
            arrowLayer2?.strokeColor = arrowColorPulling.cgColor
            arrowLayer2?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: -.pi))
            
            // Text
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) { [labelRelease, labelSwipe] in
                labelRelease?.frame.origin.x = -self.bounds.width
                labelRelease?.alpha = 0
                labelSwipe?.frame.origin.x = 0
                labelSwipe?.alpha = 1
            }
            
        case .canRelease:
            arrowLayer1?.strokeColor = arrowColorRelease.cgColor
            arrowLayer1?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: 0.001))
            arrowLayer2?.strokeColor = arrowColorRelease.cgColor
            arrowLayer2?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: 0.001))
            
            // Text
            let textShift = -(leftPadding + arrowCircleRadius)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) { [labelRelease, labelSwipe] in
                labelRelease?.frame.origin.x = textShift
                labelRelease?.alpha = 1
                labelSwipe?.frame.origin.x = self.bounds.width
                labelSwipe?.alpha = 0
            }
        case .releasing:
            // change arrow path
            let path = UIBezierPath()
            let arrowShift: CGFloat = -2 // dodo dupliation
            path.move(to: CGPoint(x: -5, y: 0 + arrowShift))
            path.addLine(to: CGPoint(x: 5, y: 0 + arrowShift))
            arrowLayer1?.path = path.cgPath

            arrowLayer1?.strokeColor = arrowColorRelease.cgColor
            arrowLayer1?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: 0.001))
            arrowLayer2?.strokeColor = UIColor.clear.cgColor
            arrowLayer2?.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: 0.001))
            
            // Text
            labelRelease?.frame.origin.x = -(leftPadding + arrowCircleRadius)
            labelRelease?.alpha = 0
            
            // Change circle path -> box
            CATransaction.setCompletionBlock { [weak self] in
                self?.animateBox(index: 1)
            }
            backgroundGrayLayer.opacity = 0
            animateBox(index: 0)
        case .doneRelease:
            break
        }
        CATransaction.commit()
    }
    
    /// Animate all box elements
    /// - Parameter index: the index of the animation key frame
    private func animateBox(index: Int) {
        print("\(Date()): animateBox: \(index)")
        guard index < BoxPathSettings.animation.count else { completeReleaseAnimation(); return }
        let settings = BoxPathSettings.animation[index]
        if index > 0 {
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            CATransaction.setCompletionBlock { [weak self] in
                self?.animateBox(index: index + 1) // schedule next key frame
            }
            CATransaction.setAnimationDuration(settings.duration)
        }
        
        let boxShiftOy = self.boxShiftOy + 2
        // Box
        do {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = settings.duration
            animation.toValue = createBoxPath(settings: settings, shiftOy: boxShiftOy).cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            arrowCircleLayer.add(animation, forKey: nil)
        }
        
        // Stripe
        do {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = settings.duration
            animation.toValue = createStripePath(settings: BoxPathSettings.circle, shiftOy: boxShiftOy).cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            stripeLayer.add(animation, forKey: nil)
            if index > 0 {
                stripeLayer.opacity = 0
            }
        }
        
        // Line
        do {
            let path = UIBezierPath()
            let lineShift: CGFloat = -5 + settings.lineShift + boxShiftOy
            path.move(to: CGPoint(x: -settings.lineWidth / 2, y: 0 + lineShift))
            path.addLine(to: CGPoint(x: settings.lineWidth / 2, y: 0 + lineShift))
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = settings.duration
            
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.toValue = path.cgPath
            
            arrowLayer1?.add(animation, forKey: nil)
        }
        initBoxCapIfNeeded()
        if settings.capWidth > 0 {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = settings.duration
            animation.toValue = createBoxCapPath(settings: settings, shiftOy: boxShiftOy).cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            boxCapLayer.add(animation, forKey: nil)
        }
        
        if index > 0 {
            CATransaction.commit()
        }
    }
    
    private func completeReleaseAnimation() {
        archiveCell?.removeFromSuperview()
        archiveCell = nil
        doneReleasingCallback?()
    }
    
    /// Create path for the box
    /// - Parameters:
    ///   - settings: the settings for the state
    ///   - shiftOy: extra Oy offset
    private func createBoxPath(settings: BoxPathSettings, shiftOy: CGFloat = 0) -> UIBezierPath {
        let cr: CGFloat = settings.cornerRadius
        let w = settings.width
        let h = settings.height
        let path = UIBezierPath()

        let shift = CGPoint(x: arrowCircleRadius, y: arrowCircleRadius * 2 + shiftOy)
        path.move(to: CGPoint(x: shift.x - w / 2, y: shift.y - cr))
        let tc = settings.topCaps ? 0 : cr
        // 1
        path.addLine(to: CGPoint(x: shift.x - w / 2, y: shift.y - (h - cr)))
        // 2
        path.addArc(withCenter: CGPoint(x: shift.x-w / 2 + tc, y: shift.y - (h - tc)), // center point of circle
                    radius: tc, // this will make it meet our path line
                    startAngle: .pi, // π radians = 180 degrees = straight left
                    endAngle: 3 * .pi / 2, // 3π/2 radians = 270 degrees = straight up
                    clockwise: true) // startAngle to endAngle goes in a clockwise direction
        // 3
        path.addLine(to: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - h))
        // 4
        path.addArc(withCenter: CGPoint(x: shift.x + w / 2 - tc, y: shift.y - (h - tc)),
                    radius: tc,
                    startAngle: 3 * .pi / 2,
                    endAngle: 0,
                    clockwise: true)
        // 5
        path.addLine(to: CGPoint(x: shift.x + w / 2, y: shift.y - cr))
        // 6
        path.addArc(withCenter: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - cr),
                    radius: cr,
                    startAngle: 0,
                    endAngle: .pi / 2,
                    clockwise: true)
        // 7
        path.addLine(to: CGPoint(x: shift.x - w / 2 + cr, y: shift.y - 0))
        path.addArc(withCenter: CGPoint(x: shift.x - w / 2 + cr, y: shift.y - cr),
                    radius: cr,
                    startAngle: .pi / 2,
                    endAngle: .pi,
                    clockwise: true)
        return path
    }
    
    /// Create path for the box cap
    /// - Parameters:
    ///   - settings: the settings for the state
    ///   - shiftOy: the extra Oy offset
    private func createBoxCapPath(settings: BoxPathSettings, shiftOy: CGFloat = 0) -> UIBezierPath {
        let cr: CGFloat = settings.capCorner
        let w = settings.capWidth
        let h = settings.capHeight
        let path = UIBezierPath()

        let shift = CGPoint(x: arrowCircleRadius, y: arrowCircleRadius * 2 - settings.height - settings.capOffset + h + shiftOy)
        path.move(to: CGPoint(x: shift.x - w / 2, y: shift.y))
        path.addLine(to: CGPoint(x: shift.x - w / 2, y: shift.y - (h - cr)))
        // 2
        path.addArc(withCenter: CGPoint(x: shift.x-w / 2 + cr, y: shift.y - (h - cr)), // center point of circle
                    radius: cr, // this will make it meet our path line
                    startAngle: .pi, // π radians = 180 degrees = straight left
                    endAngle: 3 * .pi / 2, // 3π/2 radians = 270 degrees = straight up
                    clockwise: true) // startAngle to endAngle goes in a clockwise direction
        // 3
        path.addLine(to: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - h))
        // 4
        path.addArc(withCenter: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - (h - cr)), radius: cr, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        // 5
        path.addLine(to: CGPoint(x: shift.x + w / 2, y: shift.y))
        // 7
        path.addLine(to: CGPoint(x: shift.x - w / 2, y: shift.y - 0))
        return path
    }
    
    /// Create path for the arrow stripe
    /// - Parameters:
    ///   - settings: the settings for the state
    ///   - height: the height of the stripe
    ///   - shiftOy: the extra Oy offset
    private func createStripePath(settings: BoxPathSettings, height: CGFloat? = nil, shiftOy: CGFloat = 0) -> UIBezierPath {
        let cr: CGFloat = settings.cornerRadius
        let w = settings.width
        let h = arrowCircleRadius * 2 + (height ?? 0)
        let path = UIBezierPath()

        let shift = CGPoint(x: arrowCircleRadius, y: arrowCircleRadius * 2 + shiftOy)
        path.move(to: CGPoint(x: shift.x - w / 2, y: shift.y - cr))
        // 1
        path.addLine(to: CGPoint(x: shift.x - w / 2, y: shift.y - (h - cr)))
        // 2
        path.addArc(withCenter: CGPoint(x: shift.x-w / 2 + cr, y: shift.y - (h - cr)), // center point of circle
                    radius: cr, // this will make it meet our path line
                    startAngle: .pi, // π radians = 180 degrees = straight left
                    endAngle: 3 * .pi / 2, // 3π/2 radians = 270 degrees = straight up
                    clockwise: true) // startAngle to endAngle goes in a clockwise direction
        // 3
        path.addLine(to: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - h))
        // 4
        path.addArc(withCenter: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - (h - cr)), radius: cr, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        // 5
        path.addLine(to: CGPoint(x: shift.x + w / 2, y: shift.y - cr))
        // 6
        path.addArc(withCenter: CGPoint(x: shift.x + w / 2 - cr, y: shift.y - cr), radius: cr, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        // 7
        path.addLine(to: CGPoint(x: shift.x - w / 2 + cr, y: shift.y - 0))
        path.addArc(withCenter: CGPoint(x: shift.x - w / 2 + cr, y: shift.y - cr), radius: cr, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        return path
    }
    
    /// Create a path for the gradirent mask
    /// - Parameters:
    ///   - circleCenter: the circle center
    ///   - state: the current state
    ///   - shiftOy: the extra Oy offset
    private func createReleaseMaskLayerPath(circleCenter: CGPoint, state: PositionState, shiftOy: CGFloat = 0) -> UIBezierPath {
        let radius: CGFloat
        switch state {
        case .pulling:
            radius = arrowCircleRadius
        case .canRelease:
            radius = self.bounds.width
        case .releasing, .doneRelease:
            radius = PullViewSettings.blueCircleSize
        }
        return UIBezierPath(ovalIn: CGRect(x: -radius + circleCenter.x, y: -radius + circleCenter.y + shiftOy, width: radius * 2, height: radius * 2))
    }
}
