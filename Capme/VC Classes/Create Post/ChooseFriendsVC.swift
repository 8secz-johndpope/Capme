//
//  ChooseFriendsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/19/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class ChooseFriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func doneAction(_ sender: Any) {
        let chosenFriends = DataModel.friends.filter({ $0.isSelected })
        print(chosenFriends.count)
        DataModel.newPost.chosenFriendIds = chosenFriends.map({ $0.objectId })
        DataModel.newPost.savePost()
        self.performSegue(withIdentifier: "discoverUnwind", sender: nil)
    }
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataModel.friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell
        var customUser = User()
        customUser = DataModel.friends[indexPath.row]
        cell.profilePicImageView.image = customUser.profilePic
        cell.usernameLabel.text = customUser.username
        
        if customUser.isSelected {
            cell.profilePicImageView.layer.borderWidth = 2.0
            cell.profilePicImageView.layer.borderColor = CGColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.checkMark.isHidden = false
        } else {
            cell.checkMark.isHidden = true
            cell.profilePicImageView.layer.borderWidth = 0.0
            cell.usernameLabel.font = UIFont.systemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor.lightGray
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected " + (DataModel.friends[indexPath.row].username))
        if DataModel.friends[indexPath.row].isSelected {
            DataModel.friends[indexPath.row].isSelected = false
        } else {
            DataModel.friends[indexPath.row].isSelected = true
        }
        self.tableView.reloadData()
    }
}
