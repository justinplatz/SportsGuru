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
        
    
        
        
    
//    func textViewDidChange(textView: UITextView) {
//        let fixedWidth = textView.frame.size.width
//        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
//        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
//        var newFrame = textView.frame
//        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
//        textView.frame = newFrame;
//    }
        
        //        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        //        let musicPath = paths.stringByAppendingPathComponent("recording.m4a")
        //
        //        let alertSound = NSURL(fileURLWithPath: musicPath)
        //
        //        // Removed deprecated use of AVAudioSessionDelegate protocol
        //        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        //        try! AVAudioSession.sharedInstance().setActive(true)
        //
        //        try! self.player = AVAudioPlayer(contentsOfURL: alertSound)
        //        self.player!.prepareToPlay()
        //        self.player!.play()
        

}

