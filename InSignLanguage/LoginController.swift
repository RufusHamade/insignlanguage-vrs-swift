//
//  LoginController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 20/04/2017.
//
//

import UIKit

class LoginController: UIViewController, AuthenticateHandler, SessionHandler, GetPersonalProfileHandler, GetBillingSummaryHandler {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameField.text = sessionModel.name
        self.nameField.delegate = self
        self.loginButton.layer.cornerRadius = 6
        self.loginButton.clipsToBounds = true
        self.passwordField.delegate = self
        self.sessionModel.setSessionHandler(self)
        self.onCredentialsChange()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func showPopup(_ title: String, _ message: String) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) {
            (result : UIAlertAction) -> Void in print("You pressed OK")
        }

        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func authenticateOk() {
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
        self.sessionModel.getBillingSummary(self)
    }

    func getBillingSummaryOk() {
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
        showPopup("Login failed", reason)
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
