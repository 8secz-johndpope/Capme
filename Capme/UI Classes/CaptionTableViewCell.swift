//
//  CaptionTableViewCell.swift
//  Capme
//
//  Created by Gabe Wilson on 12/23/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class CaptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var favoriteOutlet: UIButton!
    @IBOutlet weak var usernameOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var profilePictureOutlet: UIButton!
    @IBOutlet weak var favoritesCountLabel: UILabel!
    
    var favoriteAction : (() -> ())?
    
    var showCaptionerAction : (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.favoriteOutlet.addTarget(self, action: #selector(favoriteActionTapped(_:)), for: .touchUpInside)
        self.profilePictureOutlet.addTarget(self, action: #selector(captionerProfilePictureTapped(_:)), for: .touchUpInside)
    }
    
    @IBAction func favoriteActionTapped(_ sender: UIButton) {
        favoriteAction?()
    }
    
    @IBAction func captionerProfilePictureTapped(_ sender: UIButton) {
        showCaptionerAction?()
    }

    
}
