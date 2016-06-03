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
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
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
                        
                        let diseaseDict = ["0": "adsgdfg", "1": "fghfg"]
                        let user = ["isActive": "true", "addressId": "sdfhsd", "diseases": diseaseDict as AnyObject, "provider": authData.provider!, "blah": "test"]
                        
                        DataService.ds.createFireBaseUser(authData.uid, user: user)
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
                
            }
        }
    }
    


}
