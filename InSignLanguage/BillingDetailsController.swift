import UIKit

class BillingDetailsController: UIViewController {

    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var logout: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
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

    @IBAction func backClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
    }

    @IBAction func logoutClicked(_ sender: Any) {
        sessionModel.logout()
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }
}
