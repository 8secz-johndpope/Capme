//
//  FriendRequest.swift
//  Capme
//
//  Created by Gabe Wilson on 12/15/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class FriendRequest {
    
    var status: String!
    var sender: User!
    var receiver: User!
    var objectId: String!
    var updatedAt: Date!
    
    var requests = [FriendRequest]()
    
    func getRequestWithId(id: String, completion: @escaping (_ result: FriendRequest)->()) {
        let query = PFQuery(className: "FriendRequest")
        query.includeKey("recipient")
        query.includeKey("sender")
        query.whereKey("objectId", equalTo: id)
        print("before get")
        query.getFirstObjectInBackground { (object, error) in
            if error == nil {
                if let object = object {
                    let request = FriendRequest()
                    request.objectId = object.objectId!
                    request.status = (object["status"] as! String)
                    request.updatedAt = object.updatedAt!
                    if let sender = object["sender"] as? PFUser {
                        if let image = sender.object(forKey: "profilePic") as? PFFileObject {
                            image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                if error == nil  {
                                    if let finalimage = UIImage(data: imageData!) {
                                        request.sender = User(user: sender, image: finalimage)
                                        request.receiver = User(user: PFUser.current()!, image: UIImage(named: "defaultProfilePic")!)
                                        completion(request)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getNewReceivedRequests(query: PFQuery<PFObject>, completion: @escaping (_ result: [FriendRequest])->()) {
        query.findObjectsInBackground {
        (objects:[PFObject]?, error:Error?) -> Void in
        if let error = error {
            print("Error: " + error.localizedDescription)
        } else {
            if objects?.count == 0 || objects?.count == nil {
                print("No new objects")
                completion(self.requests)
                return
            }
            for object in objects! {
                let request = FriendRequest()
                request.objectId = object.objectId!
                request.status = (object["status"] as! String)
                request.updatedAt = object.updatedAt!
                if let sender = object["sender"] as? PFUser {
                    if sender.objectId == PFUser.current()!.objectId! {
                        request.sender = User(user: PFUser.current()!, image: DataModel.profilePic)
                        if let recipient = object["recipient"] as? PFUser {
                            if let image = recipient.object(forKey: "profilePic") as? PFFileObject {
                                image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                    if error == nil  {
                                        if let finalimage = UIImage(data: imageData!) {
                                            request.receiver = User(user: recipient, image: finalimage)
                                            self.requests.append(request)
                                            if self.requests.count == objects?.count {
                                                print(self.requests.count)
                                                completion(self.sortRequests(requestsToSort: self.requests))
                                            }
                                        }
                                    }
                                }
                            } else {
                                request.receiver = User(user: recipient, image: UIImage(named: "defaultProfilePic")!)
                                self.requests.append(request)
                                if self.requests.count == objects?.count {
                                    print(self.requests.count)
                                    completion(self.sortRequests(requestsToSort: self.requests))
                                }
                            }
                        }
                    } else {
                        request.receiver = User(user: PFUser.current()!, image: DataModel.profilePic)
                        if let image = sender.object(forKey: "profilePic") as? PFFileObject {
                            image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                if error == nil  {
                                    if let finalimage = UIImage(data: imageData!) {
                                        request.sender = User(user: sender, image: finalimage)
                                        self.requests.append(request)
                                        if self.requests.count == objects?.count {
                                            print(self.requests.count)
                                            completion(self.sortRequests(requestsToSort: self.requests))
                                        }
                                    }
                                }
                            }
                        } else {
                            request.sender = User(user: sender, image: UIImage(named: "defaultProfilePic")!)
                            self.requests.append(request)
                            if self.requests.count == objects?.count {
                                print(self.requests.count)
                                completion(self.sortRequests(requestsToSort: self.requests))
                            }
                        }
                    }
                }
                }
            
            }
        }
    }
    
    func getRequestsForCurrentUser(query: PFQuery<PFObject>, completion: @escaping (_ result: [FriendRequest])->()) {
        query.findObjectsInBackground {
            (objects:[PFObject]?, error:Error?) -> Void in
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(self.requests)
                    return
                }
                for object in objects! {
                    let request = FriendRequest()
                    request.objectId = object.objectId!
                    request.status = (object["status"] as! String)
                    request.updatedAt = object.updatedAt!
                    if let sender = object["sender"] as? PFUser {
                        if sender.objectId == PFUser.current()!.objectId! {
                            request.sender = User(user: PFUser.current()!, image: DataModel.profilePic)
                            if let recipient = object["recipient"] as? PFUser {
                                print(recipient)
                                if let image = recipient.object(forKey: "profilePic") as? PFFileObject {
                                    image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                        if error == nil  {
                                            if let finalimage = UIImage(data: imageData!) {
                                                request.receiver = User(user: recipient, image: finalimage)
                                                self.requests.append(request)
                                                if self.requests.count == objects?.count {
                                                    print(self.requests.count)
                                                    completion(self.sortRequests(requestsToSort: self.requests))
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    request.receiver = User(user: recipient, image: UIImage(named: "defaultProfilePic")!)
                                    self.requests.append(request)
                                    if self.requests.count == objects?.count {
                                        print(self.requests.count)
                                        completion(self.sortRequests(requestsToSort: self.requests))
                                    }
                                }
                            }
                        } else {
                            request.receiver = User(user: PFUser.current()!, image: DataModel.profilePic)
                            if let image = sender.object(forKey: "profilePic") as? PFFileObject {
                                image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                    if error == nil  {
                                        if let finalimage = UIImage(data: imageData!) {
                                            request.sender = User(user: sender, image: finalimage)
                                            self.requests.append(request)
                                            if self.requests.count == objects?.count {
                                                print(self.requests.count)
                                                completion(self.sortRequests(requestsToSort: self.requests))
                                            }
                                        }
                                    }
                                }
                            } else {
                                request.sender = User(user: sender, image: UIImage(named: "defaultProfilePic")!)
                                self.requests.append(request)
                                if self.requests.count == objects?.count {
                                    print(self.requests.count)
                                    completion(self.sortRequests(requestsToSort: self.requests))
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func getRequestsForAnotherUser(query: PFQuery<PFObject>, user: PFUser, completion: @escaping (_ result: [FriendRequest])->()) {
        query.findObjectsInBackground {
            (objects:[PFObject]?, error:Error?) -> Void in
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(self.requests)
                    return
                }
                for object in objects! {
                    let request = FriendRequest()
                    request.objectId = object.objectId!
                    request.status = (object["status"] as! String)
                    request.updatedAt = object.updatedAt!
                    if let sender = object["sender"] as? PFUser {
                        if sender.objectId == user.objectId! {
                            request.sender = User(user: user, image: UIImage(named: "defaultProfilePic")!)
                            if let recipient = object["recipient"] as? PFUser {
                                print(recipient)
                                if let image = recipient.object(forKey: "profilePic") as? PFFileObject {
                                    image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                        if error == nil  {
                                            if let finalimage = UIImage(data: imageData!) {
                                                request.receiver = User(user: recipient, image: finalimage)
                                                self.requests.append(request)
                                                if self.requests.count == objects?.count {
                                                    print(self.requests.count)
                                                    completion(self.sortRequests(requestsToSort: self.requests))
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    request.receiver = User(user: recipient, image: UIImage(named: "defaultProfilePic")!)
                                    self.requests.append(request)
                                    if self.requests.count == objects?.count {
                                        print(self.requests.count)
                                        completion(self.sortRequests(requestsToSort: self.requests))
                                    }
                                }
                            }
                        } else {
                            request.receiver = User(user: user, image: UIImage(named: "defaultProfilePic")!)
                            if let image = sender.object(forKey: "profilePic") as? PFFileObject {
                                image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                    if error == nil  {
                                        if let finalimage = UIImage(data: imageData!) {
                                            request.sender = User(user: sender, image: finalimage)
                                            self.requests.append(request)
                                            if self.requests.count == objects?.count {
                                                print(self.requests.count)
                                                completion(self.sortRequests(requestsToSort: self.requests))
                                            }
                                        }
                                    }
                                }
                            } else {
                                request.sender = User(user: sender, image: UIImage(named: "defaultProfilePic")!)
                                self.requests.append(request)
                                if self.requests.count == objects?.count {
                                    print(self.requests.count)
                                    completion(self.sortRequests(requestsToSort: self.requests))
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func sortRequests(requestsToSort: [FriendRequest]) -> [FriendRequest] {
        return requestsToSort.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    
    
}
