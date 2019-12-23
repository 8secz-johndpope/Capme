//
//  CaptionView.swift
//  Capme
//
//  Created by Gabe Wilson on 12/22/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class CaptionView: UIView {
    
    @IBOutlet weak var profilePic: UIButton!
    @IBOutlet weak var favoriteButtonOutlet: UIButton!
    @IBOutlet weak var usernameButton: UIButton!
    @IBOutlet weak var captionLabel: UILabel!
    
    var favoriteAction : (() -> ())?
      
    override func awakeFromNib() {
      super.awakeFromNib()
      self.favoriteButtonOutlet.addTarget(self, action: #selector(favoriteActionTapped(_:)), for: .touchUpInside)
    }
      
    @IBAction func favoriteActionTapped(_ sender: UIButton) {
        favoriteAction?()
    }

}
