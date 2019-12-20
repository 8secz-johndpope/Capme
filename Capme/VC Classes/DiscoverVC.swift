//
//  FeedVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var posts = [Post]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func postAction(_ sender: Any) {
        self.performSegue(withIdentifier: "showCreate", sender: nil)
    }
    
    @IBAction func discoverUnwind(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let postRef = Post()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        postRef.getPosts(query: query) { (queriedPosts) in
            self.posts = queriedPosts
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DiscoverTableViewCell
        cell.mainImageView.image = self.posts[indexPath.row].images[0]
        cell.usernameLabel.text = self.posts[indexPath.row].sender.username
        cell.senderProfilePic.image = self.posts[indexPath.row].sender.profilePic
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 290.0
    }
    
    
}
