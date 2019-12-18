//
//  PostImageVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/17/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

import Foundation
import UIKit
import SCLAlertView

class PostImageVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addActionOutlet: UIButton!
    @IBAction func addImageAction(_ sender: Any) {
        imageViewSelected(fromAction: true)
    }
    
    func imageViewSelected(fromAction: Bool) {
        if self.addActionOutlet.titleLabel?.text == "ADD IMAGE" || !fromAction {
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
            
            alert.addAction(UIAlertAction(title: "Default", style: .default, handler: { _ in
                //DataModel.newProperty.image = UIImage(named: "cityBackground")!
                self.addActionOutlet.setTitle("REVIEW", for: .normal)
                self.imageView.image = UIImage(named: "cityBackground")
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
            
        } else if self.addActionOutlet.titleLabel?.text == "REVIEW" {
            print("Reviewing...")
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
    
    override func viewDidLoad() {
        print("In AddImageVC")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        imageViewSelected(fromAction: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReview" {
            print("Segue: AddImageVC -> PropertyDetailsVC")
            
        }
    }
}

