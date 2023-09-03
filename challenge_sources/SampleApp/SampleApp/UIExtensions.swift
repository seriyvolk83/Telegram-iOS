//
//  UIExtensions.swift
//  SampleApp
//
//  Created by Volkov Alexander on 03.09.2023.
//

import Foundation
import UIKit

/**
 * Extends UIColor with helpful methods
 *
 * - author: Alexander Volkov
 * - version: 1.0
 */
extension UIColor {

    /// Creates new color with RGBA values from 0-255 for RGB and a from 0-1
    ///
    /// - Parameters:
    ///   - r: the red color
    ///   - g: the green color
    ///   - b: the blue color
    ///   - a: the alpha color
    public convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    /// Create color with RGB value in 16-format, e.g. 0xFF0000 -> red color
    ///
    /// - Parameter hex: the color in hex
    public convenience init(_ hex: Int) {
        let components = (
            r: CGFloat((hex >> 16) & 0xff) / 255,
            g: CGFloat((hex >> 08) & 0xff) / 255,
            b: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.r, green: components.g, blue: components.b, alpha: 1)
    }

    /**
     Creates new color with RGBA values from 0-255 for RGB and a from 0-1

     - parameter g: the gray color
     - parameter a: the alpha color
     */
    public convenience init(gray: CGFloat, a: CGFloat = 1) {
        self.init(r: gray, g: gray, b: gray, a: a)
    }

    /**
     Get UIColor from hex string, e.g. "FF0000" -> red color

     - parameter hexString: the hex string
     - returns: the UIColor instance or nil
     */
    public class func fromString(_ hexString: String) -> UIColor? {
        if hexString.count == 6 {
            let redStr = hexString[..<hexString.index(hexString.startIndex, offsetBy: 2)]
            let greenStr = hexString[hexString.index(hexString.startIndex, offsetBy: 2)..<hexString.index(hexString.startIndex, offsetBy: 4)]
            let blueStr = hexString[hexString.index(hexString.startIndex, offsetBy: 4)..<hexString.index(hexString.startIndex, offsetBy: 6)]
            return UIColor(
                r: CGFloat(Int(redStr, radix: 16)!),
                g: CGFloat(Int(greenStr, radix: 16)!),
                b: CGFloat(Int(blueStr, radix: 16)!))
        }
        return nil
    }

    /**
     Get same color with given transparancy

     - parameter alpha: the alpha channel

     - returns: the color with alpha channel
     */
    public func alpha(alpha: CGFloat) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b :CGFloat = 0
        if (self.getRed(&r, green:&g, blue:&b, alpha:nil)) {
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        }
        return self
    }
// dodo
//    /// Convert to string, e.g. "#FF0000"
//    ///
//    /// - Returns: the string
//    public func toString() -> String {
//        var red: CGFloat = 0
//        var green: CGFloat = 0
//        var blue: CGFloat = 0
//        var alpha: CGFloat = 0
//        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//        let redStr = Int(red * alpha * 255 + 255 * (1 - alpha)).toHex()
//        let greenStr = Int(green * alpha * 255 + 255 * (1 - alpha)).toHex()
//        let blueStr = Int(blue * alpha * 255 + 255 * (1 - alpha)).toHex()
//        return "#\(redStr)\(greenStr)\(blueStr)"
//    }
}
