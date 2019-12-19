//
//  PostDescriptionVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import DropDown
import MapKit

class PostDescriptionVC: UIViewController, UITextViewDelegate, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var locationTextfield: UITextField!
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBOutlet weak var locationBackground: UILabel!
    
    @IBAction func locationAction(_ sender: Any) {
        if self.locationTextfield.isFirstResponder {
            self.locationTextfield.resignFirstResponder()
        } else {
            self.locationTextfield.becomeFirstResponder()
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.locationTextfield.text = ""
        self.cancelOutlet.isHidden = true
    }
    
    // Address Completer Fields
    let dropDown = DropDown()
    var locations = [String]()
    var searchResults = [MKLocalSearchCompletion]()
    var searchCompleter = MKLocalSearchCompleter()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        
        // Textview
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        self.textView.text = "Describe the experience to help your friends make the best caption..."
        self.textView.textColor = UIColor.lightGray
        self.textView.frame = CGRect(x: screenWidth/10, y: self.mainLabel.frame.maxY + 30.0, width: screenWidth - (screenWidth/5), height: self.textView.frame.height)
        self.textView.layer.cornerRadius = 10.0
        self.textView.layer.masksToBounds = true
        self.textView.delegate = self
        self.textView.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        
        // Textfield
        self.locationTextfield.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        self.locationTextfield.autocapitalizationType = .words
        self.locationTextfield.delegate = self
        self.locationTextfield.textColor = .lightGray
        self.setupDropDown()
        self.locationTextfield.addTarget(self, action: #selector(PostDescriptionVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        self.locationTextfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: self.locationTextfield.frame.height))
        self.locationTextfield.leftViewMode = .always
        self.locationBackground.layer.cornerRadius = 10.0
        self.locationBackground.layer.masksToBounds = true
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
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        locations.removeAll()
        for i in 0..<4 {
            if i < completer.results.count {
                if (completer.results[i].subtitle != "Search Nearby") {
                    
                    //print(completer.results.map { $0.title })
                    //print(completer.results.map { $0.subtitle })
                    
                    var addressSuggestion =
                        completer.results[i].title
                    if addressSuggestion.last == " " {
                        addressSuggestion.removeLast()
                    }
                    if addressSuggestion.last == "," {
                        addressSuggestion.removeLast()
                    }
                    print(addressSuggestion)
                    locations.append(addressSuggestion)
                }
            }
        }
        dropDown.dataSource = locations
        dropDown.show()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.textColor = UIColor.black
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            DataModel.newPost.location = text
            searchCompleter.queryFragment = text
            print("check here", text, text.count)
            if text.count > 0 {
                self.cancelOutlet.isHidden = false
            } else {
                self.cancelOutlet.isHidden = true
            }
        }
    }
    
    func setupDropDown() {
        searchCompleter.delegate = self
        dropDown.anchorView = self.locationTextfield
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.dataSource = locations
        dropDown.width = self.locationTextfield.frame.width
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.cancelOutlet.isHidden = false
            self.locationTextfield.textColor = UIColor.black
            self.locationTextfield.text = item
            DataModel.newPost.location = item
            let startPosition = self.locationTextfield.position(from: self.locationTextfield.beginningOfDocument, offset: 0)
            let endPosition = self.locationTextfield.position(from: self.locationTextfield.beginningOfDocument, offset: 0)

            if startPosition != nil && endPosition != nil {
                self.locationTextfield.selectedTextRange = self.locationTextfield.textRange(from: startPosition!, to: endPosition!)
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) { //Handle the text changes here
        DataModel.newPost.description = textView.text
    }
    
}
