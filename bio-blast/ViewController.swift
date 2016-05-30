//
//  ViewController.swift
//  bio-blast
//
//  Created by Alex Bussan on 5/29/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var addressIdLbl: UILabel!
    @IBOutlet weak var placeLbl: UILabel!
    @IBOutlet weak var coordsLbl: UILabel!
    @IBOutlet weak var map: MKMapView!

    var currentPlaceStr: String = ""
    var currentAddressId: String = ""
    let locationManager = LKLocationManager()
    let regionRadius: CLLocationDistance = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        
        self.locationManager.debug = true
        self.locationManager.apiToken = "21292208b912cf86"
        //locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        map.delegate = self
        map.showsUserLocation = true
    }

    @IBAction func getLocation(sender: UIButton) {
        
        self.locationManager.startUpdatingLocation()
        
        self.locationManager.requestLocation { (location: CLLocation?, error: NSError?) -> Void in
            if let loc = location {
                self.centerMapOnLocation(loc)
            }
        }
        
        self.locationManager.requestPlace { (place: LKPlacemark?, error: NSError?) -> Void in
            if let place = place {
                self.currentPlaceStr = "\(place)"
                
                if let addressId = place.addressId {
                    self.currentAddressId = addressId
                } else {
                    print("NO ADDRESS ID")
                }
                
                self.addressIdLbl.text = "\(self.currentAddressId)"
                self.placeLbl.text = self.currentPlaceStr
                self.coordsLbl.text = "\(place.location!.coordinate.latitude), \(place.location!.coordinate.longitude)"
                
            } else if error != nil {
                print("ERROR FETCHING PLACE: \(error.debugDescription)")
            } else {
                print("NO ERROR, BUT PLACE COULD NOT BE FOUND")
            }
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coorinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2, regionRadius * 2)
        map.setRegion(coorinateRegion, animated: true)
    }

}

