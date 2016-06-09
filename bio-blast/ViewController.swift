//
//  ViewController.swift
//  bio-blast
//
//  Created by Alex Bussan on 5/29/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var addressIdLbl: UILabel!
    @IBOutlet weak var placeLbl: UILabel!
    @IBOutlet weak var coordsLbl: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nearbyPeopleCountLbl: UILabel!
    
    var currentPlaceStr: String = ""
    var currentAddressId: String = ""
    var prevAddressId: String = ""
    
    var currentLoc: CLLocation?
    
    let locationManager = LKLocationManager()
    let regionRadius: CLLocationDistance = 250
    
    var uids: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.requestAlwaysAuthorization()
        
        locationManager.debug = true
        locationManager.apiToken = "21292208b912cf86"
        locationManager.startUpdatingLocation()
        
        map.delegate = self
        map.showsUserLocation = true
        setupObserver()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func requestPlaceAndPushStreetAddressId() {
        
        locationManager.requestPlace { (place: LKPlacemark?, error: NSError?) -> Void in
            if let place = place {
                self.currentPlaceStr = "\(place)"
                
                if let addressId = place.addressId {
                    self.currentAddressId = addressId
                } else {
                    print("NO ADDRESS ID")
                }
                
                self.addressIdLbl.text = "\(self.currentAddressId)"
                
                if let currentLoc = place.location {
                    self.currentLoc = currentLoc
                }
                
                
                let retrievedUid: String? = String(NSUserDefaults.standardUserDefaults().objectForKey(KEY_UID)!)
                
                let randomInt = Int(arc4random_uniform(10000))
                
                if let uidStr = retrievedUid {
                    DataService.ds.REF_USERS.childByAppendingPath("/\(uidStr)").updateChildValues(["addressId": self.currentAddressId, "blah": randomInt])
                }
                
                
                self.placeLbl.text = self.currentPlaceStr
                self.coordsLbl.text = "\(place.location!.coordinate.latitude), \(place.location!.coordinate.longitude)"
                
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
        
        locationManager.requestLocation { (location: CLLocation?, error: NSError?) -> Void in
            if let loc = location {
                self.centerMapOnLocation(loc)
            } else {
                print("ERROR FETCHING LOCATION: \(error.debugDescription)")
            }
        }
        
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coorinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2, regionRadius * 2)
        map.setRegion(coorinateRegion, animated: true)
    }
    
    func setupObserver() {
        
        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
            
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
                                //if let currentLoc = self.currentLoc {
                                    //annotate for contact event
                                    //self.createAnnotationForLocation(currentLoc)
                                //}
                            }
                        }
                        
                        //let post = Post(postKey: key, dictionary: postDict)
                        //self.posts.append(post)
                    }
                }
                print("array of uids matching current addressId: \(self.uids)")
                self.nearbyPeopleCountLbl.text = String(self.uids.count - 1)
                
                //create infection annotation
                
            }
        })
    }
    
    func createAnnotationForLocation(location: CLLocation) {
        let bootcamp = ContactAnnotation(coordinate: location.coordinate)
        map.addAnnotation(bootcamp)
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

