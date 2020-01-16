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
    @IBOutlet weak var profilePicOutlet: UIButton!
    
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
    
    var acceptRequestAction : (() -> ())?
    
    override func awakeFromNib() {
        
    }
    
    @IBAction func acceptAction(_ sender: Any) {
        acceptRequestAction?()
    }
}
