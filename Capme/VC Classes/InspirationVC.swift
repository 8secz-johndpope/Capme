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
    
    @IBOutlet weak var imageFeaturesBackground: UILabel!
    @IBOutlet weak var imageFeaturesLabel: UILabel!
    @IBOutlet weak var imageFeaturesTextView: UITextView!
    
    
    
    @IBOutlet weak var noKeywordsLabel: UILabel!
    @IBOutlet weak var noTagsLabel: UILabel!
    @IBOutlet weak var noImageFeatures: UILabel!
    
    
    @IBAction func processImageAction(_ sender: Any) {
        self.imageFeaturesBackground.isHidden = false
        self.imageFeaturesLabel.isHidden = false
        self.noImageFeatures.isHidden = false
        self.imageFeaturesTextView.isHidden = false
        if imageFeaturesButtons.count > 0 {
            self.noImageFeatures.isHidden = true
            for button in imageFeaturesButtons {
                button.isHidden = false
            }
        } else {
            self.noImageFeatures.isHidden = false
        }
        
    }
    
    var selectedPost = Post()
    
    var imageFeaturesButtons = [UIButton]()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.keywordsTextView.layer.cornerRadius = 10
        self.keywordsTextView.layer.masksToBounds = true
        self.tagsTextView.layer.cornerRadius = 10
        self.tagsTextView.layer.masksToBounds = true
        self.imageFeaturesTextView.layer.cornerRadius = 10
        self.imageFeaturesTextView.layer.masksToBounds = true
        //self.keywordsTextView.adjustUITextViewHeight()
        
        self.tagsLabel.frame = CGRect(x: self.keywordsTextView.frame.minX, y: self.keywordsTextView.frame.maxY + 15.0, width: self.keywordsTextView.frame.width, height: 35.0)
        self.tagsBackground.frame = CGRect(x: self.keywordsTextView.frame.minX, y: self.keywordsTextView.frame.maxY + 15.0, width: self.keywordsTextView.frame.width, height: 35.0)
        self.tagsTextView.frame = CGRect(x: self.tagsBackground.frame.minX, y:self.tagsBackground.frame.maxY - 5.0, width: self.tagsBackground.frame.width, height: 30.0)
        
        
        let tags = self.selectedPost.tags
        let keywords = self.selectedPost.keywords
        let generatedImageFeatures = [String]()
        
        var tagButtons = [UIButton]()
        var keywordButtons = [UIButton]()
        
        
        if keywords.count == 0 {
            self.noKeywordsLabel.isHidden = false
            self.keywordsTextView.frame = CGRect(x: self.keywordsTextView.frame.minX, y: self.keywordsTextView.frame.minY, width: self.keywordsTextView.frame.width, height: self.noKeywordsLabel.frame.height + 10)
        } else {
            keywordButtons = createBackgroundView(textView: keywordsTextView, selectableTextArray: keywords, label: keywordsLabel)
            
        }
        
        if tags.count == 0 {
            self.noTagsLabel.isHidden = false
            self.tagsTextView.frame = CGRect(x: self.tagsTextView.frame.minX, y: self.tagsTextView.frame.minY, width: self.tagsTextView.frame.width, height: 35)
        } else {
            tagButtons = createBackgroundView(textView: tagsTextView, selectableTextArray: tags, label: tagsLabel)
        }
        
        if generatedImageFeatures.count == 0 {
            //self.noImageFeatures.isHidden = false
        } else {
            imageFeaturesButtons = createBackgroundView(textView: imageFeaturesTextView, selectableTextArray: generatedImageFeatures, label: imageFeaturesLabel)
        }
        
        let distanceToShift = (self.tagsBackground.frame.minY - self.keywordsTextView.frame.maxY) - 15
        
        self.tagsBackground.frame = CGRect(x: tagsBackground.frame.origin.x, y: self.tagsBackground.frame.minY - distanceToShift, width: tagsBackground.frame.width, height: tagsBackground.frame.height)
        self.tagsLabel.frame = CGRect(x: tagsLabel.frame.origin.x, y: self.tagsLabel.frame.minY - distanceToShift, width: tagsLabel.frame.width, height: tagsLabel.frame.height)
        self.tagsTextView.frame = CGRect(x: tagsTextView.frame.origin.x, y: self.tagsTextView.frame.minY - distanceToShift, width: tagsTextView.frame.width, height: tagsTextView.frame.height)
        self.noTagsLabel.frame = CGRect(x: noTagsLabel.frame.origin.x, y: self.noTagsLabel.frame.minY - distanceToShift, width: noTagsLabel.frame.width, height: noTagsLabel.frame.height)
        
        let nextDistanceToShift = (self.imageFeaturesBackground.frame.minY - self.tagsTextView.frame.maxY) - 15
        
        self.imageFeaturesBackground.frame = CGRect(x: imageFeaturesBackground.frame.origin.x, y: self.imageFeaturesBackground.frame.minY - nextDistanceToShift, width: imageFeaturesBackground.frame.width, height: imageFeaturesBackground.frame.height)
        self.imageFeaturesLabel.frame = CGRect(x: imageFeaturesLabel.frame.origin.x, y: self.imageFeaturesLabel.frame.minY - nextDistanceToShift, width: imageFeaturesLabel.frame.width, height: imageFeaturesLabel.frame.height)
        self.imageFeaturesTextView.frame = CGRect(x: imageFeaturesTextView.frame.origin.x, y: self.imageFeaturesTextView.frame.minY - nextDistanceToShift, width: tagsTextView.frame.width, height: tagsTextView.frame.height)
        self.noImageFeatures.frame = CGRect(x: noImageFeatures.frame.origin.x, y: self.noImageFeatures.frame.minY - nextDistanceToShift, width: noImageFeatures.frame.width, height: noImageFeatures.frame.height)
        
        for button in tagButtons {
            button.frame = CGRect(x: button.frame.origin.x, y: button.frame.minY - distanceToShift, width: button.frame.width, height: button.frame.height)
        }
        
        for button in imageFeaturesButtons {
            button.isHidden = true
            button.frame = CGRect(x: button.frame.origin.x, y: button.frame.minY - nextDistanceToShift, width: button.frame.width, height: button.frame.height)
        }
        
        self.scrollView.updateContentView(addInset: 15.0)
    }
    
    func createBackgroundView(textView: UITextView, selectableTextArray: [String], label: UILabel) -> [UIButton] {
        var xOffset: CGFloat = 5.0
        var yOffset: CGFloat = 5.0
        var tagsBackgroundHeight: CGFloat = 0.0
        var result = [UIButton]()
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
            result.append(button)
        }
        textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y, width: textView.frame.width, height: tagsBackgroundHeight)
        return result
        
    }
}
