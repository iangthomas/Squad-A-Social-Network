//
//  friendList.swift
//  Squad
//
//  Created by Ian Thomas on 11/4/16.
//  Copyright © 2016 Geodex Systems. All rights reserved.
//

import UIKit
import CoreLocation

class friendList : UITableViewController {

    var friendsList: [individualFriend] = []
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Friends List"
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        addPlusButton()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        self.tableView.allowsSelectionDuringEditing = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(friendList.displayList), name: Notification.Name("friendListReady"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(friendList.updateTableViewData), name: Notification.Name("updateTableViewData"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(friendList.refreshAllCells), name: Notification.Name("refreshAllFriendListCells"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(friendList.endFriendListEditing), name: Notification.Name("endFriendListEditing"), object: nil)
    }
    
    
    func sortFunc(loc1: CLLocationCoordinate2D, loc2: CLLocationCoordinate2D) -> Bool {
       
        let cllocation1: CLLocation = CLLocation(latitude: loc1.latitude,
                                              longitude: loc1.longitude)
        let cllocation2: CLLocation = CLLocation(latitude: loc2.latitude,
                                                 longitude: loc2.longitude)
        
        return cllocation1.distance(from: cllocation2) < cllocation2.distance(from: cllocation1)
    }
    
    // this shorts it based on shortest to greatest distance
    func sortList () {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if appDelegate.currentLocation != nil {
            
            let myLocation = appDelegate.currentLocation as CLLocation
            
            self.friendsList.sort { (friend1:individualFriend, friend2:individualFriend) -> Bool in
                
                if friend1.location != nil {
                    if friend2.location != nil {
                        
                        let cllocation1: CLLocation = CLLocation(latitude: friend1.location!.latitude,
                                                                 longitude: friend1.location!.longitude)
                        
                        let cllocation2: CLLocation = CLLocation(latitude: friend2.location!.latitude,
                                                                 longitude: friend2.location!.longitude)
                        
                        let distance1 = myLocation.distance(from: cllocation1)
                        let distance2 = myLocation.distance(from: cllocation2)
                        
                        return distance1 < distance2
                    }
                }
                return false
            }
        }
    }
    
    func displayList (_ theNotification: Notification) {
        let theList = theNotification.object as! NSDictionary
        if let temp = theList.object(forKey: "friendList") as? [individualFriend] {
            friendsList = temp
        }
        sortAndReDisplayData()
    }
    
    func updateTableViewData (_ theNotification: Notification) {
        let theList = theNotification.object as! NSDictionary
        if let temp = theList.object(forKey: "friendList") as? [individualFriend] {
            friendsList = temp
        }
        sortAndReDisplayData()
    }
    
    func refreshAllCells(_ theNotification: Notification) {
        sortAndReDisplayData()
    }
    
    func sortAndReDisplayData () {
        sortList()
        tableView.reloadData()
    }
    
    /*
    func updateSpecificCellWithNewData (_ index: Int) {
    
        let theCellIndexPath = IndexPath(item: index, section: 0)
        self.tableView.reloadRows(at: [theCellIndexPath], with: .automatic)
    }
    */
    
    func addPlusButton() {
    //  let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewFriend))
        let addButton = UIBarButtonItem(title: "Add Friend", style: .plain, target: self, action: #selector(addNewFriend))
        addButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func addNewFriend() {
        self.performSegue(withIdentifier: "addNewFriend", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //NotificationCenter.default.post(name: Notification.Name("pleaseSendUpdatedModel"), object: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsList.count
    }
    
    func endFriendListEditing (_ Notification: Notification) {
        super.tableView.setEditing(false, animated: true)
        self.setEditing(false, animated: true)
        self.tableView.setEditing(false, animated: true)
    }
    
    func addNickname(_ thePin: String) -> String {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let nickname = appDelegate.nickname(forPin: thePin) as String
        
        if nickname.isEmpty {
            return "Pin: \(thePin)"
        } else {
            return "\(nickname), Pin: \(thePin)"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! FriendTableViewCell
        let requestItem = friendsList[indexPath.row]
        
        cell.title?.text = addNickname(requestItem.key)
        
        if let theLocation = requestItem.location as CLLocationCoordinate2D! {

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let clCorr = CLLocation.init(latitude: theLocation.latitude, longitude: theLocation.longitude)
            let theLocationString = appDelegate.findNearestLargeCity(clCorr) as String
            
            cell.subtitle?.text = "Near \(theLocationString)"
        } else {
            cell.subtitle?.text = "Off Grid"
        }
        
        cell.dotImage.image = UIImage(named: "greenMessageDot")
        
        if requestItem.unreadMessage > 0 {
            cell.missedMessages?.text = "\(requestItem.unreadMessage)"
            cell.dotImage.isHidden = false
            
        } else {
            cell.missedMessages?.text = ""
            cell.dotImage.isHidden = true
        }
        return cell
    }
    
    func makeNewChannel (_ theFriend: individualFriend) {
    
            // no match, make a new channel
            // no -> make one, add it to both users and show it.
            
            let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
            
            // generate the main channel
            // let channelsPath = FIRDatabase.database().reference().child("channels")
            let newChannelPathId = self.channelRef.childByAutoId()
            
            var channelItem: [String: Any]
            
            channelItem = [
                "name": "Chat"
            ]
            
            newChannelPathId.setValue(channelItem) { (error, ref) in
                if error == nil {
                    
                    // make the new channel for this user
                    let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels").child(newChannelPathId.key)
                    thisUserPath.setValue(true) { (error, ref) in
                        if error == nil {
                            
                            
                            // make the new channel for the friend
                            //let theFriend = self.items[(indexPath as NSIndexPath).row]
                            
                            let theFriendPin = theFriend.key
                            
                            let friendPinPath = FIRDatabase.database().reference().child("pins").child(theFriendPin)
                            // get there uniqeu id
                            friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
                                
                                let result = snapshot.value as? NSDictionary
                                if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                                    
                                    
                                    let friendUserPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("channels").child(newChannelPathId.key)
                                    friendUserPath.setValue(true) { (error, ref) in
                                        if error == nil {
                                            
                                            // the channel has been added to both the users.
                                            // now lets make a channel object to send to the next viewcontroller
                                            
                                            
                                            // et their push notificaiotn id first!
                                            let friendPushPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("pushId")
                                            friendPushPath.observeSingleEvent(of: .value, with: { (snapshot) in
                                                if let friendPushInfoDictionary = snapshot.value as? NSDictionary {
                                                    
                                                    if let friendPushIdString = friendPushInfoDictionary["userId"] as? String {

                                                            self.pushToChannel(self.channelRef.child(newChannelPathId.key), withPushId: friendPushIdString)
                                                    }
                                                }
                                            })
                                            
                                            // add comments here
                                        } else {
                                            // add comments here
                                        }
                                    }
                                    
                                }
                            })
                        } else {
                            // add comments here
                        }
                    }
                    
                }
            }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if tableView.isEditing {
            // edit the person's name
            self.performSegue(withIdentifier: "editFriend", sender: indexPath)

        } else {
        
        
        // do these users have a channel together?
        var theKeyString = "no-match"
        var madeNewChannel = false
        
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        
        
        let theFriend = self.friendsList[(indexPath as NSIndexPath).row]
        let theFriendPin = theFriend.key
        let friendPinPath = FIRDatabase.database().reference().child("pins").child(theFriendPin)
        // get there unique id
        friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let result = snapshot.value as? NSDictionary
            if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                let friendChannelPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("channels")
                
                // get all of this users channels
                thisUserPath.observeSingleEvent(of: .value, with: {snapshot in
                    
                    if let myChannels = snapshot.value as? NSDictionary {
                    
                    // all of the friend channels
                    friendChannelPath.observeSingleEvent(of: .value, with: { (snapshot) in
                        if let friendsChannels = snapshot.value as? NSDictionary {
                        
                        let myKeys = myChannels.allKeys
                        
                        // search for overlap
                        for key in myKeys {
                            if friendsChannels.object(forKey: key) != nil {
                                // match
                                theKeyString = key as! String
                                break
                            }
                        }

                        
                        // now decide
                            if theKeyString == "no-match" {
                            
                                self.makeNewChannel(theFriend)
                            
                            } else {
                            // yes there was a matched channel -> show it
                                
                                
                                // get their push notificaiotn id first!
                                let friendPushPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("pushId")
                                friendPushPath.observeSingleEvent(of: .value, with: { (snapshot) in
                                    if let friendPushInfoDictionary = snapshot.value as? NSDictionary {
                                        
                                        if let friendPushIdString = friendPushInfoDictionary["userId"] as? String {
                                        
                                            self.pushToChannel(self.channelRef.child(theKeyString), withPushId: friendPushIdString)
                                        }
                                    }
                                })
                                
                                
 
                            }
                        } else {
                            if madeNewChannel == false {
                                madeNewChannel = true
                            self.makeNewChannel(theFriend)
                            }
                        }
                        
                    })
                    } else {
                        if madeNewChannel == false {
                            madeNewChannel = true
                        self.makeNewChannel(theFriend)
                        }
                    }
                })
            }
        })
        }
    }
    
    func pushToChannel (_ theRef: FIRDatabaseReference, withPushId thePushId: String) {
        
        theRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = channelData["name"] as! String!, name.characters.count > 0 {
                
                var theDictionary: Dictionary<String, Any> = [:]
                theDictionary["channel"] = (Channel(id: id, name: name))
                theDictionary["pushNotifId"] = thePushId
                
                self.performSegue(withIdentifier: "ShowChannel", sender: theDictionary)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "ShowChannel" {
            
            if let theDictionary = sender as? Dictionary<String, Any> {
            
                // get the channel
                if let channel = theDictionary["channel"] as? Channel {
                    
                    // get the push id
                    if let pushId = theDictionary["pushNotifId"] as? String {
                    
                        let chatVc = segue.destination as! ChatViewController
                        chatVc.senderDisplayName = UserDefaults.standard.object(forKey: kPin) as! String
                        chatVc.channel = channel
                        chatVc.channelRef = channelRef.child(channel.id)
                        chatVc.thePushIdString = pushId
                    }
                }
            }
        } else if (segue.identifier == "editFriend") {
        
            if let theIndexPath = sender as? IndexPath {
            // send the database of friends so we can save it
                // send the pin number 
                
              //  if let theFriendPin = items[theIndexPath.row] as? individualFriend {
                let destinationNavigationController = segue.destination as! UINavigationController
                let targetController = destinationNavigationController.topViewController as! editFriendViewController
                
                 //   let friendEditVC = segue.destination as! editFriendViewController
                    targetController.friendList = friendsList
                    targetController.friendPin = friendsList[theIndexPath.row].key
                    
               // }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            let myUserPin = UserDefaults.standard.object(forKey: kPin) as! String
            let friendToRemove = friendsList[indexPath.row]
            
            
            // remove this person from the other person's list
            let friendPinPath = FIRDatabase.database().reference().child("pins").child(friendToRemove.key)
            // get there unique id
            friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
                
                let result = snapshot.value as? NSDictionary
                if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                    
                    let theFormerFriendUserDirectory = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("friends").child(myUserPin)
                    theFormerFriendUserDirectory.removeValue(completionBlock: { (error, ref) in
                        if error == nil {
                            // success
                        }
                    })
                }
            })
            
            
            // remove the other perosn from my list
            let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

            let thisUsersFriendsDirectory = FIRDatabase.database().reference().child("users").child(userId).child("friends").child(friendToRemove.key)
            thisUsersFriendsDirectory.removeValue(completionBlock: { (error, ref) in
                if error == nil {
                    // success
                    self.sortAndReDisplayData()

                    // add comments here
                } else {
                    // add comments here
                }
            })
        }
        
        
    }
}
