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
    
    var favoritePosts: [String : String]?
    
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
                if error == nil  {
                    if let finalimage = UIImage(data: imageData!) {
                        self.profilePic = finalimage
                        completion(self)
                    }
                }
            }
        } else {
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
                if error == nil  {
                    if let finalimage = UIImage(data: imageData!) {
                        self.profilePic = finalimage
                        completion(self)
                    }
                }
            }
        } else {
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
    
    func convertPostsJsonToDict(posts: String) -> [String : String] {
        let result = [String : String]()
        if let dict = posts.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: dict, options: []) as! [String: String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return result
    }
    
    func saveNewFavoritePosts() {
        let cacheFavoritePosts = Cache().getFavoritePosts()
        if cacheFavoritePosts.count > 0 {
            
            print("Current Cache State:", cacheFavoritePosts)
            
            if var currentFavoritePostsDict = self.favoritePosts { // User has some favorite posts
                
                for favorite in cacheFavoritePosts {
                    if favorite.value != "removed" {
                        currentFavoritePostsDict[favorite.key] = favorite.value
                    } else {
                        currentFavoritePostsDict.removeValue(forKey: favorite.key)
                    }
                }
                 
                DataModel.currentUser.favoritePosts = currentFavoritePostsDict
                
                print("State used for the newsfeeed \(currentFavoritePostsDict)")
                
                if let user = pfuserRef {
                    user["favoritePosts"] = currentFavoritePostsDict.convertToString
                    user.saveInBackground { (success, error) in
                        print("Success: Updated the current user's favorite posts from the cache")
                        Cache().clearFavorites()
                    }
                }
                
            } else { // No favorite posts from Parse
                DataModel.favoritedPosts = cacheFavoritePosts
                let favoritePostsJson = favoritePosts.convertToString
                if let user = pfuserRef {
                    user["favoritePosts"] = favoritePostsJson
                    user.saveInBackground { (success, error) in
                        print("Success: Updated the current user's favorite posts from the cache")
                        Cache().clearFavorites()
                    }
                }
            }
        } else {
            print("No New Favorites")
        }
    }
    

}
