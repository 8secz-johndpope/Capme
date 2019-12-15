//
//  FriendTableViewCell.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class FriendTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addFriendOutlet: UIButton!
    
    @IBAction func addFriendAction(_ sender: Any) {
        print("adding friend")
        if let addFriendButton = sender as? UIButton {
            print(addFriendOutlet.accessibilityLabel)
        }
    }
    
}
