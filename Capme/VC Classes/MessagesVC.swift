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

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    
    @IBAction func addCaptionAction(_ sender: Any) {
        print("Adding a caption")
        self.lowerView.addCaptionOutlet.isHidden = true
        self.lowerView.captionTextView.isHidden = false
        self.sendNewCaptionOutlet.isHidden = false
        self.lowerView.captionTextView.becomeFirstResponder()
    }
    
    @IBOutlet weak var selectedPostLowerView: PostDetailsLowerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendNewCaptionOutlet: UIButton!
    
    @IBAction func sendNewCaptionAction(_ sender: Any) {
        let newCaption = Caption()
        newCaption.captionText = self.lowerView.captionTextView.text
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        newCaption.creationDate = formatter.string(from: Date())
        newCaption.username = PFUser.current()!.username!
        newCaption.userId = PFUser.current()!.objectId!
        newCaption.favoritesCount = 0
        newCaption.isCurrentUserFavorite = false
        self.selectedPost.saveNewCaption(caption: newCaption.convertToJSON())
    }
    
    var mediaBrowser: MediaBrowserViewController!
    var posts = [Post]()
    var selectedPost = Post()
    var lowerView = PostDetailsLowerView()
    let textView = ReadMoreTextView()
    var originalTextFieldHeight: CGFloat = 0.0
    var translatioDistance: CGFloat = 0.0
    var fromDismiss = false
    var blurView = UIImageView()

    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        
        // Lower View
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.lowerView = selectedPostLowerView
        self.lowerView.captionTextView.delegate = self
        self.lowerView.captionTextView.layer.masksToBounds = true
        self.lowerView.captionTextView.layer.cornerRadius = 10
        self.lowerView.captionTextView.isHidden = true
        self.sendNewCaptionOutlet.isHidden = true
        self.lowerView.captionTextView.tintColor = UIColor.white
        
        // Table View
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
            cell.messageTextLabel.frame.origin = CGPoint(x: 110, y: cell.messageTextLabel.frame.origin.y)
            cell.composeImageView.isHidden = false
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.fromDismiss = true
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
            let scaledTransform = originalTransform.scaledBy(x: 1.0, y: 1.0)
            let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: 0.0, y: self.translatioDistance)
            self.blurView.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.lowerView.topView.transform = scaledAndTranslatedTransform
                self.textView.transform = scaledAndTranslatedTransform
            }, completion: {
                (value: Bool) in
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
            })
        }
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
    
     func textViewDidBeginEditing(_ textView: UITextView) {
         if textView.textColor == UIColor.systemGray {
             textView.text = nil
             textView.textColor = UIColor.black
         }
     }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty && textView.textColor != UIColor.systemGray {
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendActive"), for: .normal)
        } else {
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendInactive"), for: .normal)
        }
    }
     
     func textViewDidEndEditing(_ textView: UITextView) {
         if textView.text.isEmpty {
             textView.text = "Add a caption..."
             textView.textColor = UIColor.systemGray
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendInactive"), for: .normal)
         }
     }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("text", text)
        if text == "\n" {
            print("should close...?")
            self.lowerView.captionTextView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        print("keyboard is showing")
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        print("made it this far")
        let keyboardFrame = keyboardSize.cgRectValue
        self.lowerView.frame.origin.y -= keyboardFrame.height
     }

    @objc func keyboardWillHide(notification: Notification){
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height
         self.lowerView.frame.origin.y += keyboardHeight!
    }
    
}
