//
//  PostDescriptionVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class PostDescriptionVC: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var mainLabel: UILabel!
    
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        // Textview
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        self.textView.text = "Describe the experience to help your friends make their captions..."
        self.textView.textColor = UIColor.lightGray
        self.textView.frame = CGRect(x: screenWidth/10, y: self.mainLabel.frame.maxY + 30.0, width: screenWidth - (screenWidth/5), height: self.textView.frame.height)
        self.textView.layer.cornerRadius = 10.0
        self.textView.layer.masksToBounds = true
        self.textView.delegate = self
        self.textView.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe the experience to help your friends make their captions..."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}
