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
                        
                        let diseaseDict = [authData.uid: "Steve Disease"]
                        let user = ["isActive": "true", "diseases": diseaseDict as Dictionary<String, AnyObject>, "provider": authData.provider!]
                        
                        DataService.ds.createFireBaseUser(authData.uid, user: user as! Dictionary<String, AnyObject>)
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
                
            }
            
//            facebookLogin.logOut()
//            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: KEY_UID)
        }
    }
    


}
