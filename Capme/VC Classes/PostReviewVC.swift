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
        self.performSegue(withIdentifier: "propertiesUnwind", sender: nil)
    }
    
    @IBAction func editNameAddressAction(_ sender: Any) {
        // shake name and address
        self.addressLabel.shake(toward: .bottom, amount: 0.075, duration:1, delay: 0.1)
    }
    
    
    var attributeToEdit = ""
    var attributeType = ""
    var fromCreate = false
    var originalValue = ""
    
    var tableViewFields = [["Price", "Square footage liveable", "Property Type"]]
    var attributeNames = [["Price", "Square footage liveable", "Property Type"]]
    
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
        let post = DataModel.newPost
        
        lowerShadowLabel.layer.shadowPath = UIBezierPath(rect: lowerShadowLabel.bounds).cgPath
        lowerShadowLabel.layer.shadowRadius = 3
        lowerShadowLabel.layer.shadowOffset = .zero
        lowerShadowLabel.layer.shadowOpacity = 0.8
        
        self.tableView.layer.cornerRadius = 3
        self.tableView.layer.masksToBounds = true
        
        // image view
        self.postImageView.image = post.image
        self.postImageView.backgroundColor = UIColor.white
        
        /*// name / address labels
        let nameTap = UITapGestureRecognizer(target: self, action:#selector(nameTapped(sender:)))
        self.nameLabel.addGestureRecognizer(nameTap)
        self.nameLabel.isUserInteractionEnabled = true
        self.editNameAddressOutlet.isHidden = true
        
        let addressTap = UITapGestureRecognizer(target: self, action:#selector(addressTapped(sender:)))
        //self.addressLabel.text = property.address
        self.addressLabel.addGestureRecognizer(addressTap)
        self.addressLabel.isUserInteractionEnabled = true*/
        
        // table view
        tableView.tableFooterView = UIView()
        
        let keywordsString = DataModel.newPost.keywords.joined(separator: ",")
        let hashtagsString = DataModel.newPost.tags.joined(separator: ",")
        self.tableViewFields[0][0] = "Keywords: " + keywordsString
        self.tableViewFields[0][1] = "Hashtags: " + hashtagsString
        self.tableViewFields[0][2] = "Location: " + DataModel.newPost.location
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
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
        
        alert.addAction(UIAlertAction(title: "Default", style: .default, handler: { _ in
            self.postImageView.image = UIImage(named: "cityBackground")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            DataModel.newPost.image = img
            self.postImageView.image = img
        } else if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            DataModel.newPost.image = img
            self.postImageView.image = img
        }
        dismiss(animated:true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.darkGray
        cell.textLabel?.text = tableViewFields[indexPath.section][indexPath.row]
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
        header.textLabel?.textColor = #colorLiteral(red: 0.9882352941, green: 0.8196078431, blue: 0.1647058824, alpha: 1)
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        return header
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
