//
//  FriendTableViewCell.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class FriendTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addFriendOutlet: UIButton!
    
    @IBAction func addFriendAction(_ sender: Any) {
        print("adding friend")
        if let addFriendButton = sender as? UIButton {
            print(addFriendButton.accessibilityLabel!)
            let Request = PFObject(className: "FriendRequest")
            Request["sender"] = PFUser.current()
            Request["recipient"] = PFUser(withoutDataWithObjectId: addFriendButton.accessibilityLabel!)
            Request["status"] = "pending"
            Request.saveInBackground { (success, error) in
                if error == nil {
                    print("Success: Saved the new friend request")
                    self.addFriendOutlet.setTitle("Pending...", for: .normal)
                }
            }
        }
    }
    
}
