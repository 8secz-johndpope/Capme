//
//  MessagesVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ATGMediaBrowser

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource {
    
    
    @IBOutlet weak var selectedPostLowerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [Post]()
    var selectedPost = Post()
    var lowerView = UIView()

    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.lowerView = selectedPostLowerView
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageTableViewCell
        cell.messageTextLabel.text = self.posts[indexPath.row].description
        cell.usernameLabel.text = self.posts[indexPath.row].sender.username
        cell.profilePicImageView.image = self.posts[indexPath.row].sender.profilePic
        if self.posts[indexPath.row].isViewed {
            cell.composeImageView.isHidden = true
            cell.messageTextLabel.frame.origin = CGPoint(x: 80, y: cell.messageTextLabel.frame.origin.y)
            cell.profilePicImageView.layer.borderWidth = 0.0
            cell.usernameLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.semibold)
            cell.usernameLabel.textColor = UIColor.black
        } else {
            cell.profilePicImageView.layer.borderWidth = 2.0
            cell.profilePicImageView.layer.borderColor = CGColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.messageTextLabel.frame.origin = CGPoint(x: cell.messageTextLabel.frame.origin.x + 30, y: cell.messageTextLabel.frame.origin.y)
            cell.composeImageView.isHidden = false
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.posts[indexPath.row].isViewed = true
        self.tableView.reloadData()
        self.selectedPost = self.posts[indexPath.row]
        let mediaBrowser = MediaBrowserViewController(dataSource: self)
        mediaBrowser.view.addSubview(self.lowerView)
        present(mediaBrowser, animated: true, completion: nil)
    }
    
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        return 1
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        completion(index, selectedPost.images[0], ZoomScale.default, nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    
}
