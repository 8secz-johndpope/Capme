//
//  UserDefaults.swift
//  Capme
//
//  Created by Gabe Wilson on 1/19/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation

class Cache {
    
    func getFavoritePosts() -> [String : String] {
        let defaults = UserDefaults.standard
        var result = [String : String]()
        if let favoritePostIdDict = defaults.value(forKey: "favoritedPostIds") as? [String : String] {
            result = favoritePostIdDict
        }
        return result
    }
    
    func addFavorite(postId: String, userId: String, captionText: String) {
        var dictionary = [String:String]()
        let defaults = UserDefaults.standard
        if var favoritePostIdDict = defaults.value(forKey: "favoritedPostIds") as? [String : String] {
            favoritePostIdDict[postId] = userId + "*" + captionText
            dictionary = favoritePostIdDict
        } else {
            dictionary = [postId: userId]
        }
        defaults.setValue(dictionary, forKey: "favoritedPostIds")
        printFavoritedPostIds()
    }

    func removeFavorite(postId: String) {
        let defaults = UserDefaults.standard
        if var favoritePostIdDict = defaults.value(forKey: "favoritedPostIds") as? [String : String] {
            favoritePostIdDict.removeValue(forKey: postId)
            defaults.setValue(favoritePostIdDict, forKey: "favoritedPostIds")
        }
        printFavoritedPostIds()
    }
    
    func printFavoritedPostIds() {
        let defaults = UserDefaults.standard
        if let favoritePostIdDict = defaults.value(forKey: "favoritedPostIds") as? [String : String] {
            print("Current favorite post ids dict: ", favoritePostIdDict)
        }
    }

}

