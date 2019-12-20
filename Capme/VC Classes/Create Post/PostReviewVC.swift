//
//  PostReviewVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/18/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse
import SCLAlertView
import SimpleAnimation

class PostReviewVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var doneOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var lowerShadowLabel: UILabel!
    @IBOutlet weak var editNameAddressOutlet: UIButton!
    
    @IBAction func doneAction(_ sender: Any) {
        DataModel.newPost.savePost()
        self.performSegue(withIdentifier: "discoverUnwind", sender: nil)
    }
    
    @IBAction func editNameAddressAction(_ sender: Any) {
        // shake name and address
        self.addressLabel.shake(toward: .bottom, amount: 0.075, duration:1, delay: 0.1)
    }
    
    
    var attributeToEdit = ""
    var attributeType = ""
    var fromCreate = false
    var originalValue = ""
    
    var tableViewFields = [[]]
    
    var sectionHeaders = ["Details", "Address & Cost", "Size"]
    
    var collectionViewTitles = ["Image", "Edit", "Trash"]
    
    override func viewDidLoad() {
        print("In PropertiesDetailsVC")
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func propertyDetailsUnwind(segue: UIStoryboardSegue) {
        setupUI()
    }
    
    func setupUI() {
        
        // Table View UI
        self.tableView.layer.cornerRadius = 3
        self.tableView.layer.masksToBounds = true
        self.tableView.tableFooterView = UIView()
        lowerShadowLabel.layer.shadowPath = UIBezierPath(rect: lowerShadowLabel.bounds).cgPath
        lowerShadowLabel.layer.shadowRadius = 3
        lowerShadowLabel.layer.shadowOffset = .zero
        lowerShadowLabel.layer.shadowOpacity = 0.8
        
        // Image View
        let post = DataModel.newPost
        if post.images.count > 0 {
            self.postImageView.image = post.images[0]
            self.postImageView.backgroundColor = UIColor.white
        }
        
        // Cleaning the tableview data
        if DataModel.newPost.keywords.count > 1 {
            print("more than 1 keyword")
            let keywordsString = DataModel.newPost.keywords.joined(separator: ", ")
            if keywordsString.last == " " {
                self.tableViewFields[0].append("Keywords: " + keywordsString.dropLast(2))
            } else { self.tableViewFields[0].append(self.tableViewFields[0][0] = "Keywords: " + keywordsString)
            }
        } else if DataModel.newPost.keywords.count == 1 {
            self.tableViewFields[0].append("Keywords: " + DataModel.newPost.keywords[0])
        }
        
        if DataModel.newPost.tags.count > 1 {
            let hashtagsString = DataModel.newPost.tags.joined(separator: ", ")
            if hashtagsString.last == " " {
                self.tableViewFields[0].append("Hashtags: " + hashtagsString.dropLast(2))
            } else {
                self.tableViewFields[0].append("Hashtags: " + hashtagsString)
            }
        } else if DataModel.newPost.tags.count == 1 {
            self.tableViewFields[0][1] = "Hashtags: " + DataModel.newPost.tags[0]
        }
        
        if DataModel.newPost.location != "" {
            self.tableViewFields[0].append("Location: " + DataModel.newPost.location)
        }
        
        if self.tableViewFields[0].count == 0 {
            self.tableView.isHidden = true
            self.lowerShadowLabel.isHidden = true
        } else {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.reloadData()
        }
        
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        imageViewSelected()
    }
    
    func imageViewSelected() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        
        let messageAttrString = NSMutableAttributedString(string: "Choose Image", attributes: nil)
        
        alert.setValue(messageAttrString, forKey: "attributedMessage")

        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { _ in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.darkGray
        cell.textLabel?.text = (tableViewFields[indexPath.section][indexPath.row] as! String)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewFields[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewFields.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewCell()
        header.textLabel!.text = sectionHeaders[section]
        header.backgroundColor = self.navigationController?.navigationBar.barTintColor
        header.textLabel?.textColor = UIColor.white
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        return header
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
