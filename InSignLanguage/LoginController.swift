//
//  LoginController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 20/04/2017.
//
//

import UIKit

class LoginController: UIViewController, SessionHandler {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginErrors: UILabel!
    @IBOutlet weak var qqqServer: UITextField!
    
    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameField.text = sessionModel.name
        nameField.delegate = self
        passwordField.delegate = self
        qqqServer.delegate = self

        qqqServer.text = sessionModel.server
        sessionModel.setSessionHandler(self)
        onCredentialsChange()
        sessionModel.checkToken()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func onAuthSuccess() {
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
        self.performSegue(withIdentifier: "loginSuccess", sender: self)
    }

    func onAuthFailure(_ reason: String) {
        loginErrors.isHidden = false
        loginErrors.text = "Login failed: " + reason
        loginErrors.textAlignment = .center
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
        sessionModel.authenticate()
    }

    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {}
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
        else if textField == qqqServer {
            sessionModel.server = textField.text
        }
    }
}
