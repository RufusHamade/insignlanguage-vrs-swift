//
//  RegisterController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 19/12/2017.
//  Copyright © 2017 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class ResetPasswordController: UIViewController, ActionHandler {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var resetResults: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.text = sessionModel.name
        emailField.delegate = self

        if emailField.text == nil || emailField.text == "" {
            resetButton.isEnabled = false
            resetButton.alpha = 0.5
        }
        else {
            resetButton.isEnabled = true
            resetButton.alpha = 1.0
        }
        resetResults.isHidden = true

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        sessionModel.setPasswordResetHandler(self)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func resetClicked(_ sender: Any) {
        resetButton.isEnabled = false
        resetButton.alpha = 0.5
        sessionModel.resetPassword(emailField.text!)
    }

    func done(_ success: Bool, _ message: String?) -> Void {
        resetResults.isHidden = false

        if !success {
            resetResults.text = "Reset failed: " + message!
            resetResults.textColor = .red
            resetButton.isEnabled = true
            resetButton.alpha = 1.0
        }
        else {
            resetResults.text = "Reset succeeded.  Now check your email"
            resetResults.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        }
    }
}

extension ResetPasswordController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.text == "") {
            resetButton.isEnabled = false
            resetButton.alpha = 0.5
        }
        else {
            resetButton.isEnabled = true
            resetButton.alpha = 1.0
        }
    }
}

