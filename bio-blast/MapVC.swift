//
//  MapVC.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/3/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

//ADD
//circle annotations to show other nearby users
//zoom buttons on top bar, one to jump local, one world view
//use place for annotation location
//turn off observer in background, possibly make single calls in loop for foreground
//apply to Spotify
//find place on initial install startup
//persist numInfected / annotations
//random disease name generator
//create prompt to name disease

//BUGS 

//verify name and deviceID
//self.name in other users is different
//allow A to C passing
//right now we're showing how many people have infected YOU, we need to show how many people self has infected

//implement disease spreading mechanic, allows for seeing who infected you/3rd party pass

//make location options/ turn off arrow when app closes
//look into beta service

import UIKit
import MapKit
import Firebase
import Mapbox
import CoreLocation
import FBSDKCoreKit
import FBSDKLoginKit

class MapVC: UIViewController, MGLMapViewDelegate, LKLocationManagerDelegate {
    
    @IBOutlet weak var mapBox: MGLMapView!
    @IBOutlet weak var loadingBlanket: UIView!
    @IBOutlet weak var totalInfectedLbl: UILabel!
    @IBOutlet weak var namesLbl: UILabel!
    var namesString = ""
    var stopSettingCenter = false
    var shouldCreateContactAnnotation = true
    
    @IBOutlet weak var dnaPointsLbl: UILabel!
    var currentPlaceStr: String = ""
    var currentAddressId: String = ""
    var prevAddressId: String = ""
    var firstAnnotation = true
    var firstObserver = true
    var UID = ""
    var diseaseDict: Dictionary<String,String> = ["":""]
    var diseaseDictCopy: Dictionary<String,String> = ["":""]
    var oldDiseaseDict: Dictionary<String,String> = ["":""]
    var infectedDict: Dictionary<String, String> = ["":""]
    
    var diseases: [String] = []
    //var firstRun = NSUserdefaults
    
    var currentLoc: CLLocation?
    var currentCenter: CLLocationCoordinate2D?
    
    let locationManager = LKLocationManager()
    //let ClLocationManager = LKLocationManager()
    let GET_PLACE_AND_PUSH_INTERVAL: Double = 5
    
    var sameAddressUids: [String] = []
    var collectedUids: [String] = []
    var numInfected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenForInfectionCredits()
        
        //        ClLocationManager.delegate = self
//        ClLocationManager.desiredAccuracy = kCLLocationAccuracyBest
//        ClLocationManager.requestWhenInUseAuthorization()
//        ClLocationManager.startUpdatingLocation()
        
        mapBox.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        mapBox.delegate = self
        mapBox.tintColor = UIColor(red: 180/255, green: 45/255, blue: 58/255, alpha: 1)
        
        
        //FIX
        
        //let center = CLLocationCoordinate2D(latitude: 40.4269646, longitude: -86.9182388)
        //mapBox.setCenterCoordinate(center, zoomLevel: 2, dirsection: 0, animated: false)
        
