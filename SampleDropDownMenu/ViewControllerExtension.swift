//
//  Credentials.swift
//  SpeachToText
//
//  Created by Justin M Platz on 5/24/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import Foundation
import UIKit

    /* 
        This function simple takes a number 1-5 and returns a UI Color.
        Numbers not in range return default.
        This function is used to give first 5 keywords found different colors.
    */
    func assignColor(number: Int) -> UIColor{
        switch number {
        case 1:
            return UIColor.IBMBlueColor()
        case 2:
            return UIColor.IBMRedColor()
        case 3:
            return UIColor.IBMGreenColor()
        case 4:
            return UIColor.IBMPurpleColor()
        case 5:
            return UIColor.IBMTealColor()
        default:
            return UIColor.IBMBlueColor()
    }
    
}

