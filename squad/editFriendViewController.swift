//
//  editFriendViewController.swift
//  squad
//
//  Created by Ian Thomas on 11/10/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit

class editFriendViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var friendPinLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var friendList: [individualFriend] = []
    var friendPin = ""
    var addedNickname = false
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Friend Nickname"
      //  self.navigationController?.navigationBar.tintColor = UIColor.white
        
        nicknameTextField.becomeFirstResponder()
        doneButton.isEnabled = false
        
        friendPinLabel.text = "Friend Pin: \(friendPin)"
        
        // load the old nickname
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let theOldNickname = appDelegate.nickname(forPin: friendPin) {
            if theOldNickname != "" {
                nicknameTextField.text = theOldNickname
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func cancel (_ sener: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func done (_ sender: AnyObject) {
        
        if addedNickname == false {
            perfromSavingFunctions()
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if addedNickname == false {
            perfromSavingFunctions()
        }
        return true
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = textField.text! as NSString
        let newText = oldText.replacingCharacters(in: range, with: string) as NSString
        doneButton.isEnabled = newText.length > 0
        return true
    }
    
    
    func perfromSavingFunctions() {
        addFriendNickname()
        saveFriendNicknameDatabase()
        
        NotificationCenter.default.post(name: Notification.Name("refreshAllFriendListCells"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("endFriendListEditing"), object: nil)

        self.dismiss(animated: true, completion: nil)
    }
    
    
    func addFriendNickname () {
        addedNickname = true
        appDelegate.addNewFriendNickname(withNickname: nicknameTextField.text, withPin: friendPin)
    }
    
    
    func saveFriendNicknameDatabase () {
        appDelegate.saveFriendListDatabase()
    }
}
