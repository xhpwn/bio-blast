//
//  ContactAnnotation.swift
//  bio-blast
//
//  Created by Alex Bussan on 5/31/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import Foundation
import MapKit

class ContactAnnotation: NSObject, MKAnnotation {
    var coordinate = CLLocationCoordinate2D()
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}