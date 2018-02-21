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
    @IBOutlet weak var resetResults: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.text = sessionModel.name
        emailField.delegate = self

        self.enableReset(self.emailField.text != nil && self.emailField.text != "")
        resetResults.isHidden = true

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        view.endEditing(true)
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
        resetResults.isHidden = false
        resetResults.text = "Reset succeeded.  Now check your email"
        resetResults.textColor = HAPPY_COLOR
    }

    func failure(_ message: String) {
        resetResults.isHidden = false
        resetResults.text = "Reset failed: " + message
        resetResults.textColor = .red
        self.enableReset(true)
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

