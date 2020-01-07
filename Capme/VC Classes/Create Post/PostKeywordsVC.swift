//
//  PostKeywordsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import WSTagsField
import SCLAlertView

class PostKeywordsVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var underlineLabel: UILabel!
    @IBOutlet weak var reviewOutlet: UIButton!
    
    @IBAction func reviewAction(_ sender: Any) {
        if DataModel.newPost.isValid() {
            self.performSegue(withIdentifier: "showReview", sender: nil)
        } else {
            let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
            let alert = SCLAlertView(appearance: appearance)
            alert.showInfo("Notice", subTitle: "Your post requires an image and a description that is at least 10 characters long", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        }
    }
    
    fileprivate let tagsField = WSTagsField()

    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        // Textfield
        self.textfield.delegate = self
        self.textfield.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        tagsField.frame = CGRect(x: 15.0, y: self.mainLabel.frame.maxY + 60.0, width: (self.view.frame.width - 60.0), height: 20.0)
        
        self.textfield.isHidden = true
        tagsField.spaceBetweenLines = 5.0
        tagsField.spaceBetweenTags = 10.0
        tagsField.font = .systemFont(ofSize: 17.0)
        tagsField.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        tagsField.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tagsField.backgroundColor = .clear
        tagsField.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        tagsField.textColor = .white
        tagsField.fieldTextColor = .darkGray
        tagsField.selectedColor = .lightGray
        tagsField.selectedTextColor = .darkGray
        tagsField.isDelimiterVisible = true
        tagsField.placeholderColor = .lightGray
        tagsField.placeholderAlwaysVisible = true
        tagsField.keyboardAppearance = .dark
        tagsField.returnKeyType = .next
        tagsField.acceptTagOption = .space
        tagsField.placeholder = "Add a new keyword"
        
        tagsField.textDelegate = self
        self.view.addSubview(tagsField)
        textFieldEvents()
       
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    
}


extension PostKeywordsVC {

    fileprivate func textFieldEvents() {
        
        // Events
        tagsField.onDidAddTag = { field, tag in
            print("DidAddTag", tag.text)
            DataModel.newPost.keywords.append(tag.text)
        }

        tagsField.onDidRemoveTag = { field, tag in
             print("DidRemoveTag", tag.text)
            var removeIndex = -1
            for (index, element) in  DataModel.newPost.keywords.enumerated() {
                print("Item \(index): \(element)")
                if element == tag.text {
                    removeIndex = index
                }
            }
            if removeIndex != -1 {
                DataModel.newPost.keywords.remove(at: removeIndex)
            }
        }

       tagsField.onDidChangeText = { _, text in
           print("DidChangeText")
       }

       tagsField.onDidChangeHeightTo = { _, height in
           print("HeightTo", height)
        self.underlineLabel.transform = CGAffineTransform(translationX: 0, y: (height - 44.75))
       }

       tagsField.onValidateTag = { tag, tags in
        
           // custom validations, called before tag is added to tags list
           return tag.text != "#" && !tags.contains(where: { $0.text.uppercased() == tag.text.uppercased() })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReview" {
            if let navigationVC = segue.destination as? UINavigationController, let targetVC = navigationVC.topViewController as? ChooseFriendsVC {
                targetVC.fromNewPost = true
            }
        }
    }

}
