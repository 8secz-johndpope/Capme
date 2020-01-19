//
//  DiscoverItem.swift
//  Capme
//
//  Created by Gabe Wilson on 12/19/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class DiscoverTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var usernameOutlet: UIButton!
    @IBOutlet weak var profilePicOutlet: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var firstCaptionView: CaptionView!
    @IBOutlet weak var secondCaptionView: CaptionView!
    @IBOutlet weak var thirdCaptionView: CaptionView!
    
    var profilePicAction : (() -> ())?
    
    var senderUsernameAction : (() -> ())?
    
    override func awakeFromNib() {
        self.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        self.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        self.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
    }
    
    @IBAction func profilePicTapped(_ sender: UIButton) {
        profilePicAction?()
    }
    
    @IBAction func senderUsernameTapped(_ sender: UIButton) {
        senderUsernameAction?()
    }

    
    
    
    
}
