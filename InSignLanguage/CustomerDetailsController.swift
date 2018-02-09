import UIKit

class CustomerDetailsController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
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

    @objc func adjustForKeyboard(notification: Notification) {
        let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardFrame = self.view.convert(keyboardRect!, from: nil)

        if notification.name == Notification.Name.UIKeyboardWillShow {
            var contentInset:UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            self.scrollView.contentInset = contentInset
        }
        else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
}
