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
    var reciever: User!
    
    var requests = [FriendRequest]()
    
    func getRequests(query: PFQuery<PFObject>, completion: @escaping (_ result: [FriendRequest])->()) {
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
                    request.status = (object["status"] as! String)
                    if let sender = object["sender"] as? PFUser {
                        if sender.objectId == PFUser.current()!.objectId! {
                            request.sender = User(user: PFUser.current()!, image: DataModel.profilePic)
                            if let recipient = object["recipient"] as? PFUser {
                                if let image = recipient["profilePic"] as? PFFileObject {
                                    image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                        if error == nil  {
                                            if let finalimage = UIImage(data: imageData!) {
                                                request.reciever = User(user: recipient, image: finalimage)
                                                self.requests.append(request)
                                                if self.requests.count == objects?.count {
                                                    print(self.requests.count)
                                                    completion(self.requests)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    request.reciever = User(user: recipient, image: UIImage(named: "defaultProfilePic")!)
                                    self.requests.append(request)
                                    if self.requests.count == objects?.count {
                                        print(self.requests.count)
                                        completion(self.requests)
                                    }
                                }
                            }
                        } else {
                            request.reciever = User(user: PFUser.current()!, image: DataModel.profilePic)
                            if let image = sender["profilePic"] as? PFFileObject {
                                image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                    if error == nil  {
                                        if let finalimage = UIImage(data: imageData!) {
                                            request.sender = User(user: sender, image: finalimage)
                                            self.requests.append(request)
                                            if self.requests.count == objects?.count {
                                                print(self.requests.count)
                                                completion(self.requests)
                                            }
                                        }
                                    }
                                }
                            } else {
                                request.sender = User(user: sender, image: UIImage(named: "defaultProfilePic")!)
                                self.requests.append(request)
                                if self.requests.count == objects?.count {
                                    print(self.requests.count)
                                    completion(self.requests)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
}
