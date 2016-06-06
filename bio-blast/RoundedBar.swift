//
//  RoundedBar.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/6/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit

class RoundedBar: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        layer.cornerRadius = frame.size.height / 2
        self.clipsToBounds = true
    }

}