        locationManager.debug = true
        locationManager.apiToken = "21292208b912cf86"
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)
        
        if let uid = uid {
            UID = uid as! String
            print("UID: \(uid)")
        }
        
        print(UID)
        let userValuesDict = ["name": UID] as [NSObject: AnyObject]
        
        locationManager.setUserValues(userValuesDict)
        
        locationManager.advancedDelegate = self
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringVisits()
        
        _ = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(self.stopSettingCenterCoord), userInfo: nil, repeats: false)
        
    
        
    }
    
    func mapView(mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 180/255, green: 45/255, blue: 58/255, alpha: 1)
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    }
    
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.2
    }
    
    
    func startTestingPeopleNearby() {
        
        //grab all people nearby and put them into an array
        
        locationManager.requestPeopleNearby { (people: [LKPerson]?, error: NSError?) -> Void in

                //grabs self.diseases from firebase      //what if no people nearby? still need to update?
                
                DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/diseases").observeSingleEventOfType(FEventType.Value, withBlock: { diseaseDict in
                    
                    if let diseaseDict = diseaseDict.value as? Dictionary<String, String> {
                        self.diseaseDict = diseaseDict
                        print("INITIALLY RETRIEVED SELF.DISEASES: \(self.diseaseDict)")
                    }
                    
                    self.oldDiseaseDict = self.diseaseDict  //capture oldDiseaseDict
                    
                    //loop through people nearby and check if they are in self.diseasDict, if not, add them
                    
                    self.shouldCreateContactAnnotation = true
                    
                    //TEST DATA
                    let testPeople = ["facebook:117882401968744", "testuid1"]       //use legit uids, these uids must have correct firebase model too
                    
                    for person in testPeople {

                        let uid = person       //also set personID or device ID
                            //print("UID NEARBY: \(uid)")

                            let shouldAdd = true
                            
                            if shouldAdd {
                                
                                //self.oldDiseaseDict = self.diseaseDict  //capture oldDiseaseDict
                                
                                print("OLD SELF DISEASE DICT1: \(self.oldDiseaseDict)")
                                
                                DataService.ds.REF_USERS.childByAppendingPath("/\(uid)/diseases").observeSingleEventOfType(.Value, withBlock: {
                                    uidDiseaseDict in
                                    
                                    if let uidDiseaseDict = uidDiseaseDict.value as? Dictionary<String, String> {
                                        
                                        print("DISEASES FOR \(uid): \(uidDiseaseDict)")
                                        
                                        // merging uidDiseaseDict into self.diseaseDict
                                        
                                        self.diseaseDict.unionInPlace(uidDiseaseDict)   //self.diseaseDict has been changed
                                        
                                        print("AFTER UNION: \(self.diseaseDict)")
                                        
                                        self.diseaseDictCopy = self.diseaseDict
                                        
                                        
                                        print("OLD SELF DISEASE DICT2: \(self.oldDiseaseDict)")
                                        self.diseaseDictCopy.subtractThis(self.oldDiseaseDict)  //now we have the new - orig, show what was just added
                                        
                                        self.oldDiseaseDict = self.diseaseDict  //capture oldDiseaseDict
                                        print("OLD SELF DISEASE DICT3: \(self.oldDiseaseDict)")
                                        
                                        print("THESE WERE ADDED: \(self.diseaseDictCopy)")
                                        
                                        //update self.diseases on firebase (after each merge)..
                                        
                                        DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/diseases").setValue(self.diseaseDict)
                                        self.namesLbl.text = self.diseaseDict.description
                                        self.dnaPointsLbl.text = String(self.diseaseDict.count)
                                        
                                        //now loop through what was added
                                        for (key, _) in self.diseaseDictCopy {
                                            
                                            //credit these uids with an infection
                                            //which means add of self.uid entry to this uid's infected dict
                                            
                                            //observe single event on dict, add entry, then set value
                                            
                                            DataService.ds.REF_USERS.childByAppendingPath("/\(key)/hasInfected").setValue([self.UID:"self disease name"])
                                            
                                            //may be overwritten ! if more than one user crediting to this uid.. FIX
                                        }
                                        
                                        self.totalInfectedLbl.text = String(self.infectedDict.count)
                                    }
                                })
                                
                                if self.shouldCreateContactAnnotation {
                                    //FIX: this loc is hardcoded .. should be person.location
                                    self.createAnnotationForCoord(CLLocationCoordinate2D(latitude: 40.4269646, longitude: -86.9182388))
                                }
                                
                                self.shouldCreateContactAnnotation = false
                            }
                    }
                    
                    print("OUTSIDE OF CLOSURE, SELF.DISEASES: \(self.diseaseDict)")
                    
                    
                    self.totalInfectedLbl.text = String(self.infectedDict.count)
                    
                })
        }
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //    func polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) {
//        let degreesBetweenPoints = 8.0
//        //45 sides
//        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
//        let distRadians: Double = withMeterRadius / 6371000.0
//        // earth radius in meters
//        let centerLatRadians: Double = coordinate.latitude * M_PI / 180
//        let centerLonRadians: Double = coordinate.longitude * M_PI / 180
//        var coordinates = [CLLocationCoordinate2D]()
//        //array to hold all the points
//        for index in 0 ..< Int(numberOfPoints) {
//            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
//            let degreeRadians: Double = degrees * M_PI / 180
//            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
//            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
//            let pointLat: Double = pointLatRadians * 180 / M_PI
//            let pointLon: Double = pointLonRadians * 180 / M_PI
//            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
//            coordinates.append(point)
//        }
//        let polygon = MGLPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
//        
//        
//        self.mapBox.addAnnotation(polygon)
//    }
    
    func zoomCameraToCurrentCenter() {
        print("q")
        if let currentCenter = currentCenter {
            print("r")
            let camera = MGLMapCamera(lookingAtCenterCoordinate: currentCenter, fromDistance: 30000, pitch: 0, heading: 0)
            
            mapBox.setCamera(camera, withDuration: 3, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            //polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
        }
    }
    
//    func startPushingandPulling() {
//        requestPlaceAndPushStreetAddressId()
//        NSTimer.scheduledTimerWithTimeInterval(GET_PLACE_AND_PUSH_INTERVAL, target: self, selector: #selector(self.requestPlaceAndPushStreetAddressId), userInfo: nil, repeats: true)
//        
//        
//    }
    
    func locationManager(manager: LKLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if LKLocationManager.locationServicesEnabled() {
            switch(LKLocationManager.authorizationStatus()) {
            case .NotDetermined, .Restricted, .Denied:
                print("No access")
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                print("Access")
                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.zoomCameraToCurrentCenter), userInfo: nil, repeats: false)
                
                //_ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.startPushingandPulling), userInfo: nil, repeats: false)
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    func stopSettingCenterCoord() {
        stopSettingCenter = true
    }
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLoc = locations.first {
            self.currentLoc = currentLoc
            
            if stopSettingCenter == false {
                self.currentCenter = CLLocationCoordinate2D(latitude: currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude)
                print(self.currentCenter)
            }
            
        }
    }
    
//        func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//        
//        
//        if CLLocationManager.locationServicesEnabled() {
//            switch(CLLocationManager.authorizationStatus()) {
//            case .NotDetermined, .Restricted, .Denied:
//                print("No access")
//            case .AuthorizedAlways, .AuthorizedWhenInUse:
//                print("Access")
//                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.zoomCameraToCurrentCenter), userInfo: nil, repeats: false)
//                
//                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.startPushingandPulling), userInfo: nil, repeats: false)
//            }
//        } else {
//            print("Location services are not enabled")
//        }
//    }
//    
//    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        
//        if let currentLoc = locations.first {
//            self.currentLoc = currentLoc
//            
//            self.currentCenter = CLLocationCoordinate2D(latitude: currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude)
//            print(self.currentCenter)
//            
//            ClLocationManager.stopUpdatingLocation()
//        }
//    }
    
    func mapViewDidFinishLoadingMap(mapBox: MGLMapView) {
        
        loadingBlanket.hidden = true
    }
    
//    func requestPlaceAndPushStreetAddressId() {
//        
//        locationManager.requestLocation { (location: CLLocation?, error: NSError?) -> Void in
//            // We have to make sure the location is set, could be nil
//            if let location = location {
//                print("You are currently at: \(location)")
//            }
//        }
//        
//        locationManager.requestPlace { (place: LKPlacemark?, error: NSError?) -> Void in
//            if let place = place {
//                
//                self.currentPlaceStr = "\(place)"
//                print(self.currentPlaceStr)
//                
//                if let addressId = place.addressId {
//                    self.currentAddressId = addressId
//                    print("d")
//                } else {
//                    print("NO ADDRESS ID")
//                }
//                
//                if let currentLoc = place.location {
//                    self.currentLoc = currentLoc
//                }
//                
//                let retrievedUid: String? = String(NSUserDefaults.standardUserDefaults().objectForKey(KEY_UID)!)
//                
//                if let uidStr = retrievedUid {
//                    DataService.ds.REF_USERS.childByAppendingPath("/\(uidStr)").updateChildValues(["addressId": self.currentAddressId])
//                }
//                
//            } else if error != nil {
//                print("ERROR FETCHING PLACE: \(error.debugDescription)")
//            } else {
//                print("NO ERROR, BUT PLACE COULD NOT BE FOUND")
//            }
//            
//            if let currentLoc = self.currentLoc where self.currentAddressId != self.prevAddressId {
//                //FIX
//                //self.createAnnotationForLocation(currentLoc)
//                
//                self.polygonCircleForCoordinate(CLLocationCoordinate2D(latitude: currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude), withMeterRadius: 500)
//            }
//            
//            if self.firstAnnotation == false {
//                self.prevAddressId = self.currentAddressId
//                print("a")
//            } else {
//                self.firstAnnotation = false
//                print("b")
//            }
//            
//            if self.firstObserver == true {
//                self.setupObserver()
//                self.firstObserver = false
//            }
//        }
//    }
    
    func listenForInfectionCredits() {
        DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/infected").observeEventType(.Value, withBlock: {infectedDict in
        
            if let infectedDict = infectedDict.value as? Dictionary<String, String> {
                self.infectedDict = infectedDict
                print(self.infectedDict)
            }
        
        })
    }
    
    func startRequestingPeopleNearby() {
        
        //grab all people nearby and put them into an array
        
        
        locationManager.requestPeopleNearby { (people: [LKPerson]?, error: NSError?) -> Void in
            if let people = people {
                print("There are \(people.count) other users of this app nearby you")
                
                //grabs self.diseases from firebase      //what if no people nearby? still need to update
                
                DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/diseases").observeSingleEventOfType(FEventType.Value, withBlock: { diseaseDict in
                    
                    if let diseaseDict = diseaseDict.value as? Dictionary<String, String> {
                        self.diseaseDict = diseaseDict
                        print(self.diseaseDict)
                    }
                    
                //loop through people nearby and check if they are in self.diseasDict, if not, add them
                    
                    self.shouldCreateContactAnnotation = true
                    
                    for person in people {
                        
                        if let uid = person.name {      //also set personID or device ID
                            print("UID NEARBY: \(uid)")
                            
                            //returns true if we need to add this uid to self.diseaseDict
                            //** not only should we add this uid, but we need to add it's diseaseDict as well!
                            //** shouldn't we always do that too? or time limit
                            let shouldAdd = true        //self.diseaseDict[uid] == nil   FIX
                                
                            if shouldAdd {
                                
                                self.oldDiseaseDict = self.diseaseDict  //capture oldDiseaseDict
                                
                                DataService.ds.REF_USERS.childByAppendingPath("/\(uid)/diseases").observeSingleEventOfType(.Value, withBlock: {
                                    uidDiseaseDict in
                                
                                    if let uidDiseaseDict = uidDiseaseDict.value as? Dictionary<String, String> {
                                        
                                        
                                        print("Disease dict for uid \(uid): \(uidDiseaseDict)")
                                        
                                        // merge uidDiseaseDict into self.diseaseDict
                                        
                                        self.diseaseDict.unionInPlace(uidDiseaseDict)   //self.diseaseDict has been changed
                                        self.diseaseDictCopy = self.diseaseDict
                                        
                                        self.diseaseDictCopy.subtractThis(self.oldDiseaseDict)  //now we have the new - orig, show what was just added
                                        
                                        //now loop through what was added
                                        for (key, _) in self.diseaseDictCopy {
                                            
                                            //credit these uids with an infection
                                            //which means add of self.uid entry to this uid's infected dict
                                            
                                            DataService.ds.REF_USERS.childByAppendingPath("/\(key)/diseases").childByAutoId().setValue([self.UID:"self disease name"])
                                            
                                        }
                                    }
                                })
                                
                                
                                if self.shouldCreateContactAnnotation {
                                    self.createAnnotationForCoord(person.location)
                                }
                                
                                self.shouldCreateContactAnnotation = false
                            }
                        }
                    }
                    
                    print(self.diseaseDict)
                    self.namesLbl.text = self.diseaseDict.description
                    self.dnaPointsLbl.text = String(self.diseaseDict.count)
                    self.namesLbl.text = String(self.infectedDict.count)
                    
                    //write self.diseasedict back to firebase
                    DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/diseases").setValue(self.diseaseDict)
                
                })
                
                
            } else {
                print("Sorry, no other users of this app found nearby you")
            }
            
            //self.locationManager.stopMonitoringVisits()
        }
        
        
        
    }
    
    @IBAction func getLocation(sender: UIButton) {
//        startRequestingPeopleNearby()
//        _ = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(self.startRequestingPeopleNearby), userInfo: nil, repeats: true)
        
        startTestingPeopleNearby()
    }
    
