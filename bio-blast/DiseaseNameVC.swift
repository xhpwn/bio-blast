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
        
        DataService.ds.REF_USERS.childByAppendingPath("/\(UID)/DiseaseName").observeSingleEventOfType(.Value, withBlock: { diseaseName in
            
            if diseaseName.exists() {
                self.performSegueWithIdentifier("toMap", sender: nil)
            }
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //read from textfield
        diseaseName = diseaseNameTextFld.text!
        print(diseaseName)
        
        //send self diseaseName to Firebase
        DataService.ds.REF_USERS.childByAppendingPath("/\(UID)").updateChildValues(["DiseaseName":diseaseName])
        
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
