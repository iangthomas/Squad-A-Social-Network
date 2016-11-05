//
//  friendList.swift
//  squad
//
//  Created by Ian Thomas on 11/4/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit

class friendList : UITableViewController {

    
    var items: [individualFriend] = []
    
    
 //   private var channelRefHandle: FIRDatabaseHandle?
 //   private var channels: [Channel] = []
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Friends List"
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

        let friendsPath = FIRDatabase.database().reference().child("users").child(userId).child("friends")
        friendsPath.observe(.value, with: { snapshot in
            var newItems: [individualFriend] = []
            
            for item in snapshot.children {
                let requestItem = individualFriend(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            self.items = newItems
            self.tableView.reloadData()
        })
        
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
        
        return cell
    }
    
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // do these folks have a channel together?
        
        
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        
        
        let theFriend = self.items[(indexPath as NSIndexPath).row]
        let theFriendPin = theFriend.key
        let friendPinPath = FIRDatabase.database().reference().child("pins").child(theFriendPin)
        // get there uniqeu id
        friendPinPath.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let result = snapshot.value as? NSDictionary
            if let uniqueFriendId = result?.value(forKey: "uniqueId") as? String {
                let friendUserPath = FIRDatabase.database().reference().child("users").child(uniqueFriendId).child("channels")
                
                
                
                // get all of this users channels
                thisUserPath.observe(.value, with: {snapshot in
                    let myChannels = snapshot.value as! NSDictionary
                    
                    // let theArray = result?.allKeys
                    
                    
                    
                    // all all the friend channels
                    friendUserPath.observeSingleEvent(of: .value, with: { (snapshot) in
                        let friendsChannels = snapshot.value as! NSDictionary
                        
                        let myKeys = myChannels.allKeys
                        let theirKeys = friendsChannels.allKeys
                        
                        // search for overlap
                        
                        var theKeyString = "no-match"
                        
                        for key in myKeys {
                            if friendsChannels.object(forKey: key) != nil {
                                // match
                                theKeyString = key as! String
                                break
                            }
                        }
                        
                        // now decide
                        if theKeyString == "no-match" {
                            // no match, make a new channel
                            // no -> make one, add it to both users and show it.

                            let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
                            
                            // generate the main channel
                            // let channelsPath = FIRDatabase.database().reference().child("channels")
                            let newChannelPathId = self.channelRef.childByAutoId()
                            
                            var channelItem: [String: Any]
                            
                            channelItem = [
                                "name": "ConverstionTest"
                            ]
                            
                            newChannelPathId.setValue(channelItem) { (error, ref) in
                                if error == nil {
                                    
                                    
                                    
                                    // make the new channel for this user
                                    let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels").child(newChannelPathId.key)
                                    thisUserPath.setValue(true) { (error, ref) in
                                        if error == nil {
                                            
                                            
                                            
                                            // make the new channel for the friend
                                            let theFriend = self.items[(indexPath as NSIndexPath).row]
                                            
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
                                                            
                                                            self.channelRef.child(newChannelPathId.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                                                let channelData = snapshot.value as! Dictionary<String, AnyObject>
                                                                let id = snapshot.key
                                                                if let name = channelData["name"] as! String!, name.characters.count > 0 {
                                                                    
                                                                    self.performSegue(withIdentifier: "ShowChannel", sender: (Channel(id: id, name: name)))
                                                                    
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
                            
                        } else {
                            // yes there was a matched channel -> show it

                        
                            
                            self.channelRef.child(theKeyString).observeSingleEvent(of: .value, with: { (snapshot) in
                                let channelData = snapshot.value as! Dictionary<String, AnyObject>
                                let id = snapshot.key
                                if let name = channelData["name"] as! String!, name.characters.count > 0 {
                                    
                                    self.performSegue(withIdentifier: "ShowChannel", sender: (Channel(id: id, name: name)))
                                    
                                }
                            })

                        }
                        
                    })
                })
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
    
    
    
    
    /*
     UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewFriend:)];
     add.tintColor = [UIColor whiteColor];
     
     self.navigationItem.rightBarButtonItem = add;
     
     
     -(IBAction)addNewFriend:(id)sender {
     
     [self performSegueWithIdentifier:@"addNewFriend" sender:self];
     }
     */
    
    
}
