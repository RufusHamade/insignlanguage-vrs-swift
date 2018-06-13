import UIKit

class ChangePasswordController: UIViewController, ChangePasswordHandler, PopupManager {
    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword1: UITextField!
    @IBOutlet weak var newPassword2: UITextField!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var back: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        self.oldPassword.delegate = self
        self.newPassword1.delegate = self
        self.newPassword2.delegate = self
        self.maybeEnableSubmit()
        self.submit.layer.cornerRadius = 5;
        self.submit.clipsToBounds = true;

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.oldPassword.text = ""
        self.newPassword1.text = ""
        self.newPassword2.text = ""

        if self.sessionModel.isProfileOk() {
            self.back.setTitle("Back", for: .normal)
        }
        else {
            self.back.setTitle("Logout", for: .normal)
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func maybeEnableSubmit() {
        if (self.oldPassword.text != nil && self.oldPassword.text != "" &&
            self.newPassword1.text != nil && self.newPassword1.text != "" &&
            self.newPassword2.text != nil && self.newPassword2.text != "" &&
            self.newPassword1.text == self.newPassword2.text) {
            self.submit.isEnabled = true
            self.submit.alpha = 1.0
        }
        else {
            self.submit.isEnabled = false
            self.submit.alpha = 0.5
        }
    }

    func checkPasswordsMatch() {
        if (self.newPassword1.text != nil && self.newPassword1.text != "" &&
            self.newPassword2.text != nil && self.newPassword2.text != "") {
            if self.newPassword1.text != self.newPassword2.text {
                self.showPopup("Password Mismatch", "New passwords don't match.  Please reenter.")
            }
        }
    }

    @IBAction func submitClicked(_ sender: Any) {
        self.submit.isEnabled = false
        self.submit.alpha = 0.5
        self.sessionModel.changePassword(self.oldPassword.text!, self.newPassword1.text!, self)
    }

    @IBAction func backClicked(_ sender: Any) {
        if self.sessionModel.isProfileOk() {
            self.parent?.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
        }
        else {
            sessionModel.logout()
            self.parent?.performSegue(withIdentifier: "unwindToLogin", sender: self)
        }
    }

    func changePasswordOk() {
        self.showPopup("Success", "Password updated successfully")
    }

    func failure(_ message: String) {
        self.showPopup("Password Change Failed", message)
        self.submit.isEnabled = true
        self.submit.alpha = 1.0

    }
}

extension ChangePasswordController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.newPassword1 || textField == self.newPassword2 {
            self.checkPasswordsMatch()
        }
        self.maybeEnableSubmit()
    }
}
