//
//  PostImageVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import TLPhotoPicker
import ATGMediaBrowser
import SCLAlertView

class PostImageVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TLPhotosPickerViewControllerDelegate, MediaBrowserViewControllerDataSource {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addActionOutlet: UIButton!
    @IBOutlet weak var reviewOutlet: UIButton!
    @IBOutlet weak var addImageOutlet: UIButton!
    
    
    @IBAction func reviewAction(_ sender: Any) {
        if DataModel.newPost.isValid() {
            self.performSegue(withIdentifier: "showReview", sender: nil)
        } else {
            let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
            let alert = SCLAlertView(appearance: appearance)
            alert.showInfo("Notice", subTitle: "Your post requires an image and a description that is at least 10 characters long", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        }
    }
    
    @IBAction func addImageAction(_ sender: Any) {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
    }
    
    var selectedAssets = [TLPHAsset]()
    
    override func viewDidLoad() {
        print("In AddImageVC")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func imageViewSelected(fromAction: Bool) {
        if self.addActionOutlet.titleLabel?.text == "PHOTO LIBRARY" || !fromAction {
            print("trying to add image")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.view.tintColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            
            let messageAttrString = NSMutableAttributedString(string: "Choose Image", attributes: nil)
            
            alert.setValue(messageAttrString, forKey: "attributedMessage")

            alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { _ in
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
            
        } else if self.addActionOutlet.titleLabel?.text == "REVIEW" {
            print("Reviewing...")
            self.performSegue(withIdentifier: "showReview", sender: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = img
        } else if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = img
        }
        self.addActionOutlet.setTitle("REVIEW", for: .normal)
        dismiss(animated:true, completion: nil)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let mediaBrowser = MediaBrowserViewController(dataSource: self)
        present(mediaBrowser, animated: true, completion: nil)
        //imageViewSelected(fromAction: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReview" {
            print("Segue: AddImageVC -> PropertyDetailsVC")
            
        }
    }
}

extension PostImageVC {
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        if withTLPHAssets.count > 0 {
            self.selectedAssets = withTLPHAssets
            if let images = withTLPHAssets.map({ $0.fullResolutionImage }) as? [UIImage] {
                self.imageView.image = images[0]
                DataModel.newPost.images = images
                if DataModel.newPost.isValid() {
                    self.addImageOutlet.isHidden = false
                }
            }
        }
    }
    
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        self.selectedAssets.count
        // return number of images to be shown
    }

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        
        // Fetch the required image here. Pass it to the completion
        // block along with the index, zoom scale, and error if any.
        completion(index, selectedAssets[index].fullResolutionImage, ZoomScale.default, nil)
    }
}

