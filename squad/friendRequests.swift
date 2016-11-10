//
//  friendRequests.swift
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit
import OneSignal
//import Firebase


class friendRequests: UITableViewController {
    
    var items: [individualFriendRequest] = []
  
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        addPlusButton()
      
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

        self.navigationItem.title = "Friend Requests"

        let friendRequestsPath = FIRDatabase.database().reference().child("users").child(userId).child("friendRequests")
        friendRequestsPath.observe(.value, with: { snapshot in
            var newItems: [individualFriendRequest] = []
            
            for item in snapshot.children {
                let requestItem = individualFriendRequest(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            self.items = newItems
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let requestItem = items[indexPath.row]
        
        cell.textLabel?.text = "From Pin: \(requestItem.requestersPin)"
        
        let formatter = Constants.internetTimeDateFormatter()
        let date = formatter?.date(from: requestItem.time)
        
        if let theRealDate = date as Date! {
            
            let letNewFormater = DateFormatter()
            letNewFormater.dateStyle = .medium
            letNewFormater.timeStyle = .short

            let dateString = letNewFormater.string(from: theRealDate)
            cell.detailTextLabel?.text = "Date Sent: \(dateString)"
            
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let requestItem = items[indexPath.row]
       // let toggledCompletion = !groceryItem.completed
       // toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

        
        let alert = UIAlertController(title: "Friend Request", message: "Accept this person's friend request", preferredStyle: .alert)
        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { action in
        
            let friendsRefWithPin = FIRDatabase.database().reference().child("users").child(userId).child("friends").child(requestItem.requestersPin)
            friendsRefWithPin.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                
                if error == nil {
                    //success
                    
                    // now add more friendship so it is reciprocal
                    
                    // 1 get the friend's unique id path
                    let friendPinPath = FIRDatabase.database().reference().child("pins").child(requestItem.requestersPin)
                    // get there unique id
                    friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let result = snapshot.value as? NSDictionary
                        if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                            
                            
                            
                            
                            // add me to their list
                            let myPin = UserDefaults.standard.object(forKey: kPin) as! String

                            let friendspath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("friends").child(myPin)
                            friendspath.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                                
                                if error == nil {
                                    //success
                                    
                                    
                                    
                                    
                                    // send the push notificaiotn!
                                    let friendPushPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("pushId")
                                    friendPushPath.observeSingleEvent(of: .value, with: { (snapshot) in
                                        if let friendPushInfoDictionary = snapshot.value as? NSDictionary {
                                            
                                            if let friendPushIdString = friendPushInfoDictionary["userId"] as? String {
                                                
                                                let title = "Friend Request Accepted"
                                                let senderPin = "From Pin: \(myPin)"
                                                
                                                OneSignal.postNotification(["contents": ["en": senderPin], "headings": ["en": title], "include_player_ids": [friendPushIdString], "content_available" : true])
                                            }
                                        }
                                    })
                                    
                                    
                                    
                                    
                                    
                                    self.removeFriendRequest(request: requestItem)
                                } else {
                                    // error
                                }
                            }
                            
                            
                      
                            
                            
                        }
                    })
                    
                    // add constants comments here
                } else {
                    // add comments here
                }
            }
            
            
            
        })
        
        let notAcceptAction = UIAlertAction(title: "Not Accept", style: .destructive, handler: { action in
        
            
            let declinedFriends = FIRDatabase.database().reference().child("users").child(userId).child("declinedFriends").child(requestItem.requestersPin)
            
            //refactor this into a method
            /*
            let formatter = Constants.internetTimeDateFormatter()
            let dictionary: NSDictionary = [
                "Date" : formatter!.string(from: Date.init())
            ]*/
            
            declinedFriends.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                
                if error == nil {
                    // success
                    self.removeFriendRequest(request: requestItem)
                    
                    // add comments here
                } else {
                    // add comments here
                }
            }
        })
        
        alert.addAction(acceptAction)
        alert.addAction(notAcceptAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func removeFriendRequest (request requestItem: individualFriendRequest) {
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

        let specifictFriendRequest = FIRDatabase.database().reference().child("users").child(userId).child("friendRequests").child(requestItem.requestersPin)
        
        specifictFriendRequest.removeValue(completionBlock: { (error, ref) in
            if error == nil {
                // success
                
                // add comments here
            } else {
                // add comments here
            }
        })
    }
    
    func dictionaryWithOnlyTime() -> NSDictionary {
        let formatter = Constants.internetTimeDateFormatter()
        let dictionary: NSDictionary = [
            "Date" : formatter!.string(from: Date.init())
        ]
        return dictionary
    }
    
    
    func addPlusButton() {
        //         let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewFriend))
        let addButton = UIBarButtonItem(title: "Add Friend", style: .plain, target: self, action: #selector(addNewFriend))
        addButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func addNewFriend() {
        self.performSegue(withIdentifier: "addNewFriend", sender: self)
    }
    
}
