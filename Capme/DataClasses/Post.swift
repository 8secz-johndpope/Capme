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
    var createdAt = Date()
    
    var posts = [Post]()
    var messagePreviews = [MessagePreview]()
    
    func isValid() -> Bool {
        print("checking valid", self.images.count > 0 && self.description.count > 9)
        print(self.images.count)
        print(self.description.count)
        let possibleDays = ["Today", "Tomorrow", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return self.images.count > 0 && self.description.count > 9 && possibleDays.contains(releaseDateDict.keys.first!)
    }
    
    func getPostWithObjectId(id: String, completion: @escaping (_ result: Post)->()) {
        let captionRef = Caption()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("objectId", equalTo: id)
        query.getFirstObjectInBackground { (object, error) in
            if let object = object {
                let post = Post()
                if let image = object["image"] as? PFFileObject {
                    image.getDataInBackground {
                        (imageData:Data?, error:Error?) -> Void in
                        if error == nil  {
                            if let finalimage = UIImage(data: imageData!) {
                                User(user: object["sender"] as! PFUser) { (user) in
                                    post.createdAt = object.createdAt!
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
                                    print(post.sender.username, "sender username!")
                                    if let jsonCaptions = object["captions"] as? [String] {
                                        post.captions = captionRef.sortByCreatedAt(captionsToSort: self.convert(captions: jsonCaptions))
                                    }
                                    print("got to the completion", post.objectId)
                                    completion(post)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getCaptionRequestPreviews(query: PFQuery<PFObject>, completion: @escaping (_ result: [MessagePreview])->()) {
        query.findObjectsInBackground {
        (objects:[PFObject]?, error:Error?) -> Void in
            var messagePreviewDict = [String:MessagePreview]()
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(self.messagePreviews)
                    return
                }
                for object in objects! {
                    let messagePreview = MessagePreview()
                    let sender = (object["sender"] as! PFUser).objectId!
                    messagePreview.roomName = getRoomName(externalUserId: sender)
                    messagePreview.objectId = object.objectId!
                    messagePreview.previewText = object["description"] as? String
                    messagePreview.externalUser = messagePreview.getExternalUserFromRoomName(roomName: messagePreview.roomName)
                    messagePreview.date = object.createdAt!
                    messagePreview.itemType = "captionRequest"
                    messagePreview.sender = sender
                    
                    if let isViewed = object["isViewed"] as? Bool {
                        messagePreview.isViewed = isViewed
                    } else {
                        messagePreview.isViewed = false
                    }
                    
                    messagePreview.objectId = object.objectId!
                    
                    if !messagePreviewDict.keys.contains(sender) {
                        messagePreviewDict[sender] = messagePreview
                    } else {
                        if object.createdAt! > (messagePreviewDict[sender]?.date!)! {
                            messagePreviewDict[sender] = messagePreview
                        }
                    }
                    if object === objects?.last {
                        self.messagePreviews = messagePreviewDict.map({$0.value})
                        completion(self.messagePreviews)
                    }
                }
            }
        }
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
                                        post.createdAt = object.createdAt!
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
                                            post.captions = captionRef.sortByCreatedAt(captionsToSort: self.convert(captions: jsonCaptions))
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
        post["isViewed"] = false
        post["captions"] = []
        self.sender = User(user: PFUser.current()!, image: DataModel.profilePic)
        if let imageData = DataModel.newPost.images[0].jpegData(compressionQuality: 1.00) {
            let file = PFFileObject(name: "img.png", data: imageData)
            post["image"] = file
        }
        post.saveInBackground { (success, error) in
            if error == nil {
                print("Success: Saved the new post")
                
                // Save Post as Pessage
                let postMessage = PFObject(className: "Message")
                postMessage["post"] = post
                postMessage["authorName"] = PFUser.current()!.username
                postMessage["author"] = PFUser.current()!
                postMessage["recipients"] = self.chosenFriendIds
                postMessage["isViewed"] = false
                postMessage.saveInBackground { (success, error) in
                    if error == nil {
                        print("Success: Saved the Post as a Message")
                    }
                }
                
                PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["recipientIds": self.chosenFriendIds, "title": PFUser.current()?.username!, "message": self.description, "identifier" : "captionRequest", "objectId" : post.objectId]) {
                    (response, error) in
                    if error == nil {
                        print(response, "response")
                    } else {
                        print(error!.localizedDescription, "Cloud Code Push Error")
                    }
                }
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
    
    func sortByCreatedAt(postsToSort: [Post]) -> [Post] {
        return postsToSort.sorted(by: { $0.createdAt > $1.createdAt })
    }
}
