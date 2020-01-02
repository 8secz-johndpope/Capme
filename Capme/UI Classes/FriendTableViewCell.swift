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
    
    
    var addFriendAction : (() -> ())?
    
    override func awakeFromNib() {
        
    }
    
    
    
    
    
    @IBAction func addFriendTapped(_ sender: Any) {
        addFriendAction?()
    }
    
}
