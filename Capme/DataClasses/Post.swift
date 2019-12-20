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
    
    var keywords = [String]()
    var tags = [String]()
    var description = String()
    var images = [UIImage]()
    var location = String()
    var chosenFriendIds = [String]()
    var releaseDate = Date()
    
    func isValid() -> Bool {
        print("checking valid", self.images.count > 0 && self.description.count > 9)
        print(self.images.count)
        print(self.description.count)
        return self.images.count > 0 && self.description.count > 9
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
