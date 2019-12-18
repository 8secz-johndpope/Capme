//
//  PostHashtagsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import WSTagsField

class PostHashtagsVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var underlineLabel: UILabel!
    
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
        tagsField.placeholder = "Add a new #"
        tagsField.textDelegate = self
        self.view.addSubview(tagsField)
        textFieldEvents()
    }
}


extension PostHashtagsVC {

    fileprivate func textFieldEvents() {
        
        // Events
       tagsField.onDidAddTag = { field, tag in
           print("DidAddTag", tag.text)
       }

       tagsField.onDidRemoveTag = { field, tag in
           print("DidRemoveTag", tag.text)
       }

       tagsField.onDidChangeText = { _, text in
        print(self.tagsField.text!.prefix(1))
        if let char = text!.cString(using: String.Encoding.utf8) {
            let isBackSpace = strcmp(char, "\\b")
            if (isBackSpace == -92) {
                print("Backspace was pressed")
            } else {
                if self.tagsField.text!.prefix(1) != "#" {
                    self.tagsField.text = "#" + self.tagsField.text!
                }
            }
        }
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

}
