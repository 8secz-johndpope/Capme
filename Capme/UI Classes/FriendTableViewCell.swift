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
    
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addFriendOutlet: UIButton!
    @IBOutlet weak var addFriendLabel: UILabel!
    
    @IBAction func addFriendAction(_ sender: Any) {
        self.addFriendOutlet.isEnabled = false
        self.addFriendLabel.text = "Sent ✓"
        if let addFriendButton = sender as? UIButton {
            print(addFriendButton.accessibilityLabel!)
            if let i = DataModel.users.firstIndex(where: { $0.objectId == addFriendButton.accessibilityLabel }) {
                print("adding to Data Model")
                DataModel.sentRequests.append(DataModel.users[i])
            }
            let Request = PFObject(className: "FriendRequest")
            Request["sender"] = PFUser.current()
            Request["recipient"] = PFUser(withoutDataWithObjectId: addFriendButton.accessibilityLabel!)
            Request["status"] = "pending"
            Request.saveInBackground { (success, error) in
                if error == nil {
                    print("Success: Saved the new friend request")
                    self.addFriendOutlet.setTitle("Pending...", for: .normal)
                    PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["recipientIds": [addFriendButton.accessibilityLabel!], "title": PFUser.current()?.username!, "message": "Check out your new friend request!", "identifier" : "friendRequest"]) {
                        (response, error) in
                        if error == nil {
                            print("Success: Sent a push notification for a new friend request")
                        } else {
                            print(error?.localizedDescription, "Cloud Code Push Error")
                        }
                    }
                }
            }
        }
    }
    
}
