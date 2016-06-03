//
//  ClippedCircle.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/3/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit

class ClippedCircle: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        layer.cornerRadius = frame.size.width / 2
        //layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).CGColor
        //layer.shadowOpacity = 0.8
        //layer.shadowRadius = 5.0
        //layer.shadowOffset = CGSizeMake(0, 2.0)
        
    }

}