//    func setupObserver() {
//        
//        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
//            // CALLED ANY TIME ANY USER'S INFO CHANGES
//            
//            //print(snapshot.value)
//            
//            self.sameAddressUids = []
//            
//            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
//                for snap in snapshots {
//                    //print("snap: \(snap)")
//                    
//                    if let userDict = snap.value as? Dictionary<String, AnyObject> {
//                        
//                        if let addressId = userDict["addressId"] as? String {
//                            
//                            if addressId == self.currentAddressId {
//                                let uid = snap.key
//                                self.sameAddressUids.append(uid)
//                                
//                                //grab snap's diseaseArray
//                                let snapDiseaseArray = userDict["diseases"] as? Dictionary<String, AnyObject>
//                                
//                                //add self diseaseArray to snap's diseaseArray
//                                //Stackoverflow solution to add 2 dictionaries
//                                
//                                
//                                //set updated value of snap's diseaseArray
//                                DataService.ds.REF_USERS.childByAppendingPath("/\(uid)/diseases").setValue(snapDiseaseArray)
//                            
//                            }
//                        }
//                    }
//                }
//                print("array of uids matching current addressId: \(self.sameAddressUids)")
//                
//                //checks for any new uids that are nearby and adds them to self's diseaseArray
//                
//                for uid in self.sameAddressUids {
//                    if self.collectedUids.contains(uid) {
//                        print("disregard")
//                    } else {
//                        self.collectedUids.append(uid)
//                        
//                        //create infection annotation
//                        if let currentCenter = self.currentCenter {
//                            self.polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
//                        }
//                        
//                    }
//                }
//                
//                print("TOTAL INFECTED: \(self.collectedUids.count)")
//                self.totalInfectedLbl.text = "\(self.collectedUids.count)"
//            }
//        })
//    }
    
    func createAnnotationForCoord(coord: CLLocationCoordinate2D) {
        
        let point = MGLPointAnnotation()
        point.coordinate = coord    //location.coordinate
        //point.title = "Voodoo Doughnut"
        //point.subtitle = "22 SW 3rd Avenue Portland Oregon, U.S.A."
        
        mapBox.addAnnotation(point)
        print("CREATED ANNOTATION")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
}
