//
//  individualFriendRequest.swift
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import Foundation

struct individualFriendRequest {
    
    let time: String
    let requestersPin: String
    let key: String
    let ref: FIRDatabaseReference?
    
    
    init(time: String, requestersPin: String, key: String = "") {
        self.time = time
        self.requestersPin = requestersPin
        self.key = key
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        time = snapshotValue["Date"] as! String
        requestersPin = snapshot.key as! String
        ref = snapshot.ref
    }
    
    
    func toAnyObject() -> Any {
        return [
            "time": time,
            "requestersPin": requestersPin
        ]
    }

}
