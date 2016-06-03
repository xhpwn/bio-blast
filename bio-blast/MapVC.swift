//
//  MapVC.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/3/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import Mapbox

class MapVC: UIViewController, MGLMapViewDelegate {
    
    @IBOutlet weak var mapBox: MGLMapView!
    @IBOutlet weak var loadingBlanket: UIView!
    
    var currentPlaceStr: String = ""
    var currentAddressId: String = ""
    var prevAddressId: String = ""
    
    var currentLoc: CLLocation?
    
    let locationManager = LKLocationManager()
    let regionRadius: CLLocationDistance = 250
    
    var uids: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapBox.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        mapBox.delegate = self
        
        let center = CLLocationCoordinate2D(latitude: 42.22154654, longitude: -88.22007143)
        mapBox.setCenterCoordinate(center, zoomLevel: 2, direction: 0, animated: false)
        
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.requestAlwaysAuthorization()
        
        locationManager.debug = true
        locationManager.apiToken = "21292208b912cf86"
        locationManager.startUpdatingLocation()
    
        setupObserver()
        
    }
    
    func mapViewDidFinishLoadingMap(mapBox: MGLMapView) {
        
        loadingBlanket.hidden = true
        
        let camera = MGLMapCamera(lookingAtCenterCoordinate: CLLocationCoordinate2D(latitude: 42.22154654, longitude: -88.22007143), fromDistance: 30000, pitch: 0, heading: 0)
        
        // Animate the camera movement over 5 seconds.
        mapBox.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
    
    func requestPlaceAndPushStreetAddressId() {
        
        locationManager.requestPlace { (place: LKPlacemark?, error: NSError?) -> Void in
            if let place = place {
                
                self.currentPlaceStr = "\(place)"
                print(self.currentPlaceStr)
                
                if let addressId = place.addressId {
                    self.currentAddressId = addressId
                } else {
                    print("NO ADDRESS ID")
                }
                
                if let currentLoc = place.location {
                    self.currentLoc = currentLoc
                }
                
                let retrievedUid: String? = String(NSUserDefaults.standardUserDefaults().objectForKey(KEY_UID)!)
                
                let randomInt = Int(arc4random_uniform(10000))
                
                if let uidStr = retrievedUid {
                    DataService.ds.REF_USERS.childByAppendingPath("/\(uidStr)").updateChildValues(["addressId": self.currentAddressId, "blah": randomInt])
                }
                
            } else if error != nil {
                print("ERROR FETCHING PLACE: \(error.debugDescription)")
            } else {
                print("NO ERROR, BUT PLACE COULD NOT BE FOUND")
            }
        }
        
        prevAddressId = currentAddressId
    }
    
    @IBAction func getLocation(sender: UIButton) {
        
        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(self.requestPlaceAndPushStreetAddressId), userInfo: nil, repeats: true)
    }
    
    func setupObserver() {
        
        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
            // CALLED ANY TIME ANY USERS INFO CHANGES
            
            //print(snapshot.value)
            //annotate for location change
            
            if let currentLoc = self.currentLoc where self.currentAddressId != self.prevAddressId {
                self.createAnnotationForLocation(currentLoc)
            }
            
            self.uids = []
            
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshots {
                    //print("snap: \(snap)")
                    
                    if let userDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        if let addressId = userDict["addressId"] as? String {
                            
                            if addressId == self.currentAddressId {
                                let uid = snap.key
                                self.uids.append(uid)
                            }
                        }
                    }
                }
                print("array of uids matching current addressId: \(self.uids)")
                //self.nearbyPeopleCountLbl.text = String(self.uids.count - 1)
                
                //create infection annotation
            }
        })
    }
    
    func createAnnotationForLocation(location: CLLocation) {
        
        let point = MGLPointAnnotation()
        point.coordinate = location.coordinate
        //point.title = "Voodoo Doughnut"
        //point.subtitle = "22 SW 3rd Avenue Portland Oregon, U.S.A."
        
        mapBox.addAnnotation(point)
        print("CREATED ANNOTATION")
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKindOfClass(ContactAnnotation) {
            let annoView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Default")
            annoView.pinTintColor = UIColor.blackColor()
            annoView.animatesDrop = true
            
            return annoView
            
        } else if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        return nil
    }
    
}
