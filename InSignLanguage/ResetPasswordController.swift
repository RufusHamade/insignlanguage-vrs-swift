//
//  RegisterController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 19/12/2017.
//  Copyright © 2017 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class ResetPasswordController: UIViewController, ResetPasswordHandler {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var resetButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailField.text = sessionModel.name
        self.emailField.delegate = self
        self.resetButton.layer.cornerRadius = 6
        self.resetButton.clipsToBounds = true

        self.enableReset(self.emailField.text != nil && self.emailField.text != "")

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func showPopup(_ title: String, _ message: String) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) {
            (result : UIAlertAction) -> Void in self.enableReset(true)
        }

        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func enableReset(_ enable: Bool) {
        if enable {
            self.resetButton.isEnabled = true
            self.resetButton.alpha = 1.0
        }
        else {
            self.resetButton.isEnabled = false
            self.resetButton.alpha = 0.5
        }
    }

    @IBAction func resetClicked(_ sender: Any) {
        self.enableReset(false)
        self.sessionModel.resetPassword(emailField.text!, self)
    }

    func resetPasswordOk() {
        self.showPopup("Reset succeeded", "Now check your email")
    }

    func failure(_ message: String) {
        self.showPopup("Reset failed", "Now check your email")
    }
}

extension ResetPasswordController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.enableReset(textField.text != "")
    }
}

