import UIKit

class PersonalProfileController: UIViewController, UpdatePersonalProfileHandler {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var messages: UILabel!
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var logout: UIButton!

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

    override func viewDidLoad() {
        super.viewDidLoad()

        for (i, f) in self.fields.enumerated() {
            f.delegate = self
            let n = PersonalProfileController.getNameFromIdx(i)
            if sessionModel.personalProfile[n] == nil {
                f.text = ""
            }
            else {
                f.text = sessionModel.personalProfile[n]!
            }
        }

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: Notification.Name.UIKeyboardWillHide, object: nil)

        if self.sessionModel.isProfileOk() {
            self.back.isHidden = false
            self.back.isEnabled = true
            self.logout.isHidden = true
            self.logout.isEnabled = false
        }
        else {
            self.back.isHidden = true
            self.back.isEnabled = false
            self.logout.isHidden = false
            self.logout.isEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    func dismissKeyboard() {
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
        let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardFrame = self.view.convert(keyboardRect!, from: nil)

        if notification.name == Notification.Name.UIKeyboardWillShow {
            var contentInset:UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            self.scrollView.contentInset = contentInset
        }
        else {
            self.scrollView.contentInset = UIEdgeInsets.zero
        }
    }

    func showMessage(_ isError: Bool, _ message: String) {
        self.messages.isHidden = false
        self.messages.textColor = isError ? .red : UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        self.messages.text = message
    }

    @IBAction func submitClicked(_ sender: Any) {
        if !self.sessionModel.isProfileOk() {
            self.showMessage(true, "You need to fill in all * fields...")
            return
        }
        self.submit.isEnabled = false
        self.submit.alpha = 0.5
        self.showMessage(false, "Submitting...")
        self.sessionModel.updatePersonalProfile(self)
    }

    @IBAction func backClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
    }

    @IBAction func logoutClicked(_ sender: Any) {
        sessionModel.logout()
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }

    func updatePersonalProfileOk() {
        self.showMessage(false, "Update succeeded")
        // TODO: Segue to next scene
    }

    func failure(_ message: String) {
        self.submit.isEnabled = true
        self.submit.alpha = 1.0
        self.showMessage(true, "Update failed: " + message)
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
        self.messages.isHidden = true
    }
}