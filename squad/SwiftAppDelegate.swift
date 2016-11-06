//
//  SwiftAppDelegate.swift
//  squad
//
//  Created by Ian Thomas on 11/5/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit

@objc class SwiftAppDelegateClass: NSObject {
    
    func startObservingChatChannels() {
        
       // getChatChannels()
    }
    
    func getChatChannels () {
        
        let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String
        let thisUserPath = FIRDatabase.database().reference().child("users").child(userId).child("channels")
        
      //  var initialDataLoaded = false
        
      //  var messagesRecieved = 0
        
        // get all this user's channels
        thisUserPath.observe(.value, with: {snapshot in
            
            if let myChannels = snapshot.value as! NSDictionary! {
                
                    for thisKey in myChannels {
                        
                        let thisKeyForReal = thisKey.key as! String
                        let thisChannelPath = FIRDatabase.database().reference().child("channels").child(thisKeyForReal).child("messages")
                        thisChannelPath.observe(FIRDataEventType.childAdded, with: { (snapshot) in
                            
                            
                          //  if initialDataLoaded {
                                print ("message added")
                                
                          //  } else {
                                // child added is called once for everychild that exists when first called. ignore these initial calls
                          //  }
                        })
                    }
                
                
                }
            
            // we are done with the initial calls. Now the code can work properly
          //  initialDataLoaded = true
        })
    }
    
    
}
