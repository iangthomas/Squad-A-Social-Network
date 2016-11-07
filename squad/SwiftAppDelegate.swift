//
//  SwiftAppDelegate.swift
//  squad
//
//  Created by Ian Thomas on 11/5/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit

@objc class SwiftAppDelegateClass: NSObject {
    
    var localFriendList: [individualFriend] = []

    
    func startObservingChatChannels() {
        
        getFriends()
        
        
        
        // incriment the
        
        /*
        let notificationName = Notification.Name("unreadMessage")
        NotificationCenter.default.addObserver(self, selector: #selector(SwiftAppDelegateClass.incrementUnreadMessages), name: notificationName, object: nil)
*/
    }
    
    
    
    
    func incrementUnreadMessages (_ notification: Notification){
        
        
    
    }
    
    func getChatChannels () {
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        

        // get all this user's channels
        thisUserPath.observe(.value, with: {snapshot in
            
            if let myChannels = snapshot.value as! NSDictionary! {
                
                    for thisKey in myChannels {
                        
                        let thisKeyForReal = thisKey.key as! String
                        let thisChannelPath = FIRDatabase.database().reference().child("channels").child(thisKeyForReal).child("messages")
                        thisChannelPath.observe(FIRDataEventType.childAdded, with: { (snapshotMessage) in
                            
                            if let theMessage = snapshotMessage.value as! NSDictionary! {
                                if let readMessage = theMessage.object(forKey: "recipientRead"){
                                    if readMessage as! String  == "no" {
                                        
                                      //  let tmep = thisKeyForReal
                                        NotificationCenter.default.post(name: NSNotification.Name("incrementFriendListBadgeIcon"), object: thisKeyForReal)
                                        
                                        NotificationCenter.default.post(name: NSNotification.Name("incrementUnreadMessageCell"), object: theMessage)

                                        print ("message unread in appdelegate")
                                    }
                                }
                            }
                        })
                    }
                }
        })
    }
    
    func getFriends () {
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        
        let friendsPath = FIRDatabase.database().reference().child("users").child(userId).child("friends")
        friendsPath.observe(.value, with: { snapshot in
            
            var newItems: [individualFriend] = []
            
            for item in snapshot.children {
                let requestItem = individualFriend(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            
            
            self.localFriendList = newItems
            
            
            var temo:NSDictionary = [
                "a" : self.localFriendList]
            
           // var temp : NSDictionary
            
           // temp.update
           // let test = NSDictionary["1": self.localFriendList]
            
            NotificationCenter.default.post(name: Notification.Name ("friendListReady"), object: temo)
            
            /*
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.fr
            
            appDelegate.friendList = newItems
                
               
                as! [individualFriend]
            
            friendList
            
            self.items = newItems
            */
            
            // now get the distances between you and them
            // items must already be setup!
            self.getDistancesToFriends();

            
            // now that the friends are here was can update the channels
            self.getChatChannels()

            
            
           
            
        })
    
    }
    
    
    func getDistancesToFriends () {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
       // localFriendList = appDelegate.friendList as! [individualFriend]

        
        
        for (index, theItem) in localFriendList.enumerated() {
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
                            
                            self.localFriendList [index].location = CLLocationCoordinate2D(latitude: coor.object(forKey: "lat") as! CLLocationDegrees, longitude: coor.object(forKey: "lon") as! CLLocationDegrees)
                            
                            NotificationCenter.default.post(name: Notification.Name("updateTableViewData"), object: index)
                            
                         //   self.updateSpecificCellWithNewData(index)
                            
                        } else {
                            // no location or off grid
                            self.localFriendList[index].location = nil
                            
                            NotificationCenter.default.post(name: Notification.Name("updateTableViewData"), object: index)

                           // self.updateSpecificCellWithNewData(index)
                        }
                    })
                }
            })
        }
    }

}
