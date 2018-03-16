import UIKit

class TermsAndConditionsController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var content: UIWebView!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: sessionModel.getUrl("insignlanguage_vrs_terms_embed"))!
        let request = URLRequest(url: url)
        self.content.loadRequest(request)
    }

    @IBAction func okClicked(_ sender: Any) {
        if let ns = self.navigationController {
            ns.popViewController(animated: true)
        }
    }
}
