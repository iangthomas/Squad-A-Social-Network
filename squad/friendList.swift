//
//  friendList.swift
//  squad
//
//  Created by Ian Thomas on 11/4/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit
import CoreLocation

class friendList : UITableViewController {

    var items: [individualFriend] = []
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Friends List"
        
        addPlusButton()
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

        let friendsPath = FIRDatabase.database().reference().child("users").child(userId).child("friends")
        friendsPath.observe(.value, with: { snapshot in
            
            var newItems: [individualFriend] = []
            
            for item in snapshot.children {
                let requestItem = individualFriend(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            self.items = newItems
            
            
            // now get the distances between you and them
            // items must already be setup!
            self.getDistancesToFriends();
          

            self.tableView.reloadData()
        })
    }
    
    func getDistancesToFriends () {
        for (index, theItem) in self.items.enumerated() {
            var theFriend = theItem
            
            let friendPinPath = FIRDatabase.database().reference().child("pins").child(theFriend.key)
            // get their unique id
            friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
                let result = snapshot.value as? NSDictionary
                if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                    theFriend.uniqueId = uniqueFriendId
                    
                    let friendCoorPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("coor")
                    friendCoorPath.observe(FIRDataEventType.value, with: { (snapshot) in
                        if let coor = snapshot.value as? NSDictionary {
                            
                            self.items[index].location = CLLocationCoordinate2D(latitude: coor.object(forKey: "lat") as! CLLocationDegrees, longitude: coor.object(forKey: "lon") as! CLLocationDegrees)
                            
                            self.updateSpecificCellWithNewLoctaion(index)

                        } else {
                            // no location or off grid
                            self.items[index] .location = nil
                            
                            self.updateSpecificCellWithNewLoctaion(index)
                        }
                    })
                }
            })
        }
    }
    
    
    func updateSpecificCellWithNewLoctaion (_ index: Int) {
    
        let theCellIndexPath = IndexPath(item: index, section: 0)
        self.tableView.reloadRows(at: [theCellIndexPath], with: .automatic)
    }
    
    
    func addPlusButton() {
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewFriend))
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
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        let requestItem = items[indexPath.row]
        
        cell.textLabel?.text = requestItem.key
        
        if let theLocation = requestItem.location as CLLocationCoordinate2D! {
            cell.detailTextLabel?.text = ("lat\(theLocation.latitude), lon \(theLocation.longitude)")
        } else {
            cell.detailTextLabel?.text = "Off Grid"
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
                                            
                                            self.pushToChannel(self.channelRef.child(newChannelPathId.key))
                                            
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

        // do these folks have a channel together?
        var theKeyString = "no-match"
        var madeNewChannel = false
        
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        
        
        let theFriend = self.items[(indexPath as NSIndexPath).row]
        let theFriendPin = theFriend.key
        let friendPinPath = FIRDatabase.database().reference().child("pins").child(theFriendPin)
        // get there unique id
        friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let result = snapshot.value as? NSDictionary
            if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                let friendUserPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("channels")
                
                // get all of this users channels
                thisUserPath.observe(.value, with: {snapshot in
                    
                    if let myChannels = snapshot.value as? NSDictionary {
                    
                    // all of the friend channels
                    friendUserPath.observeSingleEvent(of: .value, with: { (snapshot) in
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
                                
                                self.pushToChannel(self.channelRef.child(theKeyString))
 
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
    
    func pushToChannel (_ theRef: FIRDatabaseReference) {
        
        theRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = channelData["name"] as! String!, name.characters.count > 0 {
                
                self.performSegue(withIdentifier: "ShowChannel", sender: (Channel(id: id, name: name)))
                
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let channel = sender as? Channel {
            let chatVc = segue.destination as! ChatViewController
            chatVc.senderDisplayName = UserDefaults.standard.object(forKey: kPin) as! String
            chatVc.channel = channel
            chatVc.channelRef = channelRef.child(channel.id)
        }
    }
}
