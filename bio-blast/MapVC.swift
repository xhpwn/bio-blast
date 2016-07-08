//
//  MapVC.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/3/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

//ADD
//circle annotations to show other nearby users
//turn off observer in background, possibly make single calls in loop for foreground
//find place on initial install startup
//persist numInfected / annotations
//random disease name generator
//create prompt to name disease
//implement DNA points
//just start with local location view? as opposed to zooming in?.. zoom +/- buttons, or popdown sider?

//use actual disease names

//BUGS 

//verify name and deviceID
//self.name in other users is different


//make location options/ turn off arrow when app closes
//look into beta service

//ESSENTIAL
//automate processes
//enter disease name
//if firebase acct already created, do not push the starting user dict

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
    @IBOutlet weak var dnaPointsLbl: UILabel!
    
    var namesString = ""
    var stopSettingCenter = false
    var shouldCreateContactAnnotation = true
    
    
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
    
    var currentLoc: CLLocation?
    var currentCenter: CLLocationCoordinate2D?
    
    let locationManager = LKLocationManager()
    let GET_PLACE_AND_PUSH_INTERVAL: Double = 5
    
    var sameAddressUids: [String] = []
    var collectedUids: [String] = []
    var numInfected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapBox.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        mapBox.delegate = self
        mapBox.tintColor = UIColor(red: 180/255, green: 45/255, blue: 58/255, alpha: 1)
        
        //set initial map viewpoint
        //let center = CLLocationCoordinate2D(latitude: 40.4269646, longitude: -86.9182388)
        //mapBox.setCenterCoordinate(center, zoomLevel: 2, dirsection: 0, animated: false)
        
        locationManager.debug = true
        locationManager.apiToken = "21292208b912cf86"
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)
        
        if let uid = uid {
            UID = uid as! String
            print("UID: \(uid)")
        }
        
        let userValuesDict = ["name": UID] as [NSObject: AnyObject]
        
        locationManager.setUserValues(userValuesDict)
        
        locationManager.advancedDelegate = self
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringVisits()
        
        listenForInfectionCredits()
        
        _ = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(self.stopSettingCenterCoord), userInfo: nil, repeats: false)
        
        
    }
    @IBAction func peopleBtn(sender: AnyObject) {
        simplePeopleNearby()
    }
    
    func simplePeopleNearby() {     //looks for people nearby, and prints, just for debugging
        locationManager.requestPeopleNearby{ (people: [LKPerson]?, error: NSError?) -> Void in
        
            if let people = people {
                for person in people {
                    print("PERSON NEARBY: \(person.name)")
                }
            }
        }
    }
    
    @IBAction func zoomOut(sender: AnyObject) {
        let center = CLLocationCoordinate2D(latitude: 40.4269646, longitude: -86.9182388)
        mapBox.setCenterCoordinate(center, zoomLevel: 0, direction: 0, animated: false)
    }
    
    func zoomToCurrentLocation() {
        let center = CLLocationCoordinate2D(latitude: currentLoc!.coordinate.latitude, longitude: currentLoc!.coordinate.longitude) //could have error?
        mapBox.setCenterCoordinate(center, zoomLevel: 14, direction: 0, animated: false)
    }
    
    @IBAction func zoomIn(sender: AnyObject) {
        zoomToCurrentLocation()
    }
    func startTestingPeopleNearby() {
        
        //grab all people nearby and put them into an array
        
        locationManager.requestPeopleNearby { (people: [LKPerson]?, error: NSError?) -> Void in
            
            if let people = people {    //what if no people nearby? still need to update? no?
                
                //grabs self.diseases from firebase
                DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/diseases").observeSingleEventOfType(FEventType.Value, withBlock: { diseaseDict in
                    
                    if let diseaseDict = diseaseDict.value as? Dictionary<String, String> {
                        self.diseaseDict = diseaseDict
                        print("INITIALLY RETRIEVED SELF.DISEASES: \(self.diseaseDict)")
                    }
                    
                    self.oldDiseaseDict = self.diseaseDict  //capture oldDiseaseDict
                    
                    //loop through people nearby and check if they are in self.diseasDict, if not, add them
                    
                    self.shouldCreateContactAnnotation = true
                    
                    for person in people {

                        let uid = person.name
                        
                            print("UID NEARBY: \(uid)")

                            let shouldAdd = true    //test ifActive in future?
                            
                            if shouldAdd {
                                
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
                                        //self.namesLbl.text = self.diseaseDict.description
                                        self.dnaPointsLbl.text = String(self.diseaseDict.count)
                                        
                                        //now loop through what was added
                                        for (key, _) in self.diseaseDictCopy {
                                            
                                            //credit these uids with an infection
                                            //which means add of self.uid entry to this uid's infected dict
                                            
                                            DataService.ds.REF_USERS.childByAppendingPath("/\(key)/hasInfected").updateChildValues([self.UID:"self disease name"])
                                        }
                                        
                                        self.totalInfectedLbl.text = String(self.infectedDict.count)
                                    }
                                })
                                
                                if self.shouldCreateContactAnnotation  {
                                    self.createAnnotationForCoord(person.location)
                                }
                                
                                self.shouldCreateContactAnnotation = false
                            }
                    }
                    
                    print("OUTSIDE OF CLOSURE, SELF.DISEASES: \(self.diseaseDict)")

                    self.totalInfectedLbl.text = String(self.infectedDict.count)
                    
                })
            }
        }
    }
    
    
    func listenForInfectionCredits() {
        DataService.ds.REF_USERS.childByAppendingPath("/\(self.UID)/hasInfected").observeEventType(.Value, withBlock: {infectedDict in
            
            print("observed")
            
            if let infectedDict = infectedDict.value as? Dictionary<String, String> {
                self.infectedDict = infectedDict
                print(self.infectedDict)
                self.totalInfectedLbl.text = String(self.infectedDict.count) //also in people nearby
            }
            
        })
    }

    
    func zoomCameraToCurrentCenter() {
        print("q")
        if let currentCenter = currentCenter {
            print("r")
            let camera = MGLMapCamera(lookingAtCenterCoordinate: currentCenter, fromDistance: 30000, pitch: 0, heading: 0)
            
            mapBox.setCamera(camera, withDuration: 3, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            //polygonCircleForCoordinate(currentCenter, withMeterRadius: 500)
        }
    }
    
    func locationManager(manager: LKLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if LKLocationManager.locationServicesEnabled() {
            switch(LKLocationManager.authorizationStatus()) {
            case .NotDetermined, .Restricted, .Denied:
                print("No access")
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                print("Access")
                _ = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.zoomToCurrentLocation), userInfo: nil, repeats: false)
                
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
    
    func mapViewDidFinishLoadingMap(mapBox: MGLMapView) {
        
        loadingBlanket.hidden = true
    }
    
    @IBAction func startLookingNearby(sender: UIButton) {
//        startRequestingPeopleNearby()
//        _ = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(self.startRequestingPeopleNearby), userInfo: nil, repeats: true)
        
        startTestingPeopleNearby()
    }

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
