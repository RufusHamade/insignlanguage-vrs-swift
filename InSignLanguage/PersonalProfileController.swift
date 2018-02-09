import UIKit

class PersonalProfileController: UIViewController, ActionHandler {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var mobile: UITextField!
    @IBOutlet weak var address1: UITextField!
    @IBOutlet weak var address2: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var postcode: UITextField!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var messages: UILabel!
    @IBOutlet weak var back: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

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

    @IBAction func submitClicked(_ sender: Any) {
    }

    func done(_ success: Bool, _ message: String?) -> Void {
        self.messages.isHidden = false

        if !success {
            self.messages.text = "Update failed: " + message!
            self.messages.textColor = .red
            self.submit.isEnabled = true
            self.submit.alpha = 1.0
        }
        else {
            self.messages.text = "Update succeeded"
            self.messages.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
            // TODO: Segue to next scene
        }
    }

}

extension PersonalProfileController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
}
