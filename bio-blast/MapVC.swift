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
import CoreLocation

class MapVC: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapBox: MGLMapView!
    @IBOutlet weak var loadingBlanket: UIView!
    @IBOutlet weak var totalInfectedLbl: UILabel!
    
    var currentPlaceStr: String = ""
    var currentAddressId: String = ""
    var prevAddressId: String = ""
    var firstAnnotation = true
    var firstObserver = true
    //var firstRun = NSUserdefaults
    
    var currentLoc: CLLocation?
    var currentCenter: CLLocationCoordinate2D?
    
    let locationManager = LKLocationManager()
    let ClLocationManager = CLLocationManager()
    let GET_PLACE_AND_PUSH_INTERVAL: Double = 5
    
    var sameAddressUids: [String] = []
    var collectedUids: [String] = []
    var numInfected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ClLocationManager.delegate = self
        ClLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        ClLocationManager.requestWhenInUseAuthorization()
        ClLocationManager.startUpdatingLocation()
        
        mapBox.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        mapBox.delegate = self
        mapBox.tintColor = UIColor.redColor()
        
        
        //FIX
        
        //let center = CLLocationCoordinate2D(latitude: 42.22154654, longitude: -88.22007143)
        //mapBox.setCenterCoordinate(center, zoomLevel: 2, direction: 0, animated: false)
        
        locationManager.debug = true
        locationManager.apiToken = "21292208b912cf86"
        locationManager.startUpdatingLocation()
        
    }
    
    func mapView(mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 180/255, green: 45/255, blue: 58/255, alpha: 1)
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor(red: 255/255, green: 45/255, blue: 58/255, alpha: 1)
    }
    
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.2
    }
    
    func polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) {
        let degreesBetweenPoints = 8.0
        //45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / 6371000.0
        // earth radius in meters
        let centerLatRadians: Double = coordinate.latitude * M_PI / 180
        let centerLonRadians: Double = coordinate.longitude * M_PI / 180
        var coordinates = [CLLocationCoordinate2D]()
        //array to hold all the points
        for var index = 0; index < Int(numberOfPoints); index++ {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * M_PI / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / M_PI
            let pointLon: Double = pointLonRadians * 180 / M_PI
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            coordinates.append(point)
        }
        let polygon = MGLPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
        
        
        self.mapBox.addAnnotation(polygon)
    }
    
    func zoomCameraToCurrentCenter() {
        print("q")
        if let currentCenter = currentCenter {
            print("r")
            let camera = MGLMapCamera(lookingAtCenterCoordinate: currentCenter, fromDistance: 30000, pitch: 0, heading: 0)
            
            mapBox.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            //polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
        }
    }
    
    func startPushingandPulling() {
        requestPlaceAndPushStreetAddressId()
        NSTimer.scheduledTimerWithTimeInterval(GET_PLACE_AND_PUSH_INTERVAL, target: self, selector: #selector(self.requestPlaceAndPushStreetAddressId), userInfo: nil, repeats: true)
        
        if firstObserver == true {
            setupObserver()
            firstObserver = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined, .Restricted, .Denied:
                print("No access")
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                print("Access")
                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.zoomCameraToCurrentCenter), userInfo: nil, repeats: false)
                
                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.startPushingandPulling), userInfo: nil, repeats: false)
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let currentLoc = locations.first {
            self.currentLoc = currentLoc
            
            self.currentCenter = CLLocationCoordinate2D(latitude: currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude)
            print(self.currentCenter)
            
            ClLocationManager.stopUpdatingLocation()
        }
    }
    
    func mapViewDidFinishLoadingMap(mapBox: MGLMapView) {
        
        loadingBlanket.hidden = true
    }
    
    func requestPlaceAndPushStreetAddressId() {
        
        locationManager.requestLocation { (location: CLLocation?, error: NSError?) -> Void in
            // We have to make sure the location is set, could be nil
            if let location = location {
                print("You are currently at: \(location)")
            }
        }
        
        locationManager.requestPlace { (place: LKPlacemark?, error: NSError?) -> Void in
            if let place = place {
                
                self.currentPlaceStr = "\(place)"
                print(self.currentPlaceStr)
                
                if let addressId = place.addressId {
                    self.currentAddressId = addressId
                    print("d")
                } else {
                    print("NO ADDRESS ID")
                }
                
                if let currentLoc = place.location {
                    self.currentLoc = currentLoc
                }
                
                let retrievedUid: String? = String(NSUserDefaults.standardUserDefaults().objectForKey(KEY_UID)!)
                
                if let uidStr = retrievedUid {
                    DataService.ds.REF_USERS.childByAppendingPath("/\(uidStr)").updateChildValues(["addressId": self.currentAddressId])
                }
                
            } else if error != nil {
                print("ERROR FETCHING PLACE: \(error.debugDescription)")
            } else {
                print("NO ERROR, BUT PLACE COULD NOT BE FOUND")
            }
            
            if let currentLoc = self.currentLoc where self.currentAddressId != self.prevAddressId {
                //FIX
                //self.createAnnotationForLocation(currentLoc)
                if let currentCenter = self.currentCenter {
                    self.polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
                }
            }
            
            if self.firstAnnotation == false {
                self.prevAddressId = self.currentAddressId
                print("a")
            } else {
                self.firstAnnotation = false
                print("b")
            }
        }
    }
    
    @IBAction func getLocation(sender: UIButton) {

    }
    
    func setupObserver() {
        
        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
            // CALLED ANY TIME ANY USER'S INFO CHANGES
            
            //print(snapshot.value)
            
            self.sameAddressUids = []
            
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshots {
                    //print("snap: \(snap)")
                    
                    if let userDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        if let addressId = userDict["addressId"] as? String {
                            
                            if addressId == self.currentAddressId {
                                let uid = snap.key
                                self.sameAddressUids.append(uid)
                                
                                //grab snap's diseaseArray
                                var snapDiseaseArray = userDict["diseases"] as? Dictionary<String, AnyObject>
                                
                                //add self diseaseArray to snap's diseaseArray
                                //Stackoverflow solution to add 2 dictionaries
                                
                                
                                //set updated value of snap's diseaseArray
                                DataService.ds.REF_USERS.childByAppendingPath("/\(uid)/diseases").setValue(snapDiseaseArray)
                            
                            }
                        }
                    }
                }
                print("array of uids matching current addressId: \(self.sameAddressUids)")
                
                //checks for any new uids that are nearby and adds them to self's diseaseArray
                
                for uid in self.sameAddressUids {
                    if self.collectedUids.contains(uid) {
                        print("disregard")
                    } else {
                        self.collectedUids.append(uid)
                        
                        //create infection annotation
                        if let currentCenter = self.currentCenter {
                            self.polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
                        }
                        
                    }
                }
                
                
                print("TOTAL INFECTED: \(self.collectedUids.count)")
                self.totalInfectedLbl.text = "Infected: \(self.collectedUids.count)"
                
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
    
}
