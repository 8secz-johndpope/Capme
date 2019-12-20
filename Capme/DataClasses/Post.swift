//
//  Post.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class Post {
    
    var sender = User()
    var keywords = [String]()
    var tags = [String]()
    var description = String()
    var images = [UIImage]()
    var location = String()
    var chosenFriendIds = [String]()
    var releaseDateDict = [String : Date]()
    var isViewed = false
    
    var posts = [Post]()
    
    func isValid() -> Bool {
        print("checking valid", self.images.count > 0 && self.description.count > 9)
        print(self.images.count)
        print(self.description.count)
        let possibleDays = ["Today", "Tomorrow", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return self.images.count > 0 && self.description.count > 9 && possibleDays.contains(releaseDateDict.keys.first!)
    }
    
    func getPosts(query: PFQuery<PFObject>, completion: @escaping (_ result: [Post])->()) {
        query.findObjectsInBackground {
            (objects:[PFObject]?, error:Error?) -> Void in
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(self.posts)
                    return
                }
                for object in objects! {
                    let post = Post()
                    if let image = object["image"] as? PFFileObject {
                        image.getDataInBackground {
                            (imageData:Data?, error:Error?) -> Void in
                            if error == nil  {
                                if let finalimage = UIImage(data: imageData!) {
                                    User(user: object["sender"] as! PFUser) { (user) in
                                        post.description = object["description"] as! String
                                        post.sender = user
                                        post.images.append(finalimage)
                                        post.location = object["location"] as! String
                                        post.tags = object["tags"] as! [String]
                                        post.keywords = object["keywords"] as! [String]
                                        self.posts.append(post)
                                        if self.posts.count == objects?.count {
                                            completion(self.posts)
                                        }
                                    }
                                }
                            }
                        }
                    }   
                }
            }
        }
    }
    
    func savePost() {
        let post = PFObject(className: "Post")
        post["keywords"] = self.keywords
        post["tags"] = self.tags
        post["description"] = self.description
        // TODO figure out how to store multiple images (s3?)
        post["location"] = self.location
        post["sender"] = PFUser.current()!
        post["recipients"] = self.chosenFriendIds
        post["releaseDate"] = self.releaseDateDict[releaseDateDict.keys.first!]
        
        if let imageData = DataModel.newPost.images[0].jpegData(compressionQuality: 1.00) {
            let file = PFFileObject(name: "img.png", data: imageData)
            post["image"] = file
        }
        
        post.saveInBackground { (success, error) in
            if error == nil {
                print("Success: Saved the new post")
            }
        }
        if self === DataModel.newPost {
            DataModel.newPost = Post()
        }
        
    }
}
