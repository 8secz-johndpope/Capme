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
    var isSenderFavorite = Bool()
    
    func convertToJSON() -> String {
        print(self.convertToString!)
        return self.convertToString!
    }
    
    func becameSenderFavorite(captions: inout [Caption]) {
        // Unfavorites all captions then saves selected as favorite
        for caption in captions {
            caption.isSenderFavorite = false
            if caption === captions.last {
                self.isSenderFavorite = true
            }
        }
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
    
    func sortByCreatedAt(captionsToSort: [Caption]) -> [Caption] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return captionsToSort.sorted(by: { formatter.date(from: $0.creationDate)! < formatter.date(from: $1.creationDate)! })
    }
    
    func sortByFavoritesCount(captionsToSort: [Caption]) -> [Caption] {
        return captionsToSort.sorted(by: { $0.favoritesCount > $1.favoritesCount })
    }
}
