//
//  UIColor+SpeachToText.swift
//  SpeachToText
//
//  Created by Justin M Platz on 5/23/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func darkGrayBackground() -> UIColor {
        return UIColor(red:0.26, green:0.26, blue:0.26, alpha:1.0)
    }
    
    class func lightGrayBackground() -> UIColor{
        return UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
    }
    
    class func lightBorderColor() -> UIColor{
        return UIColor(red:0.84, green:0.83, blue:0.82, alpha:1.0)
    }
    
    // Colors to be used for keywords
    class func IBMBlueColor() -> UIColor{
        return UIColor(red:0.33, green:0.59, blue:0.90, alpha:1.0)
    }
    
    class func IBMGreenColor() -> UIColor{
        return UIColor(red:0.55, green:0.82, blue:0.07, alpha:1.0)
    }
    
    class func IBMTealColor() -> UIColor{
        return UIColor(red:0.00, green:0.71, blue:0.63, alpha:1.0)
    }
    
    class func IBMPurpleColor() -> UIColor{
        return UIColor(red:0.69, green:0.43, blue:0.91, alpha:1.0)
    }
    
    class func IBMRedColor() -> UIColor{
        return UIColor(red:0.91, green:0.11, blue:0.20, alpha:1.0)
    }
}
