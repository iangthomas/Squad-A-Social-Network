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
    
    var recievedFriendRequests: [individualFriendRequest] = []
    var sentFriendRequests: [individualFriendRequest] = []
    
    let recievedSegmentedIndex = 0
    let sentSegmentedIndex = 1


    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        addPlusButton()
    //  self.navigationItem.title = "Friend Requests"

        loadRecievedFriendRequests()
        loadSentFriendRequests()
        
        
        /*
        // if there is a inbound request, show it, otherwise show the list that is the larger
        if recievedFriendRequests.count > 0 {
            if recievedFriendRequests.count < sentFriendRequests.count {
                segmentedControl.selectedSegmentIndex = sentSegmentedIndex
            }
        }
         */
    }
    
    // refactor the following two...

    func loadRecievedFriendRequests () {
        let myUserId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let friendRequestsPath = FIRDatabase.database().reference().child("users").child(myUserId).child("friendRequests")
        friendRequestsPath.observe(.value, with: { snapshot in
            var newItems: [individualFriendRequest] = []
            
            for item in snapshot.children {
                let requestItem = individualFriendRequest(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            self.recievedFriendRequests = newItems
            self.tableView.reloadData()
        })
    }
    
    func loadSentFriendRequests () {
        let myUserId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let friendRequestsPath = FIRDatabase.database().reference().child("users").child(myUserId).child("outstandingFriendRequests")
        friendRequestsPath.observe(.value, with: { snapshot in
            var newItems: [individualFriendRequest] = []
            
            for item in snapshot.children {
                let requestItem = individualFriendRequest(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            self.sentFriendRequests = newItems
            self.tableView.reloadData()
        })
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segmentedControl.selectedSegmentIndex == recievedSegmentedIndex {
            return recievedFriendRequests.count
        } else {
            return sentFriendRequests.count
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let formatter = Constants.internetTimeDateFormatter()
        let letNewFormater = DateFormatter()
        letNewFormater.dateStyle = .medium
        letNewFormater.timeStyle = .short
        
        if segmentedControl.selectedSegmentIndex == recievedSegmentedIndex {

            let requestItem = recievedFriendRequests[indexPath.row]
            
            cell.textLabel?.text = "From Pin: \(requestItem.requestersPin)"
            
            let date = formatter?.date(from: requestItem.time)
            
            if let theRealDate = date as Date! {

                let dateString = letNewFormater.string(from: theRealDate)
                cell.detailTextLabel?.text = "Date Sent: \(dateString)"
            } else {
                cell.detailTextLabel?.text = ""
            }
            return cell
            
        } else {
        
            let requestItem = sentFriendRequests[indexPath.row]
            
            cell.textLabel?.text = "To Pin: \(requestItem.requestersPin)"
            
            let date = formatter?.date(from: requestItem.time)
            if let theRealDate = date as Date! {
                
                let dateString = letNewFormater.string(from: theRealDate)
                cell.detailTextLabel?.text = "Date Sent: \(dateString)"
            } else {
                cell.detailTextLabel?.text = ""
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segmentedControl.selectedSegmentIndex == recievedSegmentedIndex {
        
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            let requestItem = recievedFriendRequests[indexPath.row]
            let myUserId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

            let alert = UIAlertController(title: "Friend Request", message: "Accept this person's friend request", preferredStyle: .alert)
            alert.addAction(acceptFriendRequestAction(requestItem))
            alert.addAction(self.denyFriendRequestAction(requestItem, myUserId))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func acceptFriendRequestAction(_ requestItem: individualFriendRequest) -> UIAlertAction {
        
        let myUserId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let myPin = UserDefaults.standard.object(forKey: kPin) as! String

        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { action in
            
            let friendsRefWithPin = FIRDatabase.database().reference().child("users").child(myUserId).child("friends").child(requestItem.requestersPin)
            friendsRefWithPin.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                
                if error == nil {
                    //success
                    
                    // now add more friendship so it is reciprocal
                    
                    // get the friend's unique id path
                    let friendPinPath = FIRDatabase.database().reference().child("pins").child(requestItem.requestersPin)
                    // get there unique id
                    friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let result = snapshot.value as? NSDictionary
                        if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                            
                            // add me to their list
                            
                            let friendspath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("friends").child(myPin)
                            friendspath.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                                
                                if error == nil {
                                    //success

                                    self.sendPushNotificaitonToNewFriend(uniqueFriendId)
                                    self.removeFriendRequest(requestItem, myUserId)
                                    self.removeOutstandingFriendRequest(myPin, uniqueFriendId)
                                    
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
        return acceptAction
    }
    
    func denyFriendRequestAction(_ requestItem: individualFriendRequest, _ myUserId: String) -> UIAlertAction {
        
        let notAcceptAction = UIAlertAction(title: "Not Accept", style: .destructive, handler: { action in
            
            let declinedFriends = FIRDatabase.database().reference().child("users").child(myUserId).child("declinedFriends").child(requestItem.requestersPin)
            
            declinedFriends.setValue(self.dictionaryWithOnlyTime()) { (error, ref) in
                
                if error == nil {
                    // success
                    self.removeFriendRequest(requestItem, myUserId)
                    
                } else {
                    // add comments here
                }
            }
        })
        return notAcceptAction
    }
    
    func sendPushNotificaitonToNewFriend (_ uniqueFriendId: String) {
        let friendPushPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("pushId")
        let myPin = UserDefaults.standard.object(forKey: kPin) as! String

        friendPushPath.observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendPushInfoDictionary = snapshot.value as? NSDictionary {
                
                if let friendPushIdString = friendPushInfoDictionary["userId"] as? String {
                    
                    let title = "Friend Request Accepted"
                    let senderPin = "From Pin: \(myPin)"
                    
                    OneSignal.postNotification(["contents": ["en": senderPin], "headings": ["en": title], "include_player_ids": [friendPushIdString], "content_available" : true])
                }
            }
        })
    }
    
    func removeFriendRequest (_ requestItem: individualFriendRequest, _ userId: String) {
        
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
    
    func removeOutstandingFriendRequest(_ myPin: String, _ uniqueFriendId: String) {

        let specifictFriendRequest = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("outstandingFriendRequests").child(myPin)
        
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
        let addButton = UIBarButtonItem(title: "Add Friend", style: .plain, target: self, action: #selector(addNewFriend))
        addButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func addNewFriend() {
        self.performSegue(withIdentifier: "addNewFriend", sender: self)
    }
    
}
