import UIKit

class BillingDetailsController: UIViewController {

    @IBOutlet weak var back: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        if self.sessionModel.isProfileOk() {
            self.back.setTitle("Back", for: .normal)
        }
        else {
            self.back.setTitle("Logout", for: .normal)
        }
    }

    func dismissKeyboard() {
        view.endEditing(true)
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
}
