//
//  ProfileVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import Parse

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shadowLabel: UILabel!
    
    var collectionViewTitles = ["RECEIVED", "SENT", "FRIENDS"]
    var collectionViewCounts = ["---", "---", "---"]
    
    var friends = [User]()
    var sentRequests = [User]()
    var recievedRequests = [User]()
    
    @IBAction func logoutAction(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Confirm") {
            PFUser.logOut()
            //self.performSegue(withIdentifier: "unwindProfileToRegistration", sender: nil)
            self.performSegue(withIdentifier: "profileUnwind", sender: nil)
        }
        alert.showInfo("Notice", subTitle: "Are you sure you want to log out?")
        DataModel.profilePic = UIImage()
    }
    
    override func viewDidLoad() {
        setupUI()
        self.queryFriends()
    }
    
    func setupUI() {
        
        // Profile Picture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profilePicImageView.isUserInteractionEnabled = true
        profilePicImageView.addGestureRecognizer(tapGestureRecognizer)
        if DataModel.profilePic != UIImage() {
            self.profilePicImageView.image = DataModel.profilePic
        } else {
            self.profilePicImageView.image = UIImage(named: "defaultProfilePic")
        }
        
        // Collection View
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        self.collectionView.layer.cornerRadius = 3
        self.collectionView.reloadData()
        shadowLabel.layer.shadowPath = UIBezierPath(rect: shadowLabel.bounds).cgPath
        shadowLabel.layer.shadowRadius = 3
        shadowLabel.layer.shadowOffset = .zero
        shadowLabel.layer.shadowOpacity = 0.8
        
        self.usernameLabel.text = PFUser.current()?.username!
        self.profilePicImageView.layer.borderWidth = 3.0
        self.profilePicImageView.layer.borderColor = UIColor.white.cgColor
        self.profilePicImageView.layer.cornerRadius = self.profilePicImageView.frame.height/2
        self.profilePicImageView.layer.masksToBounds = true
    }
    
    func queryFriends() {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "recipient = %@", PFUser.current()!))
        predicates.append(NSPredicate(format: "sender = %@", PFUser.current()!))
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let query = PFQuery(className: "FriendRequest", predicate: predicate)
        query.includeKey("recipient")
        query.includeKey("sender")
        let requestRef = FriendRequest()
        requestRef.getRequests(query: query) { (queriedRequests) in
            print("Recieved this many requests:", queriedRequests.count)
            for request in queriedRequests {
                if request.status == "accepted" {
                    if request.reciever.objectId == PFUser.current()!.objectId {
                        print("in here!1")
                        self.friends.append(request.sender)
                    } else if request.sender.objectId == PFUser.current()!.objectId {
                        self.friends.append(request.reciever)
                        print("in here!2")
                    }
                } else if request.status == "pending" {
                    if request.reciever.objectId == PFUser.current()!.objectId! {
                        self.recievedRequests.append(request.sender)
                    } else if request.sender.objectId == PFUser.current()!.objectId! {
                        self.sentRequests.append(request.reciever)
                    }
                }
                if request === queriedRequests.last {
                    self.collectionViewCounts[2] = String(describing: self.friends.count)
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionViewTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProfileCollectionViewCell
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectionViewTapped(tapGestureRecognizer:)))
        tapGestureRecognizer.accessibilityLabel = collectionViewTitles[indexPath.row] + "_" + String(describing: collectionViewCounts[indexPath.row])
        cell.isUserInteractionEnabled = true
        cell.addGestureRecognizer(tapGestureRecognizer)
        cell.titleLabel.text = collectionViewTitles[indexPath.row]
        cell.countLabel.text = String(describing: collectionViewCounts[indexPath.row])
        return cell
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let userRef = User()
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.profilePicImageView.image = img
            userRef.updateProfilePicture(userId: (PFUser.current()?.objectId!)!, data: img.jpegData(compressionQuality: 1.0)!)
        } else if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profilePicImageView.image = img
            userRef.updateProfilePicture(userId: (PFUser.current()?.objectId!)!, data: img.jpegData(compressionQuality: 1.0)!)
        }
        dismiss(animated:true, completion: nil)
    }
    
    @objc func collectionViewTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        var count = 0
        let stringParam = tapGestureRecognizer.accessibilityLabel
        let end = stringParam!.index(after: stringParam!.firstIndex(of: "_")!)
        count = String(stringParam![...end]).convertStringToInt()
        if (stringParam!.contains("RECEIVED")) {
            self.receivedSelected(count: count)
        } else if (stringParam!.contains("SENT")) {
            self.sentSelected(count: count)
        } else if (stringParam!.contains("FRIENDS")) {
            self.friendsSelected(count: count)
        }
    }
    
    func receivedSelected(count: Int) {
    }
    
    func sentSelected(count: Int) {
    }
    
    func friendsSelected(count: Int) {
        self.performSegue(withIdentifier: "showFriends", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFriends" {
            let targetVC = segue.destination as! FriendsVC
            targetVC.friends = self.friends
            targetVC.sentRequests = self.sentRequests
            targetVC.recievedRequests = self.recievedRequests
            print(self.friends, "friends")
            print(self.sentRequests, "sent requests")
            print(self.recievedRequests, "recieved requests")
        }
    }
    
    
}
