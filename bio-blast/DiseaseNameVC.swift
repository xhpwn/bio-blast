//
//  DiseaseNameVC.swift
//  bio-blast
//
//  Created by Alex Bussan on 7/7/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import UIKit

class DiseaseNameVC: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var diseaseNameTextFld: UITextField!

    var UID = ""
    var diseaseName = ""
    
    override func viewDidLoad() {

        super.viewDidLoad()
        diseaseNameTextFld.delegate = self
        setUID()

        //FIX : how this is done
        
        DataService.ds.REF_USERS.childByAppendingPath("/\(UID)/DiseaseName").observeSingleEventOfType(.Value, withBlock: { diseaseName in
            
            if diseaseName.exists() {
                NSUserDefaults.standardUserDefaults().setValue(self.diseaseName, forKey: "diseaseName")
                self.performSegueWithIdentifier("toMap", sender: nil)
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if NSUserDefaults.standardUserDefaults().valueForKey("diseaseName") != nil {
            
            self.performSegueWithIdentifier("toMap", sender: nil)
        }
        
        diseaseNameTextFld.becomeFirstResponder()
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //read from textfield
        diseaseName = diseaseNameTextFld.text!
        print(diseaseName)
        
        //send self diseaseName to Firebase
        DataService.ds.REF_USERS.childByAppendingPath("/\(UID)").updateChildValues(["DiseaseName":diseaseName])
        
        DataService.ds.REF_USERS.childByAppendingPath("/\(UID)/diseases").updateChildValues([UID:diseaseName])
        
        //Set default so we don't come back to this (self) VC again
        NSUserDefaults.standardUserDefaults().setValue(diseaseName, forKey: "diseaseName")
        
        //segue to next view
        performSegueWithIdentifier("toMap", sender: nil)
        
        return true
    }
    
    func setUID() {
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)
        
        if let uid = uid {
            UID = uid as! String
            print("UIDfromDiseaseNameVC: \(uid)")
        }
    }

}
