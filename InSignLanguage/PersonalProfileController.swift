import UIKit

class PersonalProfileController: UIViewController, UpdatePersonalProfileHandler, PopupManager {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var back: UIButton!

    @IBOutlet var fields: [UITextField]!
    static var FIELD_MAP = [
        "first_name",
        "last_name",
        "email",
        "phone",
        "address1",
        "address2",
        "address3",
        "postcode"
    ]
    static func getFieldIdxFromName(_ name:String) ->Int {
        for (i, v) in FIELD_MAP.enumerated() {
            if v == name {
                return i
            }
        }
        return -1
    }
    static func getNameFromIdx(_ idx: Int) -> String {
        return FIELD_MAP[idx]
    }

    var sessionModel = SessionModel.sharedInstance
    var updateSuccess = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.submit.layer.cornerRadius = 5;
        self.submit.clipsToBounds = true;

        for (i, f) in self.fields.enumerated() {
            f.delegate = self
            let n = PersonalProfileController.getNameFromIdx(i)
            if sessionModel.personalProfile[n] == nil {
                if n == "email" {
                    f.text = self.sessionModel.name
                    sessionModel.personalProfile[n] = self.sessionModel.name
                }
                else {
                    f.text = ""
                }
            }
            else {
                f.text = sessionModel.personalProfile[n]!
            }
        }

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        self.updateSuccess = false

        if self.sessionModel.isProfileOk() {
            self.back.setTitle("Back", for: .normal)
        }
        else {
            self.back.setTitle("Logout", for: .normal)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func enableSubmit(_ enable: Bool) {
        if enable {
            self.submit.isEnabled = true
            self.submit.alpha = 1.0
        }
        else {
            self.submit.isEnabled = false
            self.submit.alpha = 0.5
        }
    }

    @objc func adjustForKeyboard(notification: Notification) {
        let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardFrame = self.view.convert(keyboardRect!, from: nil)

        if notification.name == UIResponder.keyboardWillShowNotification {
            var contentInset:UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            self.scrollView.contentInset = contentInset
        }
        else {
            self.scrollView.contentInset = UIEdgeInsets.zero
        }
    }

    @IBAction func submitClicked(_ sender: Any) {
        if !self.sessionModel.isProfileOk() {
            self.showPopup("Information Missing", "You need to fill in all * fields...")
            return
        }
        self.submit.isEnabled = false
        self.submit.alpha = 0.5
        self.sessionModel.updatePersonalProfile(self)
    }

    // TODO: Logic wrong here.  Will log you out if you enter bad info then hit back.
    @IBAction func backClicked(_ sender: Any) {
        if self.sessionModel.isProfileOk() {
            self.parent?.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
        }
        else {
            sessionModel.logout()
            self.parent?.performSegue(withIdentifier: "unwindToLogin", sender: self)
        }
    }

    func updatePersonalProfileOk() {
        self.showPopup("Success", "Update succeeded")
        self.updateSuccess = true
    }

    // TODO: Make a callback, then updateSuccess not necessary
    func showPopupCompletion() {
        if self.updateSuccess {
            self.parent?.performSegue(withIdentifier: "registrationComplete", sender: self)
        }
    }

    func failure(_ message: String) {
        self.submit.isEnabled = true
        self.submit.alpha = 1.0
        self.showPopup("Update Failed", message)
    }
}

extension PersonalProfileController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        for (i, f) in self.fields.enumerated() {
            if f == textField {
                let n = PersonalProfileController.getNameFromIdx(i)
                self.sessionModel.personalProfile[n] = f.text
            }
        }
        self.submit.alpha = self.sessionModel.isProfileOk() ? 1.0 : 0.5
        self.submit.isEnabled = true
    }
}
