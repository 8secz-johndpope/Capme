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
    
    @IBAction func removeAction(_ sender: Any) {
        if let buttonRef = sender as? UIButton {
            
            //buttonRef.accessibilityLabel
        }
    }
    
    @IBAction func acceptAction(_ sender: Any) {
        if let buttonRef = sender as? UIButton {
            let request = PFObject(withoutDataWithClassName: "FriendRequest", objectId: buttonRef.accessibilityLabel)
            request["status"] = "aceepted"
            request.saveInBackground { (success, error) in
                if error == nil {
                    print("Success: Updated the request status to accepted")
                }
            }
        }
    }
    
}
