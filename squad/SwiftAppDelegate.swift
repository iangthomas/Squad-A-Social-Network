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
    var listOfUnreadMessagesAddedToNotification: Dictionary<String, String> = [:]
    var friendListReady = false
    
    func startObservingChatChannels() {
        
        listOfUnreadMessagesAddedToNotification = [:]
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(SwiftAppDelegateClass.incrementUnreadMessageCell), name: Notification.Name("incrementUnreadMessageCell"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SwiftAppDelegateClass.decrementUnreadMessageCell), name: Notification.Name("decrementUnreadMessageCell"), object: nil)
        
        
     //   NotificationCenter.default.addObserver(self, selector: #selector(SwiftAppDelegateClass.pleaseSendUpdatedModel), name: Notification.Name ("pleaseSendUpdatedModel"), object: nil)
        
        getFriends()
    }
    
    
    func getChatChannels () {
        
        let userId = UserDefaults.standard.object(forKey: kUserId) as! String
        let userPin = UserDefaults.standard.object(forKey: kPin) as! String

        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        

        // get all this user's channels
        thisUserPath.observe(.value, with: {snapshot in
            
            if let myChannels = snapshot.value as? NSDictionary {
                
                    for thisKey in myChannels {
                        
                        let thisChannelKey = thisKey.key as! String
                        let thisChannelPath = FIRDatabase.database().reference().child("channels").child(thisChannelKey).child("messages")
                        thisChannelPath.observe(FIRDataEventType.childAdded, with: { (snapshotMessage) in
                            
                            if let theMessage = snapshotMessage.value as! NSDictionary! {
                                
                                if theMessage.object(forKey: "senderName") as! String != userPin {
                                
                                if let readMessage = theMessage.object(forKey: "recipientRead"){
                                    if readMessage as! String  == "no" {
                                        
                                        // has this message already been added to all the notification stuff?
                                        if self.alreadyAddedToUnreadMessages(snapshotMessage.key) {
                                           self.addNotificaitonsForANewUnreadMessage(message: theMessage, withkey: snapshotMessage.key)
                                        }
                                    }
                                }
                                }
                            }
                        })
                    }
                }
        })
    }
    
    
    func alreadyAddedToUnreadMessages (_ theKey: String) -> Bool {
        if self.listOfUnreadMessagesAddedToNotification.count > 0 {
            if self.listOfUnreadMessagesAddedToNotification[theKey] != nil {
                return false
            }
        }
        return true
    }
    
    
    func addNotificaitonsForANewUnreadMessage(message theMessage: NSDictionary, withkey theKey: String) {
        
        self.listOfUnreadMessagesAddedToNotification[theKey] = theKey
        NotificationCenter.default.post(name: NSNotification.Name("incrementFriendListBadgeIcon"), object: theKey)
        NotificationCenter.default.post(name: NSNotification.Name("incrementUnreadMessageCell"), object: theMessage)
    }
    
    
    // most of the following code is a duplicate, refactor it!
    // also it is insane, fix that!!!!!
    func decrementUnreadMessageCell (_ theNotification: Notification) {
        
        let theMessage = theNotification.object as! NSDictionary
        let theFriendPin = theMessage.object(forKey: "senderName") as! String
        
        var i = 0
        while i < localFriendList.count {
            if localFriendList[i].key == theFriendPin {
                if localFriendList[i].unreadMessage > 0 {
                    localFriendList[i].unreadMessage -= 1
                    let updatedList:NSDictionary = [
                        "friendList" : self.localFriendList]
                    NotificationCenter.default.post(name: Notification.Name ("updateTableViewData"), object: updatedList)
                    break
                }
             //   updateSpecificCellWithNewData(i)
            }
            i += 1
        }
    }
    
    
    func incrementUnreadMessageCell (_ theNotification: Notification) {
        
        let theMessage = theNotification.object as! NSDictionary
        let theFriendPin = theMessage.object(forKey: "senderName") as! String
        
        var i = 0
        while i < localFriendList.count {
            if localFriendList[i].key == theFriendPin {
                localFriendList[i].unreadMessage += 1
                let updatedList:NSDictionary = [
                    "friendList" : self.localFriendList]
                NotificationCenter.default.post(name: Notification.Name ("updateTableViewData"), object: updatedList)

                //updateSpecificCellWithNewData(i)
                break
            }
            i += 1
        }
    }
    
    func pleaseSendUpdatedModel (_ notification:Notification) {
        if friendListReady == true {
            let updatedList:NSDictionary = [
                "friendList" : self.localFriendList]
            NotificationCenter.default.post(name: Notification.Name ("updateTableViewData"), object: updatedList)
        }
        // else, wait, this is the inital app load and it will automatically send the friend list when it is ready to show
    }
    
    
    
    func getFriends () {
        
        let userId = UserDefaults.standard.object(forKey: kUserId) as! String
        
        let friendsPath = FIRDatabase.database().reference().child("users").child(userId).child("friends")
        friendsPath.observe(.value, with: { snapshot in
            
            var newItems: [individualFriend] = []
            
            for item in snapshot.children {
                let requestItem = individualFriend(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            
            
            self.localFriendList = newItems
            
            
            let updatedList:NSDictionary = [
                "friendList" : self.localFriendList]
            NotificationCenter.default.post(name: Notification.Name ("friendListReady"), object: updatedList)

           // var temp : NSDictionary
            
           // temp.update
           // let test = NSDictionary["1": self.localFriendList]
            
            
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
    //    let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
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
                            
                            
                            let updatedList:NSDictionary = [
                                "friendList" : self.localFriendList]
                          //  NotificationCenter.default.post(name: Notification.Name ("friendListReady"), object: updatedList)

                            NotificationCenter.default.post(name: Notification.Name("updateTableViewData"), object: updatedList)
                            
                         //   self.updateSpecificCellWithNewData(index)
                            
                        } else {
                            // no location or off grid
                            self.localFriendList[index].location = nil
                            
                            let updatedList:NSDictionary = [
                                "friendList" : self.localFriendList]
                         
                            NotificationCenter.default.post(name: Notification.Name("updateTableViewData"), object: updatedList)

                           // self.updateSpecificCellWithNewData(index)
                        }
                    })
                }
            })
        }
    }

}
