//
//  LoginVC.swift
//  bio-blast
//
//  Created by Alex Bussan on 5/30/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class LoginVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        locationManager.requestAlwaysAuthorization()
//        locationManager.debug = true
//        locationManager.apiToken = "21292208b912cf86"
//        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print(NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID))
        
        //Determine which VC to segue to initially, initally, if any
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    
    }
    

//        FBSDKLoginManager().logOut()
//        DataService.ds.REF_BASE.unauth()


    @IBAction func fbBtnPressed(sender: UIButton) {
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
                //also make popup notification
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with facebook! \(accessToken)")
                
                
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: {error, authData in
                    
                    if error != nil {
                        print("login failed \(error)")
                    } else {
                        print("logged in!\(authData)")
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        
                        // if there is no existing firebase data for this UID, then create new user
                        DataService.ds.REF_USERS.childByAppendingPath("/\(authData.uid)/isActive").observeSingleEventOfType(.Value, withBlock: { active in
                            
                            if !active.exists() {
                                let diseaseDict = [authData.uid: "stev diseas"]
                                let infectedDict = [authData.uid:"name of disease"]
                                
                                let user = ["isActive": "true", "diseases": diseaseDict as Dictionary<String, AnyObject>, "hasInfected": infectedDict as Dictionary<String, AnyObject>, "provider": authData.provider!]
                                
                                DataService.ds.createFireBaseUser(authData.uid, user: user as! Dictionary<String, AnyObject>)
                            }
                        })
                        
                        //self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                        
                        //grab user info
                        
                        let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken, version: nil, HTTPMethod: "GET")
                        req.startWithCompletionHandler({ (connection, result, error : NSError!) -> Void in
                            if(error == nil)
                            {
                                print("result \(result)")
                                
                                if let FBInfoDict = result as? Dictionary<String, String> {
                                    print("GO")
                                    
                                    if let FBUserName = FBInfoDict["name"] {
                                        print(FBUserName)
                                        NSUserDefaults.standardUserDefaults().setValue(FBUserName, forKey: "FBUserName")
                                        DataService.ds.REF_USERS.childByAppendingPath("/\(authData.uid)").updateChildValues(["FBUserName":FBUserName])
                                        
                                        //.updateChildValues(["FBUserName":FBUserName])
                                    }
                                }
                            }
                            else
                            {
                                print("error \(error)")
                            }
                        })
                        
                        //Move to next view
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
            }
//            facebookLogin.logOut()
//            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: KEY_UID)
        }
    }
}
