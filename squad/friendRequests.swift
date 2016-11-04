//
//  friendRequests.swift
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit
//import Firebase


class friendRequests: UITableViewController {
    
  //  var ref: FIRDatabaseReference!
    
    var items: [individualFriendRequest] = []

    let userId = UserDefaults.standard.object(forKey: kDocentUserId) as! String

    
    
  //  let ref = FIRDatabase.database().reference(withPath: "grocery-items")
    var userCountBarButtonItem: UIBarButtonItem!

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        /*
        tableView.allowsMultipleSelectionDuringEditing = false
        
        userCountBarButtonItem = UIBarButtonItem(title: "1",
                                                 style: .plain,
                                                 target: self,
                                                 action: nil)
        userCountBarButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = userCountBarButtonItem
        */
        
        self.navigationItem.title = "Friend Requests"

        let friendRequestsPath = FIRDatabase.database().reference().child("users").child(userId).child("friendRequests")
        friendRequestsPath.observe(.value, with: { snapshot in
            var newItems: [individualFriendRequest] = []
            
            for item in snapshot.children {
                let requestItem = individualFriendRequest(snapshot: item as! FIRDataSnapshot)
                newItems.append(requestItem)
            }
            
            self.items = newItems
            
            self.navigationController?.tabBarItem.badgeValue = "\(self.items.count)"

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
        
        cell.textLabel?.text = requestItem.requestersPin
        cell.detailTextLabel?.text = requestItem.time
        
       // toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
        
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
        
            let friends = FIRDatabase.database().reference().child("users").child(userId).child("friends").child(requestItem.requestersPin)
            
            
            let formatter = Constants.internetTimeDateFormatter()
            let dictionary: NSDictionary = [
                "Date" : formatter!.string(from: Date.init())
            ]
            
            friends.setValue(dictionary) { (error, ref) in
                
                if error == nil {
                    //success
                    self.removeFriendRequest(request: requestItem)
                  
                    // add comments here
                } else {
                    // add comments here
                }
            }
            
            
            
        })
        
        let notAcceptAction = UIAlertAction(title: "Not Accept", style: .destructive, handler: { action in
        
            
            let declinedFriends = FIRDatabase.database().reference().child("users").child(userId).child("declinedFriends").child(requestItem.requestersPin)
            
            //refactor this into a method
            let formatter = Constants.internetTimeDateFormatter()
            let dictionary: NSDictionary = [
                "Date" : formatter!.string(from: Date.init())
            ]
            
            declinedFriends.setValue(dictionary) { (error, ref) in
                
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
        let specifictFriendRequest = FIRDatabase.database().reference().child("users").child(userId).child("friendRequests").child(requestItem.requestersPin)
        
        specifictFriendRequest.removeValue(completionBlock: { (error, ref) in
            if error != nil {
                // success
                
                // add comments here
            } else {
                // add comments here
            }
        })
    }
    
    
  
    
}
