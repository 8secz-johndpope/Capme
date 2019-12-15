//
//  FriendsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var users = [User]()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let query = PFQuery(className: "_User")
        query.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        let userRef = User()
        userRef.getUsers(query: query) { (queriedUsers) in
            self.users = queriedUsers
            print(self.users)
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell
        cell.profilePicImageView.image = self.users[indexPath.row].profilePic
        cell.usernameLabel.text = self.users[indexPath.row].username
        cell.addFriendOutlet.accessibilityLabel = self.users[indexPath.row].objectId
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
}
