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
    var objectId = String()
    var captions = [Caption]()
    var releaseDate = Date()
    
    var posts = [Post]()
    
    func isValid() -> Bool {
        print("checking valid", self.images.count > 0 && self.description.count > 9)
        print(self.images.count)
        print(self.description.count)
        let possibleDays = ["Today", "Tomorrow", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return self.images.count > 0 && self.description.count > 9 && possibleDays.contains(releaseDateDict.keys.first!)
    }
    
    func getPosts(query: PFQuery<PFObject>, completion: @escaping (_ result: [Post])->()) {
        let captionRef = Caption()
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
                                        post.objectId = object.objectId!
                                        post.description = object["description"] as! String
                                        post.sender = user
                                        let releaseDate = object["releaseDate"] as! Date
                                        let releaseDateString = (object["releaseDate"] as! Date).getWeekDay()
                                        post.releaseDateDict = [releaseDateString : releaseDate]
                                        post.images.append(finalimage)
                                        post.location = object["location"] as! String
                                        post.tags = object["tags"] as! [String]
                                        post.keywords = object["keywords"] as! [String]
                                        
                                        if let jsonCaptions = object["captions"] as? [String] {
                                            print(jsonCaptions)
                                            post.captions = captionRef.sortByCreatedAt(captionsToSort: self.convert(captions: jsonCaptions))
                                            print("CHECK HERE", post.captions.count, post.description)
                                            for caption in post.captions {
                                                print(caption.captionText)
                                            }
                                        }
                                        
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
        post["captions"] = []
        self.sender = User(user: PFUser.current()!, image: DataModel.profilePic)
        if let imageData = DataModel.newPost.images[0].jpegData(compressionQuality: 1.00) {
            let file = PFFileObject(name: "img.png", data: imageData)
            post["image"] = file
        }
        post.saveInBackground { (success, error) in
            if error == nil {
                print("Success: Saved the new post")
            }
        }
    }
    
    func saveNewCaption(caption: String) {
        let post = PFObject(withoutDataWithClassName: "Post", objectId: self.objectId)
        post.addUniqueObject(caption, forKey: "captions")
        post.saveInBackground { (success, error) in
            if error == nil {
                print("Success: Saved the new caption")
            }
        }
    }
    
    func convert(captions: [String]) -> [Caption] {
        var result = [Caption]()
        let jsonDecoder = JSONDecoder()
        
        for caption in captions {
            do {
                let convertedCaption = try jsonDecoder.decode(Caption.self, from: caption.data(using: .utf8)!)
                print(convertedCaption, "Convert")
                result.append(convertedCaption)
            } catch {
                print("could not convert the caption")
            }
        }
        return result
    }
    
    func sortByReleaseDate(postsToSort: [Post]) -> [Post] {
        return postsToSort.sorted(by: { $0.releaseDate > $1.releaseDate })
    }
}
