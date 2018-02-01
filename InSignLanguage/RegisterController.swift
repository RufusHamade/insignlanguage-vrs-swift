//
//  RegisterController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 19/12/2017.
//  Copyright © 2017 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class RegisterController: UIViewController, ActionHandler {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var registerResults: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self

        self.enableRegister(false)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        sessionModel.setRegisterHandler(self)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func enableRegister(_ enable: Bool) {
        if enable {
            registerButton.isEnabled = true
            registerButton.alpha = 1.0
        }
        else {
            registerButton.isEnabled = false
            registerButton.alpha = 0.5
        }
    }

    func setResults(_ success: Bool, _ message: String) {
        if message == "" {
            registerResults.isHidden = true
            return
        }
        registerResults.isHidden = false

        if success {
            registerResults.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        }
        else {
            registerResults.textColor = .red
        }
        registerResults.text = message
    }

    @IBAction func registerClicked(_ sender: Any) {
        enableRegister(false)
        sessionModel.register(emailField.text!, passwordField.text!)
    }

    func done(_ success: Bool, _ message: String?) {
        if !success {
            enableRegister(true)
            setResults(false, "Registration failed: " + (message == nil ? "none" : message!))
            return
        }
        self.performSegue(withIdentifier: "registerSuccess", sender: self)
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
            setResults(true, "")
            enableRegister(false)
            return
        }
        if (passwordField.text != confirmPasswordField.text) {
            setResults(false, "The passwords don't match.\nCorrect this to continue.")
            enableRegister(false)
            return
        }
        setResults(true, "")
        enableRegister(true)
    }
}
