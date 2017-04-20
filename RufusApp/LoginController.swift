//
//  LoginController.swift
//  RufusApp
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 20/04/2017.
//
//

import UIKit

class LoginController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginErrors: UILabel!
    @IBOutlet weak var dialButton: UIButton!
    
    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameField.text = sessionModel.name
        nameField.delegate = self
        passwordField.delegate = self

        sessionModel.setOnAuthChange(self.onAuthChange)
        sessionModel.setOnAuthFailure(self.onAuthFailure)
        onAuthChange()
    }

    func onAuthChange() {
        // Set up the UI accodring to the session state
        if sessionModel.loginState == SessionModel.LoginState.authenticated {
            nameField.isEnabled = false
            passwordField.isEnabled = false
            loginButton.isEnabled = true
            loginButton.alpha = 1.0
            loginButton.setTitle("Logout", for: .normal)
            dialButton.isEnabled = true
            dialButton.alpha = 1.0
        }
        else {
            nameField.isEnabled = true
            passwordField.isEnabled = true
            if sessionModel.isAuthenticable() {
                loginButton.isEnabled = true
                loginButton.alpha = 1.0
            }
            else {
                loginButton.isEnabled = false
                loginButton.alpha = 0.5
            }
            loginButton.setTitle("Login", for: .normal)
            dialButton.isEnabled = false
            dialButton.alpha = 0.5
        }
    }
    
    func onAuthFailure(_ reason: String) {
        loginErrors.isHidden = false
        loginErrors.text = "Login failed: " + reason
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        loginErrors.isHidden = true
        loginButton.isEnabled = false
        loginButton.alpha = 0.5
        if loginButton.titleLabel?.text == "Login" {
            sessionModel.authenticate()
        }
        else {
            sessionModel.logout()
        }
    }
}

extension LoginController: UITextFieldDelegate {
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == nameField {
            sessionModel.setName(textField.text)
        }
        else if textField == passwordField {
            sessionModel.setPassword(textField.text)
        }
    }
}
