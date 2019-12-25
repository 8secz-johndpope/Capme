//
//  InspirationVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/24/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class InspirationVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var keywordsTextView: UITextView!
    @IBOutlet weak var tagsTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var keywordsLabel: UILabel!
    @IBOutlet weak var keywordsBackground: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var tagsBackground: UILabel!
    
    @IBAction func processImageAction(_ sender: Any) {
        print("processing image")
    }
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.keywordsTextView.layer.cornerRadius = 10
        self.keywordsTextView.layer.masksToBounds = true
        self.tagsTextView.layer.cornerRadius = 10
        self.tagsTextView.layer.masksToBounds = true
        //self.keywordsTextView.adjustUITextViewHeight()
        
        self.tagsLabel.frame = CGRect(x: self.keywordsTextView.frame.minX, y: self.keywordsTextView.frame.maxY + 15.0, width: self.keywordsTextView.frame.width, height: 35.0)
        self.tagsBackground.frame = CGRect(x: self.keywordsTextView.frame.minX, y: self.keywordsTextView.frame.maxY + 15.0, width: self.keywordsTextView.frame.width, height: 35.0)
        self.tagsTextView.frame = CGRect(x: self.tagsBackground.frame.minX, y:self.tagsBackground.frame.maxY - 5.0, width: self.tagsBackground.frame.width, height: 30.0)
        //self.tagsTextView.adjustUITextViewHeight()
        
        let keywords = ["key1", "key2", "key3"]
        
        createBackgroundView(textView: keywordsTextView, selectableTextArray: keywords, label: keywordsLabel)
        createBackgroundView(textView: tagsTextView, selectableTextArray: keywords, label: tagsLabel)
        
        self.scrollView.updateContentView()
    }
    
    func createBackgroundView(textView: UITextView, selectableTextArray: [String], label: UILabel) {
        var xOffset: CGFloat = 5.0
        var yOffset: CGFloat = 5.0
        var tagsBackgroundHeight: CGFloat = 0.0
        for word in selectableTextArray {
            let button = UIButton()
            button.setTitle(word, for: .normal)
            button.layer.cornerRadius = 10
            button.layer.masksToBounds = true
            button.tintColor = UIColor.white
            button.backgroundColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            button.sizeToFit()
            
            let totalWidth = label.frame.minX + xOffset + button.frame.width + 20
            if totalWidth > textView.frame.maxX - 5.0 {
                xOffset = 5.0
                yOffset += 30
            }
            button.frame = CGRect(x: label.frame.minX + xOffset, y: label.frame.maxY + yOffset, width: button.frame.width + 20, height: 25.0)
            xOffset = xOffset + button.frame.width + 5.0

            button.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            self.scrollView.addSubview(button)
            if word == selectableTextArray.last {
                tagsBackgroundHeight = button.frame.height + yOffset + 10.0
            }
        }
        textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y, width: textView.frame.width, height: tagsBackgroundHeight)
        
    }
}
