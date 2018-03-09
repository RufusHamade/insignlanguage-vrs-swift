import UIKit

class BillingDetailsController: UIViewController, GetBillingSummaryHandler {

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

    func showBilling() {
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

    func addConstraints(_ item: UIView, _ previous: UIView, _ distance: CGFloat) {
        self.view.addConstraints([
            NSLayoutConstraint(item: item, attribute: .top,
                               relatedBy: .equal,
                               toItem: previous, attribute: .bottom,
                               multiplier: 1.0, constant: distance),
            NSLayoutConstraint(item: item, attribute: .leading,
                               relatedBy: .equal,
                               toItem: self.view, attribute: .leading,
                               multiplier: 1.0, constant: 45.0),
            NSLayoutConstraint(item: item, attribute: .trailing,
                               relatedBy: .equal,
                               toItem: self.view, attribute: .trailing,
                               multiplier: 1.0, constant: -45.0)
            ])
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
            self.view.addSubview(label)
            self.addConstraints(label, self.contractType, 20.0)
            self.showPaymentMethod()
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
        self.view.addSubview(label)
        self.addConstraints(label, self.contractType, 20.0)

        let previousLabel = label
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "%d minutes (of %d) remaining in this period", remaining, total)
        label.numberOfLines = 0
        self.view.addSubview(label)
        addConstraints(label, previousLabel, 10.0)

        if remaining == 0 {
            let previousLabel = label
            label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.text = "You've used all your minutes.  But you can still Pay As You Go."
            self.addConstraints(label, previousLabel, 20.0)
            self.view.addSubview(label)
            self.showPaymentMethod()
        }
    }

    func showLastMonthsUsage() {
        let minutes = self.sessionModel.billingSummary!["minutes_used_in_billing_period"] as! NSArray
        let used = minutes[1] as! Int
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "%d minutes used this month", used)
        label.numberOfLines = 0
        self.view.addSubview(label)
        addConstraints(label, self.contractType, 10.0)
    }

    func showPaymentMethod() {
    }

    func getBillingSummaryOk() {
        self.showBilling()
    }

    func failure(_ message: String) {
        self.showBilling()
    }
}
