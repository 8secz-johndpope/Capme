//
//  RequestCollectionViewCell.swift
//  Capme
//
//  Created by Gabe Wilson on 12/16/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class RequestCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var removeOutlet: UIButton!
    @IBOutlet weak var acceptOutlet: UIButton!
    
    var requestId = ""
    
    @IBAction func removeAction(_ sender: Any) {
        self.removeOutlet.isEnabled = false
        if let buttonRef = sender as? UIButton {
            let _ = buttonRef.accessibilityLabel
            let request = PFObject(withoutDataWithClassName: "FriendRequest", objectId: requestId)
            request.deleteInBackground(block: { (success, error) in
                if error == nil {
                    print("Success: Deleted the request")
                }
            })
        }
    }
    
    @IBAction func acceptAction(_ sender: Any) {
        self.acceptOutlet.isEnabled = false
        if let buttonRef = sender as? UIButton {
            let _ = buttonRef.accessibilityLabel
            // TODO send push to recipient here now that
            // the current user has accepted the request
            let request = PFObject(withoutDataWithClassName: "FriendRequest", objectId: requestId)
            request["status"] = "accepted"
            request.saveInBackground { (success, error) in
                if error == nil {
                    print("Success: Updated the request status to accepted")
                }
            }
        }
    }
}
