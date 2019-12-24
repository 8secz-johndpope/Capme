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
    
    @IBOutlet weak var senderProfilePic: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var firstCaptionView: CaptionView!
    @IBOutlet weak var secondCaptionView: CaptionView!
    @IBOutlet weak var thirdCaptionView: CaptionView!
    
    override func awakeFromNib() {
        self.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        self.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        self.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
    }

    
    
    
    
}
