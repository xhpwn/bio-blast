//
//  RoundedBorderLabel.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/3/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit

class RoundedBorderLabel: UILabel {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        layer.cornerRadius = 7.0
        self.clipsToBounds = true
        
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 1.0

    }

}
