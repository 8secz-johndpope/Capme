//
//  ChooseFriendsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/19/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class ChooseFriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneOutlet: UIButton!
    
    @IBAction func doneAction(_ sender: Any) {
        let chosenFriends = DataModel.friends.filter({ $0.isSelected })
        print(chosenFriends.count)
        DataModel.newPost.chosenFriendIds = chosenFriends.map({ $0.objectId })
        DataModel.newPost.savePost()
        self.performSegue(withIdentifier: "discoverUnwind", sender: nil)
    }
    
    var fromNewMessages = false
    var fromNewPost = false
    var selectedFriend = User()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        if self.fromNewMessages {
            self.doneOutlet.isHidden = true
        }
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
        if self.fromNewPost {
            print("selected " + (DataModel.friends[indexPath.row].username))
            if DataModel.friends[indexPath.row].isSelected {
                DataModel.friends[indexPath.row].isSelected = false
            } else {
                DataModel.friends[indexPath.row].isSelected = true
            }
            self.tableView.reloadData()
        } else if self.fromNewMessages {
            // perform segue to messages
            self.selectedFriend = DataModel.friends[indexPath.row]
            self.performSegue(withIdentifier: "showChatRoom", sender: nil)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "discoverUnwind" {
            let targetVC = segue.destination as! DiscoverVC
            
            let newPost = DataModel.newPost
            
            targetVC.posts.insert(newPost, at: 0)
            DataModel.newPost = Post()
        } else if segue.identifier == "showChatRoom" {
            let targetVC = segue.destination as! ChatVC
            var users = [String]()
            users.append(PFUser.current()!.objectId!)
            users.append(self.selectedFriend.objectId!)
            let sortedUsers = users.sorted { $0 < $1 }
            targetVC.roomName = sortedUsers[0] + "+" + sortedUsers[1]
            targetVC.externalUser = self.selectedFriend
            DataModel.currentRecipient = self.selectedFriend
            targetVC.currentUser = DataModel.currentUser
            print("Set the roomName:", targetVC.roomName)
            
        }
    }
}
