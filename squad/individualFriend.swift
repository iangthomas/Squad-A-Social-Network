//
//  individualFriend.swift
//  Squad
//
//  Created by Ian Thomas on 11/4/16.
//  Copyright © 2016 Geodex Systems. All rights reserved.
//

import Foundation
import CoreLocation

struct individualFriend {
    
    let time: String
    //let requestersPin: String
    let key: String
    let ref: FIRDatabaseReference?
    var location: CLLocationCoordinate2D?
    var uniqueId: String?
    var unreadMessage: Int
    
    
    init(time: String, key: String = "") {
        self.time = time
       // self.requestersPin = requestersPin
        self.key = key
        self.ref = nil
        self.location = nil
        self.uniqueId = nil
        self.unreadMessage = 0
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        time = snapshotValue["Date"] as! String
        ref = snapshot.ref
        location = nil
        self.uniqueId = nil
        unreadMessage = 0
    }
    
    
    func toAnyObject() -> Any {
        return [
            "time": time,
            "key": key
        ]
    }
    
}
