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

// Handle Large Descriptions
// 1) Add gesture recognizer to the textview
// 2) Shift the text view (bottom should be right above the separator label)
// 3) Increase the size of the content view
// 4) Show less should shrink

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var selectedPostLowerView: PostDetailsLowerView!
    @IBOutlet weak var tableView: UITableView!
    
    var mediaBrowser: MediaBrowserViewController!
    var posts = [Post]()
    var selectedPost = Post()
    var lowerView = PostDetailsLowerView()
    let textView = ReadMoreTextView()
    var originalTextFieldHeight: CGFloat = 0.0
    var translatioDistance: CGFloat = 0.0
    var blurView = UIImageView()

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
        mediaBrowser = MediaBrowserViewController(dataSource: self)
        self.lowerView.descriptionTextView.text = self.selectedPost.description
        self.lowerView.descriptionTextView.isHidden = true
        
        textView.text = self.selectedPost.description
        textView.shouldTrim = true
        textView.maximumNumberOfLines = 2
        textView.font  = UIFont.systemFont(ofSize: 17.0)
        textView.backgroundColor = UIColor.black
        textView.textColor = UIColor.white
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        textView.attributedReadMoreText = NSAttributedString(string: "... More", attributes: attributes)
        textView.attributedReadLessText = NSAttributedString(string: " Less", attributes: attributes)
        textView.frame = self.lowerView.descriptionTextView.frame
        var selectTextViewGesture:UITapGestureRecognizer = UITapGestureRecognizer()
        selectTextViewGesture = UITapGestureRecognizer(target: self, action: #selector(MessagesVC.tapTextView(sender:)))
        selectTextViewGesture.delegate = self
        textView.addGestureRecognizer(selectTextViewGesture)
        self.originalTextFieldHeight = textView.frame.height
        print("new height", textView.frame.height)
        self.lowerView.addSubview(textView)
        //self.lowerView.descriptionTextView.adjustUITextViewHeight()
        self.lowerView.usernameLabel.text = self.selectedPost.sender.username
        self.lowerView.dateLabel.text = "Expires: " +  self.selectedPost.releaseDateDict.keys.first!
        
        mediaBrowser.view.addSubview(self.lowerView)
        present(mediaBrowser, animated: true, completion: nil)
    }
    
    @objc func tapTextView(sender:UITapGestureRecognizer) {
        let lastChar = self.textView.text.last!
        if lastChar == "s" { // Show less
            self.textView.showLessText()
            //self.textView.adjustUITextViewHeight()
            let screenSize = UIScreen.main.bounds
            let screenHeight = screenSize.height
            let originalTransform = self.textView.transform
            let scaledTransform = originalTransform.scaledBy(x: 1.0, y: 1.00)
            let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: 0.0, y: self.translatioDistance)
            self.blurView.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.lowerView.topView.transform = scaledAndTranslatedTransform
                self.textView.transform = scaledAndTranslatedTransform
            }, completion: {
                (value: Bool) in
                self.textView.backgroundColor = UIColor.clear
                let tempView = self.lowerView.bottomView
                self.lowerView.bottomView.removeFromSuperview()
                self.lowerView.addSubview(tempView!)
            })
        } else if lastChar == "e" {
            self.textView.backgroundColor = UIColor.black
            self.textView.showMoreText()
            self.textView.adjustUITextViewHeight()
            let screenSize = UIScreen.main.bounds
            let screenHeight = screenSize.height
            let originalTransform = self.textView.transform
            let scaledTransform = originalTransform.scaledBy(x: 1.0, y: 1.00)
                    
            
            self.translatioDistance = textView.frame.height - self.lowerView.topView.frame.maxY + 30
            
            self.blurView.isHidden = false
            let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: 0.0, y: -(textView.frame.height - self.lowerView.topView.frame.maxY + 30))
            UIView.animate(withDuration: 0.3, animations: {
                self.lowerView.topView.transform = scaledAndTranslatedTransform
                self.textView.transform = scaledAndTranslatedTransform
                //self.textView.transform = scaledAndTranslatedTransform
            })
            //self.textView.frame.origin.y = screenHeight - self.textView.frame.height
        }
        
        print(self.textView.text, "new text")
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
