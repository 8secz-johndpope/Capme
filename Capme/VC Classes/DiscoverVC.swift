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
import NVActivityIndicatorView
import ATGMediaBrowser
import FloatingPanel
import WLEmptyState
import SCLAlertView

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource, WLEmptyStateDelegate, WLEmptyStateDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func postAction(_ sender: Any) {
        if DataModel.friends.count > 0 {
            self.performSegue(withIdentifier: "showCreate", sender: nil)
        } else {
            let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
            let alert = SCLAlertView(appearance: appearance)
            alert.addButton("Add Friends") {
                self.tabBarController?.selectedIndex = 2
            }
            alert.addButton("Invite Contacts") {
                let items: [Any] = ["Join me on Capme! This app helps friends build one another the best captions!", URL(string: "https://www.linkedin.com/in/gabriel-wilson-2b480914b/")!]
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                self.present(ac, animated: true)
            }
            alert.showInfo("Notice", subTitle: "Add friends to send caption requests", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        }
        
    }
    
    @IBAction func discoverUnwind(segue: UIStoryboardSegue) {
        if segue.identifier == "discoverUnwind" {
            print("Created new caption")
            self.tableView.reloadData()
        }
    }
    
    var posts = [Post]()
    var selectedUser = User()
    var selectedPost = Post()
    var mediaBrowser: MediaBrowserViewController!
    let fpc = FloatingPanelController()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.viewControllers?[0].tabBarItem.badgeValue = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if DataModel.pushId == "friendRequest" {
            DataModel.pushId = ""
            self.tabBarController?.selectedIndex = 2
            let navController = self.tabBarController?.viewControllers![2] as! UINavigationController
            let profileVC = navController.viewControllers[0] as! ProfileVC
            profileVC.performSegue(withIdentifier: "showFriends", sender: nil)
        } else if DataModel.pushId == "captionRequest" {
            DataModel.pushId = ""
            if let badgeValue = self.tabBarController!.tabBar.items?[1].badgeValue,
                let value = Int(badgeValue) {
                tabBarController!.tabBar.items?[1].badgeValue = String(value + 1)
            } else {
                tabBarController!.tabBar.items?[1].badgeValue = "1"
            }
        } else if DataModel.pushId == "newMessage" {
            AppDelegate().queryFriends()
        }
    }
    
    func setupUI() {
        
        // Refresh Controller
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))]
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new posts...", attributes: attributes)
        refreshControl.tintColor = #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1)
        refreshControl.addTarget(self, action: #selector(startRefresh), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Table View
        self.tableView.separatorColor = UIColor.clear
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let postRef = Post()
        let query = PFQuery(className: "Post")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        query.includeKey("sender")
        postRef.getPosts(query: query) { (queriedPosts) in
            if queriedPosts.count == 0 {
                self.tableView.backgroundColor = UIColor.white
                self.tableView.emptyStateDataSource = self
            }
            self.posts = postRef.sortByReleaseDate(postsToSort: queriedPosts)
            self.tableView.reloadData()
        }
        
        DataModel.tabBarController = tabBarController!
        
    }
    
    @objc func startRefresh(sender:AnyObject) {
        print("Refreshing...")
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(endRefresh), userInfo: nil, repeats: false)
    }
    
    @objc func endRefresh() {
        print("End Refreshing...")
        self.refreshControl.endRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func getSelectedUser(userId: String) {
        let user = PFUser(withoutDataWithClassName: "_User", objectId: userId)
        user.fetchIfNeededInBackground { (user, error) in
            if error == nil {
                if let queriedUser = user as? PFUser {
                    self.selectedUser = User(user: queriedUser, completion: { (queriedUser) in
                        self.performSegue(withIdentifier: "showProfile", sender: nil)
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedPost = self.posts[indexPath.row]
        mediaBrowser = MediaBrowserViewController(dataSource: self)
        present(mediaBrowser, animated: true, completion: nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let tempVC : CaptionsVC = mainStoryboard.instantiateViewController(withIdentifier: "captionsVC") as! CaptionsVC
        tempVC.discoverRef = self
        tempVC.fromDiscover = true
        tempVC.postId = self.posts[indexPath.row].objectId
        tempVC.mediaBrowserRef = mediaBrowser
        tempVC.captions = self.posts[indexPath.row].captions
        tempVC.view.layer.cornerRadius = 10.0
        tempVC.view.layer.masksToBounds = true
        fpc.set(contentViewController: tempVC)
        DataModel.captionsVC = tempVC
        fpc.isRemovalInteractionEnabled = true
        mediaBrowser.present(fpc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.posts[indexPath.row].captions.count == 0 {
            return 294.0
        } else if self.posts[indexPath.row].captions.count == 1 {
            return 347.0
        } else if self.posts[indexPath.row].captions.count == 2 {
            return 401.0
        } else if self.posts[indexPath.row].captions.count >= 3 {
            return 454.0
        }
        return 0.0
    }
    
    func showFavorites(cell: DiscoverTableViewCell) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                cell.firstCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                cell.secondCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                cell.thirdCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                print("starting translation")
            }, completion: {
                (value: Bool) in
                print("completed the translation")
                cell.firstCaptionView.favoritesCountLabel.isHidden = false
                cell.secondCaptionView.favoritesCountLabel.isHidden = false
                cell.thirdCaptionView.favoritesCountLabel.isHidden = false
            })
        }
    }
    
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        return 1
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        completion(index, selectedPost.images[0], ZoomScale.default, nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let targetVC = segue.destination as! ProfileVC
            targetVC.selectedUser = self.selectedUser
            targetVC.fromSelectedUser = true
        }
    }
    
}

extension DiscoverVC {
    
    func saveFavorite(indexPathRow: Int, captionNumber: Int) {
        if DataModel.favoritedPosts[self.posts[indexPathRow].objectId] == self.posts[indexPathRow].captions[captionNumber].username + "*" + self.posts[indexPathRow].captions[captionNumber].captionText {
            DataModel.favoritedPosts.removeValue(forKey: self.posts[indexPathRow].objectId)
        }
        DataModel.favoritedPosts[self.posts[indexPathRow].objectId] = self.posts[indexPathRow].captions[captionNumber].username + "*" + self.posts[indexPathRow].captions[captionNumber].captionText
        
        // TODO add logic to determine if sending a push is really necessary (time elapsed and favorite still is true)
        // Don't send a push if the user has recieved a ton recently
        print("favorited Caption ID!")
        PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["recipientIds": [self.posts[indexPathRow].captions[captionNumber].userId], "title": "", "message": "\(PFUser.current()!.username!) favorited your caption", "identifier" : "favoritedCaption", "objectId" : self.posts[indexPathRow].objectId]) {
            (response, error) in
            if error == nil {
                print("Success: Pushed the notification for favoritedCaption")
            } else {
                print(error?.localizedDescription, "Cloud Code Push Error")
            }
        }
    }
    
    func unsaveFavorite(indexPathRow: Int, captionNumber: Int) {
        DataModel.favoritedPosts.removeValue(forKey: self.posts[indexPathRow].objectId)
        print("removed", DataModel.favoritedPosts)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DiscoverTableViewCell
        cell.mainImageView.image = self.posts[indexPath.row].images[0]
        cell.usernameOutlet.setTitle(self.posts[indexPath.row].sender.username, for: .normal)
        cell.profilePicOutlet.setImage(self.posts[indexPath.row].sender.profilePic, for: .normal)
        cell.dateLabel.text = self.posts[indexPath.row].releaseDateDict[self.posts[indexPath.row].releaseDateDict.keys.first!]!.timeAgo()
        cell.firstCaptionView.favoriteButtonOutlet.accessibilityLabel = "1"
        cell.secondCaptionView.favoriteButtonOutlet.accessibilityLabel = "2"
        cell.thirdCaptionView.favoriteButtonOutlet.accessibilityLabel = "3"
        
        cell.firstCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[0].userId)
        }
        
        cell.secondCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[1].userId)
        }
        
        cell.thirdCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[2].userId)
        }
        
        let currentPostCaptions = self.posts[indexPath.row].captions
        
        cell.profilePicAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].sender.objectId)
        }
        
        cell.senderUsernameAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].sender.objectId)
        }
        
        cell.firstCaptionView.favoriteAction = { [unowned self] in
            if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)

                if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                
                self.saveFavorite(indexPathRow: indexPath.row, captionNumber: 0)
                self.posts[indexPath.row].captions[0].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                self.unsaveFavorite(indexPathRow: indexPath.row, captionNumber: 0)
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                
            }
        }
        
        cell.secondCaptionView.favoriteAction = { [unowned self] in
            if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)
                
                if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                self.saveFavorite(indexPathRow: indexPath.row, captionNumber: 1)
                self.posts[indexPath.row].captions[1].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                self.unsaveFavorite(indexPathRow: indexPath.row, captionNumber: 1)
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
            }
        }
        
        cell.thirdCaptionView.favoriteAction = { [unowned self] in
            if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)
                
                if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                self.saveFavorite(indexPathRow: indexPath.row, captionNumber: 2)
                self.posts[indexPath.row].captions[2].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                self.unsaveFavorite(indexPathRow: indexPath.row, captionNumber: 2)
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
            }
        }
        
        if self.posts[indexPath.row].captions.count == 0 {
            cell.firstCaptionView.isHidden = true
            cell.dateLabel.text = "Pending Captions"
        } else {
            cell.firstCaptionView.isHidden = false
            cell.dateLabel.text = self.posts[indexPath.row].releaseDateDict[self.posts[indexPath.row].releaseDateDict.keys.first!]!.timeAgo()
        }
        
        if self.posts[indexPath.row].captions.count > 0 {
            let caption = self.posts[indexPath.row].captions[0]
            cell.firstCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            
            cell.firstCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.firstCaptionView.captionLabel.text = caption.captionText
            
            if self.posts[indexPath.row].captions.count == 1 {
                cell.secondCaptionView.isHidden = true
                cell.thirdCaptionView.isHidden = true
            }
        }
        
        if self.posts[indexPath.row].captions.count > 1 {
            let caption = self.posts[indexPath.row].captions[1]
            cell.secondCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            cell.secondCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.secondCaptionView.captionLabel.text = caption.captionText
            if self.posts[indexPath.row].captions.count == 2 {
                cell.secondCaptionView.isHidden = false
                cell.thirdCaptionView.isHidden = true
            }
        }
        
        if self.posts[indexPath.row].captions.count > 2 {
            let caption = self.posts[indexPath.row].captions[2]
            cell.thirdCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            cell.thirdCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.thirdCaptionView.captionLabel.text = caption.captionText
            cell.secondCaptionView.isHidden = false
            cell.thirdCaptionView.isHidden = false
        }
        
        if DataModel.favoritedPosts.keys.contains(self.posts[indexPath.row].objectId) {
            if self.posts[indexPath.row].captions[0].username + "*" + self.posts[indexPath.row].captions[0].captionText == DataModel.favoritedPosts[self.posts[indexPath.row].objectId]  {
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
            } else if self.posts[indexPath.row].captions[1].username + "*" + self.posts[indexPath.row].captions[1].captionText == DataModel.favoritedPosts[self.posts[indexPath.row].objectId]   {
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
            } else if self.posts[indexPath.row].captions[2].username + "*" + self.posts[indexPath.row].captions[2].captionText == DataModel.favoritedPosts[self.posts[indexPath.row].objectId]   {
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
            }
            self.showFavorites(cell: cell)
        }
        
        return cell
    }
    
    func imageForEmptyDataSet() -> UIImage? {
        return UIImage(named: "friendsEmpty")
    }
    
    func titleForEmptyDataSet() -> NSAttributedString {
        let title = NSAttributedString(string: "Grow your captioning network!", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.init(cgColor: #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))])
        return title
    }
    
    func descriptionForEmptyDataSet() -> NSAttributedString {
        let description = "Go to your profile and more friends to see more content"
        
        let title = NSAttributedString(string: description, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        return title
    }
}
