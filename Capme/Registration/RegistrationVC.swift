//
//  ViewController.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//


import UIKit
import SimpleAnimation
import Parse

class RegistrationVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var submitLoginSignUpOutlet: UIButton!
    @IBOutlet weak var loginSignUpOutlet: UIButton!
    @IBOutlet weak var toggleLoginSignUpOutlet: UIButton!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var confirmPasswordLine: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    
    @IBAction func submitLoginSignUpAction(_ sender: Any) {
        print("Submitting Login/Sign Up")
        if confirmPasswordTextField.isHidden {
            login()
        } else {
            signUp()
        }
    }
    
    @IBAction func registrationUnwind(segue: UIStoryboardSegue) {
    }
    
    @IBAction func toggleLoginSignUpAction(_ sender: Any) {
        let yourAttributes : [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue]
        if toggleLoginSignUpOutlet.titleLabel?.text == "Already have an account?" { //Change to login layout
            submitLoginSignUpOutlet.setTitle("Login", for: .normal)
            toggleLoginSignUpOutlet.setTitle(" Create a new account? ", for: .normal)
            let attributeString = NSMutableAttributedString(string: "Sign Up", attributes: yourAttributes)
            loginSignUpOutlet.setAttributedTitle(attributeString, for: .normal)
            confirmPasswordLabel.isHidden = true
            confirmPasswordTextField.isHidden = true
            confirmPasswordLine.isHidden = true
            passwordTextField.returnKeyType = .go
        } else { //Change to Sign Up layout
            submitLoginSignUpOutlet.setTitle("Sign Up", for: .normal)
            toggleLoginSignUpOutlet.setTitle("Already have an account?", for: .normal)
            let attributeString = NSMutableAttributedString(string: "Login", attributes: yourAttributes)
            loginSignUpOutlet.setAttributedTitle(attributeString, for: .normal)
            confirmPasswordLabel.isHidden = false
            confirmPasswordTextField.isHidden = false
            confirmPasswordLine.isHidden = false
            passwordTextField.returnKeyType = .next
        }
        textFieldDidChange()
    }
    
    var fromLogout = false
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() != nil {
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if fromLogout {
            fromLogout = false
            self.tabBarController?.tabBar.isHidden = true
            self.navigationController?.navigationBar.isHidden = true
            self.backgroundImageView.isUserInteractionEnabled = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        setupUI()
    }

    func setupUI() {
        passwordTextField.tintColor = .white
        usernameTextField.tintColor = .white
        confirmPasswordTextField.tintColor = .white
        passwordTextField.textContentType = .newPassword
        passwordTextField.isSecureTextEntry = true
        submitLoginSignUpOutlet.alpha = 0.5
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        submitLoginSignUpOutlet.layer.cornerRadius = submitLoginSignUpOutlet.frame.height/2
    }
    
    func signUp() {
        let user = PFUser()
        user.username = usernameTextField.text
        user.password = passwordTextField.text
        //create parse file
        if confirmPasswordTextField.text == passwordTextField.text {
            user.signUpInBackground(block: { (success, error) in
                if success {
                    print("Success: Registered User \(user.username!)")
                    //self.setupAdminStatus()
                    self.performSegue(withIdentifier: "showTabBar", sender: nil)
                } else {
                    let signUpErrorAlertView = UIAlertController(title: "Notice", message: error!.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                    signUpErrorAlertView.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action: UIAlertAction!) in
                    }))
                    self.present(signUpErrorAlertView, animated: true, completion: nil)
                }
            })
        } else {
            let signUpErrorAlertView = UIAlertController(title: "Notice", message: "The passwords you entered do not match", preferredStyle: UIAlertController.Style.alert)
            signUpErrorAlertView.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action: UIAlertAction!) in
            }))
            self.present(signUpErrorAlertView, animated: true, completion: nil)
        }

    }
    
    func login() {
        PFUser.logInWithUsername(inBackground: usernameTextField.text!, password: passwordTextField.text!, block: { (user, error) in
            if user != nil {
                // Yes, User Exists
                self.usernameTextField.text = ""
                self.passwordTextField.text = ""
                print("Success: Logged in User \(user!.username!)")
                
                if let image = user!["profilePic"] as? PFFileObject {
                    image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                        if error == nil  {
                            if let finalimage = UIImage(data: imageData!) {
                                DataModel.profilePic = finalimage
                            }
                        }
                    }
                }
                
                
                self.performSegue(withIdentifier: "showTabBar", sender: nil)
            } else {
                // No, User Doesn't Exist
                let signUpErrorAlertView = UIAlertController(title: "Notice", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                signUpErrorAlertView.view.tintColor = UIColor.darkGray
                signUpErrorAlertView.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action: UIAlertAction!) in
                }))
                self.submitLoginSignUpOutlet.shake(toward: .right, amount: 0.03, duration: 0.5, delay: 0)
                self.present(signUpErrorAlertView, animated: true, completion: nil)
                
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == self.usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            if confirmPasswordTextField.isHidden {
                submitLoginSignUpAction(self)
            } else {
                confirmPasswordTextField.becomeFirstResponder()
            }
        } else if textField == self.confirmPasswordTextField {
            submitLoginSignUpAction(self)
        }
        return true
    }
    
    @objc func textFieldDidChange() {
        if !(usernameTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)!
            && (!(confirmPasswordTextField.text?.isEmpty)! || confirmPasswordTextField.isHidden) {
            submitLoginSignUpOutlet.alpha = 1.0
            submitLoginSignUpOutlet.isEnabled = true
        } else {
            submitLoginSignUpOutlet.alpha = 0.5
            submitLoginSignUpOutlet.isEnabled = false
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
