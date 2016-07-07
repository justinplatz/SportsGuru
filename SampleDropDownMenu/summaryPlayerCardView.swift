//
//  summaryPlayerCardView.swift
//  SportsGuru
//
//  Created by Justin M Platz on 7/7/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import UIKit

@IBDesignable class summaryPlayerCardView: UIView {

    var view: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var birthplaceLabel: UILabel!
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required internal init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass:self.dynamicType)
        let nib = UINib(nibName: "summaryPlayerCardView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }

}
