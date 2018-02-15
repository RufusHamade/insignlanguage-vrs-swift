//
//  LoginController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 20/04/2017.
//
//

import UIKit

class LoginController: UIViewController, AuthenticateHandler, SessionHandler, GetPersonalProfileHandler {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginErrors: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameField.text = sessionModel.name
        nameField.delegate = self
        passwordField.delegate = self
        sessionModel.setSessionHandler(self)
        onCredentialsChange()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func authenticateOk() {
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
        self.sessionModel.getPersonalProfile(self)
    }

    func getPersonalProfileOk() {
        if self.sessionModel.isProfileOk() {
            self.performSegue(withIdentifier: "loginSuccess", sender: self)
        }
        else {
            self.performSegue(withIdentifier: "returnToPersonalDetails", sender: self)
        }
    }

    func failure(_ reason: String) {
        loginErrors.isHidden = false
        loginErrors.text = "Login failed: " + reason
        onCredentialsChange()
    }

    func onCredentialsChange() {
        if (sessionModel.isAuthenticable()) {
            loginButton.isEnabled = true
            loginButton.alpha = 1
        }
        else {
            loginButton.isEnabled = false
            loginButton.alpha = 0.5
        }
    }

    @IBAction func loginClicked(_ sender: Any) {
        loginErrors.isHidden = true
        loginButton.isEnabled = false
        loginButton.alpha = 0.5
        sessionModel.authenticate(self)
    }

    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {
        // May have got here via register page, so make sure nameField
        // is up-to-date
        nameField.text = sessionModel.name
    }
}

extension LoginController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.nameField {
            sessionModel.setName(textField.text)
        }
        else if textField == self.passwordField {
            sessionModel.setPassword(textField.text)
        }
    }
}
