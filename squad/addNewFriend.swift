//
//  addNewFriend.swift
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit
import OneSignal

class addNewFriend: UIViewController, UITextFieldDelegate {
    
    
    //  add constasnt commenting to the different possible outcomes
    
    
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var cancel: UIBarButtonItem!
    @IBOutlet weak var done: UIBarButtonItem!
    
    
    var sentRequest : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.becomeFirstResponder()
        done.isEnabled = false
        sentRequest = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func cancel (_ sener: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done (_ sender: AnyObject) {
        if sentRequest == false {
            attemptToSendPinRequest()
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
     //   textField.resignFirstResponder()
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField.text != "" {
            if sentRequest == false {
                attemptToSendPinRequest()
            }
        }
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = textField.text! as NSString
        let newText = oldText.replacingCharacters(in: range, with: string) as NSString
        done.isEnabled = newText.length > 0
        return true
    }
    
    
    func attemptToSendPinRequest () {
        
        sentRequest = true

        var ref: FIRDatabaseReference
        ref = FIRDatabase.database().reference().child("pins")
        
        if let enteredPin = textField.text {
            
            ref.child(enteredPin).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let result = snapshot.value as? NSDictionary
                
                
                if let uniqueId = result?.value(forKey: "uniqueId") as? String {
                    
                    
                    // success!
                    
                    // send request to friend
                    self.sendPinRequestToFriend(uniqueId: uniqueId)
                    
                    
                    // show message to user
                    let alert = UIAlertController(title: "Request Sent", message: "If they accept, they will appear on your friends list", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler:{ action in
                        
                        self.dismiss(animated: true, completion: nil)
                        })
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    
                    let alert = UIAlertController(title: "No Matches", message: "The pin you are looking for does not exist", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
                
            }) { (error) in
                print("error one")
                
                // say no match
                print(error.localizedDescription)
            }
        }
    }
    
    
    func sendPinRequestToFriend (uniqueId: String) {
        // go to users folder with tthe uniqu id

        let myPin = UserDefaults.standard.object(forKey: kPin) as! String
        
        var ref: FIRDatabaseReference
        ref = FIRDatabase.database().reference().child("users").child(uniqueId).child("friendRequests").child(myPin)
        
        let formatter = Constants.internetTimeDateFormatter()
        let dictionary: NSDictionary = [
            "Date" : formatter!.string(from: Date.init())
        ]
        
        ref.setValue(dictionary) { (error, ref) in
            
            if error == nil {
             // add comments here
                
                
                // send the push notificaiotn!
                let friendPushPath = FIRDatabase.database().reference().child("users").child(uniqueId).child("pushId")
                friendPushPath.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let friendPushInfoDictionary = snapshot.value as? NSDictionary {
                        
                        if let friendPushIdString = friendPushInfoDictionary["userId"] as? String {
                            
                            let title = "New Friend Request"
                            let senderPin = "From Pin: \(myPin)"
                            
                            OneSignal.postNotification(["contents": ["en": senderPin], "headings": ["en": title], "include_player_ids": [friendPushIdString], "content_available" : true])
                        }
                    }
                })
                
            } else {
                // add comments here
            }
        }
        
        // double check that the user reall exists?? ro jsut go and write the request...? I'm skipign the double check... for now
        /*
        ref.child(uniqueId).observeSingleEvent(of: .value, with: { (snapshot) in
        
            let result = snapshot.value
            if let
        })
        */
    }
}
