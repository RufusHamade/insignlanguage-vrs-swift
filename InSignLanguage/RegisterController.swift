//
//  RegisterController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 19/12/2017.
//  Copyright © 2017 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class RegisterController: UIViewController, RegisterHandler, PopupManager {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailField.text = sessionModel.name
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.confirmPasswordField.delegate = self
        self.registerButton.layer.cornerRadius = 6
        self.registerButton.clipsToBounds = true

        self.enableRegister(false)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

    func showPopupCompletion() {
        self.enableRegister(true)
    }

    func enableRegister(_ enable: Bool) {
        if enable {
            self.registerButton.isEnabled = true
            self.registerButton.alpha = 1.0
        }
        else {
            self.registerButton.isEnabled = false
            self.registerButton.alpha = 0.5
        }
    }

    @IBAction func registerClicked(_ sender: Any) {
        self.enableRegister(false)
        sessionModel.register(emailField.text!, passwordField.text!, self)
    }

    func registerOk() {
        self.performSegue(withIdentifier: "completeRegistration", sender: self)
    }

    func failure(_ message: String) {
        self.showPopup("Registration Failed", message)
    }
}

extension RegisterController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (emailField.text == "" ||
            passwordField.text == "" ||
            confirmPasswordField.text == "") {
            enableRegister(false)
            return
        }
        if (passwordField.text != confirmPasswordField.text) {
            self.showPopup("Password mismatch", "The passwords don't match.\nCorrect this to continue.")
            enableRegister(false)
            return
        }
        enableRegister(true)
    }
}
