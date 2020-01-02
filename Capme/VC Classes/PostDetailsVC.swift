//
//  PostDetailsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 1/1/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class PostDetailsVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var selectedPost = Post()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.imageView.image = self.selectedPost.images[0]
    }
    
}
