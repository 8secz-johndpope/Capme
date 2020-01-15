//
//  User.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse


class User: Hashable {
    
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.objectId == rhs.objectId
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(objectId)
    }
    
    var objectId: String!
    var username: String!
    
    var requestId: String?
    var profilePic: UIImage?
    
    var requestSender: PFUser?
    var requestreceiver: PFUser?
    
    var pfuserRef: PFUser?
    
    var users = [User]()
    
    // For friend selection
    var isSelected = false
    
    init() {
        self.objectId = ""
        self.username = ""
        self.profilePic = UIImage()
    }
    
    init(user: PFUser, image: UIImage) {
        self.pfuserRef = user
        self.objectId = user.objectId!
        if let username = user.username {
            self.username = username
        }
        self.profilePic = image
    }
    
    init(user: PFUser, username: String, completion: @escaping (_ result: User)->()) {
        self.pfuserRef = user
        self.objectId = user.objectId!
        self.username = username
        if let image = user["profilePic"] as? PFFileObject {
            image.getDataInBackground {
                (imageData:Data?, error:Error?) -> Void in
                print("fetching the user1")
                if error == nil  {
                    if let finalimage = UIImage(data: imageData!) {
                        self.profilePic = finalimage
                        completion(self)
                    }
                }
            }
        } else {
            print("fetching the user2")
            self.profilePic = UIImage(named: "defaultProfilePic")
            completion(self)
        }
    }
    
    init(user: PFUser, completion: @escaping (_ result: User)->()) {
        self.pfuserRef = user
        self.objectId = user.objectId!
        self.username = user.username!
        if let image = user["profilePic"] as? PFFileObject {
            image.getDataInBackground {
                (imageData:Data?, error:Error?) -> Void in
                print("fetching the user1")
                if error == nil  {
                    if let finalimage = UIImage(data: imageData!) {
                        self.profilePic = finalimage
                        completion(self)
                    }
                }
            }
        } else {
            print("fetching the user2")
            self.profilePic = UIImage(named: "defaultProfilePic")
            completion(self)
        }
    }
    
    func getUsers(query: PFQuery<PFObject>, completion: @escaping (_ result: [User])->()) {
        query.findObjectsInBackground {
            (objects:[PFObject]?, error:Error?) -> Void in
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(self.users)
                    return
                }
                for object in objects as! [PFUser] {
                    if let image = object["profilePic"] as? PFFileObject {
                        image.getDataInBackground {
                            (imageData:Data?, error:Error?) -> Void in
                            if error == nil  {
                                if let finalimage = UIImage(data: imageData!) {
                                    let user = User()
                                    user.pfuserRef = object
                                    user.username = object.username!
                                    user.objectId = object.objectId!
                                    user.profilePic = finalimage
                                    self.users.append(user)
                                    if self.users.count == objects?.count {
                                        print(self.users.count)
                                        completion(self.users)
                                    }
                                }
                            }
                        }
                    } else {
                        let user = User()
                        user.pfuserRef = object
                        user.username = object.username!
                        user.objectId = object.objectId!
                        user.profilePic = UIImage(named: "defaultProfilePic")
                        self.users.append(user)
                        if self.users.count == objects?.count {
                            print(self.users.count)
                            completion(self.users)
                        }
                    }
                }
            }
        }
    }
    
    func updateProfilePicture(userId: String, data: Data) {
        if let currentUser = PFUser.current() {
            currentUser["profilePic"] = PFFileObject(name: userId + ".png", data: data)
            currentUser.saveInBackground { (success, error) in
                if error == nil {
                    print("Success: Update user profile picture")
                }
            }
        }
    }
    
    func getUsernameFromFriendId(id: String) -> String {
        if id == PFUser.current()?.objectId! {
            return PFUser.current()!.username!
        }
        if let i = DataModel.friends.firstIndex(where: { $0.objectId == id }) {
            return DataModel.friends[i].username
        }
        return ""
    }
    

}
