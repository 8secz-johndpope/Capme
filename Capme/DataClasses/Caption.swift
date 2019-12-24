//
//  Caption.swift
//  Capme
//
//  Created by Gabe Wilson on 12/22/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//


import Foundation
import Parse

class Caption: Codable {
    
    // New Caption Creator
    var userId = String()
    var username = String()
    var captionText = String()
    var creationDate = String()
    var favoritesCount = Int()
    var isCurrentUserFavorite = Bool()
    
    func convertToJSON() -> String {
        print(self.convertToString!)
        return self.convertToString!
    }
    
    func becameFavorite(captions: [Caption], username: String, captionText: String, postId: String) {
        var captionsJson = [String]()
        for caption in captions {
            if caption.username == username && caption.captionText == captionText {
                caption.favoritesCount += 1
            }
            captionsJson.append(caption.convertToJSON())
            if caption === captions.last {
                let post = PFObject(withoutDataWithClassName: "Post", objectId: postId)
                post["captions"] = captionsJson
                post.saveInBackground { (success, error) in
                    if error == nil {
                        print("Success: Incremented caption's favorites count")
                    }
                }
            }
        }
    }
    
    func unFavorite(captions: [Caption], username: String, captionText: String, postId: String) {
        print("this was the selected caption (to unfavorite)", captionText)
        var captionsJson = [String]()
        for caption in captions {
            if caption.username == username && caption.captionText == captionText {
                caption.favoritesCount -= 1
            }
            captionsJson.append(caption.convertToJSON())
            if caption === captions.last {
                let post = PFObject(withoutDataWithClassName: "Post", objectId: postId)
                post["captions"] = captionsJson
                post.saveInBackground { (success, error) in
                    if error == nil {
                        print("Success: Decremented caption's favorites count")
                    }
                }
            }
        }
    }
}
