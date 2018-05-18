import UIKit
import Stripe

let MY_TAG = 1

class BillingDetailsController: UIViewController, GetBillingSummaryHandler, STPAddCardViewControllerDelegate {

    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var contractType: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        if self.sessionModel.isProfileOk() {
            self.back.setTitle("Back", for: .normal)
            self.sessionModel.getBillingSummary(self)
        }
        else {
            self.back.setTitle("Logout", for: .normal)
        }
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

    @IBAction func showTerms(_ sender: Any) {
        if let sb = self.storyboard, let ns = self.navigationController {
            let terms = sb.instantiateViewController(withIdentifier: "Terms")
            ns.pushViewController(terms, animated: true)
        }
    }

    func showBilling() {
        self.removeItems()
        if self.sessionModel.billingSummary == nil {
            self.contractType.text = "Not yet configured"
            return
        }

        switch self.sessionModel.billingSummary!["contract_type"]! as! String {
        case "access_to_work":
            self.contractType.text = "Access To Work client"
            self.showMonthlyUsage()
        case "pay_monthly":
            self.contractType.text = "Pay monthly"
            self.showMonthlyUsage()
        default:
            self.contractType.text = "Pay as you go"
            self.showLastMonthsUsage()
        }
    }

    func addItem(_ item: UIView) {
        item.tag = MY_TAG
        self.view.addSubview(item)
    }

    func removeItems() {
        for item in self.view.subviews {
            if item.tag == MY_TAG {
                item.removeFromSuperview()
            }
        }
    }

    func addConstraints(_ item: UIView, _ previous: UIView, _ distance: CGFloat, centered: Bool = false) {
        self.view.addConstraints([
            NSLayoutConstraint(item: item, attribute: .top,
                               relatedBy: .equal,
                               toItem: previous, attribute: .bottom,
                               multiplier: 1.0, constant: distance)
            ])
        if centered {
            item.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        }
        else {
            self.view.addConstraints([
                NSLayoutConstraint(item: item, attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: self.view, attribute: .leading,
                                   multiplier: 1.0, constant: 25.0),
                NSLayoutConstraint(item: item, attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: self.view, attribute: .trailing,
                                   multiplier: 1.0, constant: -25.0)
                ])
        }
    }

    func showMonthlyUsage() {
        let billing_period_active = self.sessionModel.billingSummary!["billing_period_active"] as! Bool
        var label:UILabel;

        if !billing_period_active {
            label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Billing has not been set up for this account.  " +
                "Please contact support@insignlanguage.co.uk to fix.  " +
                "In the meantime you can use Pay As You Go."
            label.numberOfLines = 0
            label.font = label.font.withSize(12)
            self.addItem(label)
            self.addConstraints(label, self.contractType, 20.0)
            self.showPaymentMethod(label)
            return
        }

        let total = self.sessionModel.billingSummary!["minutes_per_billing_period"] as! Int
        let minutes = self.sessionModel.billingSummary!["minutes_used_in_billing_period"] as! NSArray
        let remaining = minutes[1] as! Int
        let start = self.sessionModel.billingSummary!["billing_period_start"] as! String
        let end = self.sessionModel.billingSummary!["billing_period_end"] as! String

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        let df = SessionModel.outputDateFormatter
        let dfi = SessionModel.jsonDateParser
        label.text = String(format:"Billing period: from %@ to %@",
                            df.string(from: dfi.date(from: start)!),
                            df.string(from: dfi.date(from: end)!))
        self.addItem(label)
        self.addConstraints(label, self.contractType, 20.0)

        let previousLabel = label
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "%d minutes (of %d) remaining in this period", remaining, total)
        label.numberOfLines = 0
        self.addItem(label)
        addConstraints(label, previousLabel, 10.0)

        if remaining == 0 {
            let previousLabel = label
            label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.text = "You've used all your minutes.  But you can still Pay As You Go."
            self.addConstraints(label, previousLabel, 20.0)
            self.addItem(label)
            self.showPaymentMethod(label)
        }
    }

    func showLastMonthsUsage() {
        let minutes = self.sessionModel.billingSummary!["minutes_used_in_billing_period"] as! NSArray
        let used = minutes[0] as! Int
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "%d minutes used this month", used)
        label.numberOfLines = 0
        self.addItem(label)
        addConstraints(label, self.contractType, 10.0)
        showPaymentMethod(label)
    }

    func showPaymentMethod(_ lastlabel:UIView) {
        let card = self.sessionModel.billingSummary!["card"]

        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        if let carddata = card as? [String: String] {
            label.text = String(format: "Currently using %@: \n  XXXX XXXX XXXX %@\n  Exp %@",
                                carddata["card_type"]!,
                                carddata["last_digits"]!,
                                carddata["expires"]!)
        }
        else {
            label.text = "No card set up on the account"
        }
        self.addItem(label)
        addConstraints(label, lastlabel, 10.0)

        let button = UIButton.init(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .blue
        button.setTitle("Add new payment card", for: [])
        button.addTarget(self, action: #selector(self.handleAddCard), for: .touchUpInside)
        button.layer.cornerRadius = 5;
        button.clipsToBounds = true;

        self.addItem(button)
        self.view.addConstraints([
            NSLayoutConstraint (item: button, attribute: .width,
                                relatedBy: .equal,
                                toItem: nil, attribute: .notAnAttribute,
                                multiplier: 1, constant: 250),
            NSLayoutConstraint (item: button, attribute: .height,
                                relatedBy: .equal,
                                toItem: nil, attribute: .notAnAttribute,
                                multiplier: 1, constant: 50)
        ])
        addConstraints(button, label, 20.0, centered: true)
    }

    func getBillingSummaryOk() {
        self.showBilling()
    }

    func failure(_ message: String) {
        self.showBilling()
    }

    @objc func handleAddCard() {
        // Setup add card view controller
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self

        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        self.present(navigationController, animated: true)
    }

    // MARK: STPAddCardViewControllerDelegate

    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        // Dismiss add card view controller
        self.dismiss(animated: true)
    }

    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        self.sessionModel.submitTokenToBackend(token, completion: { (error: Error?) in
            if let error = error {
                // Show error in add card view controller
                completion(error)
            }
            else {
                completion(nil)
                self.dismiss(animated: true)
                self.showBilling()
            }
        })
    }
}
