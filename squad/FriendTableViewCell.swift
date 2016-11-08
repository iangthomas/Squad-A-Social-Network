//
//  FriendTableViewCell.swift
//  squad
//
//  Created by Ian Thomas on 11/5/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var missedMessages: UILabel!
    @IBOutlet weak var dotImage: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
