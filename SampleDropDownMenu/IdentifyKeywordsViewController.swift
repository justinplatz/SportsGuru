//
//  IdentifyKeywords.swift
//  SampleDropDownMenu
//
//  Created by Justin M Platz on 6/1/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import Foundation
import UIKit

class IdentifyKeywordsViewController: UIViewController {
    @IBOutlet weak var keywordsTextView: UITextView!
    var keywordsText = NSAttributedString()
    
    override func viewDidLoad() {
        keywordsTextView.attributedText = keywordsText
    }
    
    override func viewDidAppear(animated: Bool)  {
    }
    
    override func viewWillDisappear(animated: Bool)  {
    }

}
