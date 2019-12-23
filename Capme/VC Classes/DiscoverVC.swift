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
        cell.firstCaptionView.favoriteButtonOutlet.accessibilityLabel = "1"
        cell.secondCaptionView.favoriteButtonOutlet.accessibilityLabel = "2"
        cell.thirdCaptionView.favoriteButtonOutlet.accessibilityLabel = "3"
        
        cell.firstCaptionView.favoriteAction = { [unowned self] in
            self.posts[indexPath.row].captions[0].isCurrentUserFavorite = true
            self.tableView.reloadData()
        }
        
        cell.secondCaptionView.favoriteAction = { [unowned self] in
            self.posts[indexPath.row].captions[1].isCurrentUserFavorite = true
            self.tableView.reloadData()
        }
        
        cell.thirdCaptionView.favoriteAction = { [unowned self] in
            self.posts[indexPath.row].captions[2].isCurrentUserFavorite = true
            self.tableView.reloadData()
        }
        
        print(self.posts[indexPath.row].captions.count)
        
        if self.posts[indexPath.row].captions.count > 0 {
            let caption = self.posts[indexPath.row].captions[0]
            cell.firstCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.firstCaptionView.captionLabel.text = caption.captionText
            if self.posts[indexPath.row].captions[0].isCurrentUserFavorite {
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
            }
        }
        
        if self.posts[indexPath.row].captions.count > 1 {
            let caption = self.posts[indexPath.row].captions[1]
            cell.secondCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.secondCaptionView.captionLabel.text = caption.captionText
            if self.posts[indexPath.row].captions[1].isCurrentUserFavorite {
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
            }
        }
        
        if self.posts[indexPath.row].captions.count > 2 {
            let caption = self.posts[indexPath.row].captions[1]
            cell.thirdCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.thirdCaptionView.captionLabel.text = caption.captionText
            if self.posts[indexPath.row].captions[2].isCurrentUserFavorite {
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.posts[indexPath.row].captions.count == 1 {
            return 344.0
        } else if self.posts[indexPath.row].captions.count == 2 {
            return 398.0
        } else if self.posts[indexPath.row].captions.count == 2 {
            return 452.0
        }
        return 0.0
    }
    
    
}
