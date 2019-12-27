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
import SCLAlertView

class PostDescriptionVC: UIViewController, UITextViewDelegate, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var calendarCancelOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var locationTextfield: UITextField!
    @IBOutlet weak var calendarTextfield: UITextField!
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBOutlet weak var locationBackground: UILabel!
    @IBOutlet weak var reviewOutlet: UIButton!
    @IBOutlet weak var calendarBackground: UILabel!
    @IBOutlet weak var addTimeOutlet: UIButton!
    
    @IBAction func reviewAction(_ sender: Any) {
        if DataModel.newPost.isValid() && self.textView.textColor != UIColor.lightGray {
            self.performSegue(withIdentifier: "showReview", sender: nil)
        } else {
            let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
            let alert = SCLAlertView(appearance: appearance)
            alert.showInfo("Notice", subTitle: "Your post requires an image and a description that is at least 10 characters long", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        }
    }
    
    @IBAction func addTimeAction(_ sender: Any) {
        
        let datePicker: UIDatePicker = UIDatePicker()
        datePicker.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        //datePicker.timeZone = NSTimeZone.local
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = 5
        datePicker.frame = CGRect(x: 0, y: 100, width: 270, height: 100)
        if DataModel.newPost.releaseDateDict.keys.first! == "Today" {
            print("got to this minimum date shite")
            //let components = Calendar.current.dateComponents([.hour, .minute], from:Date())
            datePicker.minimumDate = Date()
        }
        
        let alertController = UIAlertController(title: "Choose Time on \(self.calendarTextfield.text!)", message: "The recipients of your post have until the end of the day you have chosen. You can pick an earlier time below:\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        
        alertController.view.addSubview(datePicker)
        let selectAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { _ in
            print("Selected Date: \(datePicker.date)")
            let date = datePicker.date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hour = components.hour!
            let minute = components.minute!
            
            let upDatedDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: DataModel.newPost.releaseDateDict[DataModel.newPost.releaseDateDict.keys.first!]!)
            self.addTimeOutlet.setTitle("  " + String(describing: hour) + ":" + String(describing: minute), for: .normal)
            
            print("Selected Date: \(upDatedDate)")
        
            
        })
        alertController.view.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        alertController.addAction(selectAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:{})
    }
    
    
    @IBAction func locationAction(_ sender: Any) {
        if self.locationTextfield.isFirstResponder {
            self.locationTextfield.resignFirstResponder()
        } else {
            self.locationTextfield.becomeFirstResponder()
        }
    }
    
    @IBAction func calendarAction(_ sender: Any) {
        if self.calendarTextfield.isFirstResponder {
            self.calendarTextfield.resignFirstResponder()
        } else {
            self.calendarTextfield.becomeFirstResponder()
        }
    }
    
    @IBAction func calendarCancelAction(_ sender: Any) {
        self.calendarTextfield.text = ""
        self.calendarCancelOutlet.isHidden = true
        calendarDropDown.dataSource = days
        self.calendarDropDown.show()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.locationTextfield.text = ""
        self.cancelOutlet.isHidden = true
    }
    
    // Address Completer Fields
    var datePicker:UIDatePicker = UIDatePicker()
    let locationDropDown = DropDown()
    let calendarDropDown = DropDown()
    var locations = [String]()
    var searchResults = [MKLocalSearchCompletion]()
    var searchCompleter = MKLocalSearchCompleter()
    
    var currentTextfield = ""
    
    var days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    var dayDates = [String : Date]()
    
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
        
        // Location Textfield
        self.locationTextfield.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        self.locationTextfield.autocapitalizationType = .words
        self.locationTextfield.delegate = self
        self.locationTextfield.textColor = .lightGray
        self.setupLocationDropDown()
        self.locationTextfield.addTarget(self, action: #selector(PostDescriptionVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        self.locationTextfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: self.locationTextfield.frame.height))
        self.locationTextfield.leftViewMode = .always
        self.locationBackground.layer.cornerRadius = 10.0
        self.locationBackground.layer.masksToBounds = true
        
        // Calendar Textfield
        var weekdayDates = [String : Date]()
        var weekdays = ["Today"]
        var today = Date().endOfDay
        if (today.hours(from: Date()) < 4) {
            weekdays[0] = "Tomorrow"
            today = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        }
        weekdayDates[weekdays[0]] = today
        for i in 1...6 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: today)
            let weekday = date!.getWeekDay()
            weekdays.append(weekday)
            weekdayDates[weekday] = date!
        }
        print(weekdays)
        self.days = weekdays
        self.dayDates = weekdayDates
        self.calendarTextfield.tintColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
        self.calendarTextfield.delegate = self
        self.calendarTextfield.textColor = .lightGray
        self.calendarBackground.layer.cornerRadius = 10.0
        self.calendarBackground.layer.masksToBounds = true
        self.calendarTextfield.addTarget(self, action: #selector(PostDescriptionVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        self.calendarTextfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: self.calendarTextfield.frame.height))
        self.calendarTextfield.leftViewMode = .always
        self.setupCalendarDropDown()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.calendarTextfield {
            self.currentTextfield = "calendar"
            print("custom single tap")
            calendarDropDown.dataSource = days
            self.calendarDropDown.show()
        } else if textField == self.locationTextfield {
            self.currentTextfield = "location"
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.textColor = UIColor.black
        textField.resignFirstResponder()
        return true
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
        locationDropDown.dataSource = locations
        locationDropDown.show()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == self.locationTextfield {
            if let text = textField.text {
                DataModel.newPost.location = text
                searchCompleter.queryFragment = text
                if text.count > 0 {
                    self.cancelOutlet.isHidden = false
                } else {
                    self.cancelOutlet.isHidden = true
                }
            }
        } else if textField == self.calendarTextfield {
            
            if let text = textField.text {
                if days.contains(text) {
                    self.calendarCancelOutlet.isHidden = false
                    self.addTimeOutlet.isHidden = false
                } else if text.count == 0 {
                    self.calendarCancelOutlet.isHidden = true
                    self.addTimeOutlet.isHidden = true
                }
                print("text changed to", text)
                let pattern = "\\b" + NSRegularExpression.escapedPattern(for: text)
                let filtered = days.filter {
                    $0.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
                }
                print("filtered", filtered)
                calendarDropDown.dataSource = filtered
                calendarDropDown.show()
            }
        }
    }
    
    func setupCalendarDropDown() {
        calendarDropDown.anchorView = self.calendarTextfield
        calendarDropDown.bottomOffset = CGPoint(x: 0, y:(calendarDropDown.anchorView?.plainView.bounds.height)!)
        calendarDropDown.width = self.locationDropDown.width
        calendarDropDown.dataSource = days
        calendarDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.calendarCancelOutlet.isHidden = false
            self.addTimeOutlet.isHidden = false
            let newPosition = self.calendarTextfield.endOfDocument
            self.calendarTextfield.selectedTextRange = self.calendarTextfield.textRange(from: newPosition, to: newPosition)
            self.calendarTextfield.textColor = UIColor.black
            self.calendarTextfield.text = item
            for (key,value) in self.dayDates {
                if key == self.calendarTextfield.text {
                    print("Date association with \(key) selected")
                    DataModel.newPost.releaseDateDict = [key : value]
                }
            }
            
            let endPosition = self.calendarTextfield.position(from: self.calendarTextfield.endOfDocument, offset: 0)
            if endPosition != nil {
                self.calendarTextfield.selectedTextRange = self.calendarTextfield.textRange(from: endPosition!, to: endPosition!)
            }
        }
        
    }
    
    func setupLocationDropDown() {
        searchCompleter.delegate = self
        locationDropDown.anchorView = self.locationTextfield
        locationDropDown.bottomOffset = CGPoint(x: 0, y:(locationDropDown.anchorView?.plainView.bounds.height)!)
        locationDropDown.dataSource = locations
        locationDropDown.width = self.locationTextfield.frame.width
        locationDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.cancelOutlet.isHidden = false
            self.locationTextfield.textColor = UIColor.black
            self.locationTextfield.text = item
            DataModel.newPost.location = item
            
            let endPosition = self.locationTextfield.position(from: self.locationTextfield.endOfDocument, offset: 0)

            if endPosition != nil {
                self.locationTextfield.selectedTextRange = self.locationTextfield.textRange(from: endPosition!, to: endPosition!)
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) { //Handle the text changes here
        DataModel.newPost.description = textView.text
    }
    
}


