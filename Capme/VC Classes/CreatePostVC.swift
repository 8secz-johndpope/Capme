//
//  CreatePostVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class CreatePostVC: UIViewController {
    
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nextOutlet: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBAction func nextAction(_ sender: Any) {
        if currentAttributeIndex < attributes.count - 1 {
            currentAttributeIndex += 1
            self.attributeLabel.text = "New Property " + self.attributes[currentAttributeIndex]
        } else if currentAttributeIndex == attributes.count - 1 {
            //handle review
            nextOutlet.setTitle("CONFIRM", for: .normal)
        }
    }
    
    var currentAttributeIndex = 0
    var attributes = ["Description", "Keywords", "Image"]
    
    override func viewDidLoad() {
        print("In CreatePropertyVC")
        setupUI()
    }
    
    func setupUI() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.hideKeyboardWhenTappedAround()
        self.attributeLabel.text = "New Property " + self.attributes[currentAttributeIndex]
        self.textField.placeholder = "Add a " + self.attributes[currentAttributeIndex] + "..."
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
       let keyboardHeight = keyboardSize?.height
       if #available(iOS 11.0, *) {
            self.bottomConstraint.constant = -(keyboardHeight!)
       } else {
            
             self.bottomConstraint.constant = -keyboardHeight!
           }
        self.bottomConstraint.constant = keyboardHeight!

        
        UIView.animate(withDuration: 1.5) {
            self.bottomConstraint.constant = -keyboardHeight!
         }
     }

    @objc func keyboardWillHide(notification: Notification) {
        print("hide keyboard")
        self.bottomConstraint.constant = 0 // or change according to your logic
         UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
         }
    }
}

