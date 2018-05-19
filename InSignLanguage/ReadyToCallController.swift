import UIKit

func dateFromString(_ isoString: String) -> String {
    let df = SessionModel.outputDateFormatter
    let dfi = SessionModel.jsonDateParser
    return df.string(from: dfi.date(from: isoString)!)
}


class ReadyToCallController: UIViewController, ProviderHandler {

    @IBOutlet weak var nameField: UILabel!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var numberField: UITextField!
    @IBOutlet weak var contractDetailsField: UILabel!
    @IBOutlet weak var providerAvailabilityField: UILabel!
    @IBOutlet weak var callButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.notesField.layer.borderWidth = 1.0
        self.notesField.layer.cornerRadius = 3.0
        self.notesField.text = sessionModel.getNotes()
        self.notesField.delegate = self
        self.numberField.layer.borderWidth = 1.0
        self.numberField.layer.cornerRadius = 3.0
        self.numberField.delegate = self
        self.numberField.layer.borderWidth = 1.0
        self.sessionModel.setProviderHandler(self)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionModel.startProviderPoll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.sessionModel.stopProviderPoll()
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func showPopup(_ title: String, _ message: String) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) {
            (result : UIAlertAction) -> Void in print("You pressed OK")
        }

        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func onProviderAvailability(_ availableProviders: Int) {
        if availableProviders < 1 {
            if availableProviders == 0 {
                self.providerAvailabilityField.text = "Unfortunately, there are no translators available."
            }
            else {
                self.providerAvailabilityField.text = "Server unavailable."
            }
            callButton.isEnabled = false
            callButton.alpha = 0.25
        }
        else {
            self.providerAvailabilityField.text = String(format: "There are %d translators available.", availableProviders)
            callButton.isEnabled = true
            callButton.alpha = 1
        }
        self.providerAvailabilityField.textAlignment = .center

        if availableProviders >= 0 {
            let bs = self.sessionModel.billingSummary!
            let contract_type = bs["contract_type"] as! String
            let minimum_minutes_charged = bs["minimum_minutes_charged"] as! Int
            let cost_per_minute = bs["cost_per_minute"] as! NSNumber
            var text: String
            if contract_type == "payg" {
                if !self.sessionModel.cardRegistered {
                    text = String(format: "Pay as you go: No payment method set up.")
                }
                else if !self.sessionModel.cardActive {
                    text = String(format: "Pay as you go: There was a problem with your last payment.")
                }
                else {
                    text = String(format: "Pay as you go: Calls cost £%@ per minute,\nminimum %d minutes.",
                                  cost_per_minute.stringValue, minimum_minutes_charged)
                }
            }
            else {
                if self.sessionModel.minutesRemaining == 0 {
                    text = String(format: "Contract: You have used up all your minutes.\nContact InSignLanguage to arrange more.")
                }
                else {
                    let billingPeriodEndStr = self.sessionModel.billingSummary!["billing_period_end"] as! String
                    let billingPeriodEnd = dateFromString(billingPeriodEndStr)
                    text = String(format: "Contract: You have %d minutes left.\nMore minutes on %@",
                                  self.sessionModel.minutesRemaining!, billingPeriodEnd)
                }
            }
            self.contractDetailsField.text = text
        }
        else {
            self.contractDetailsField.text = ""
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.nameField.text = sessionModel.name
        self.nameField.textAlignment = .center
        self.providerAvailabilityField.text = "Checking for translators..."
        self.providerAvailabilityField.textAlignment = .center
        self.sessionModel.resetProviderAvailabilityCheck()
    }

    @IBAction func logoutClicked(_ sender: Any) {
        sessionModel.logout()
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }

    @IBAction func viewSettings(_ sender: Any) {
        if let sb = self.storyboard, let ns = self.navigationController {
            let terms = sb.instantiateViewController(withIdentifier: "Settings")
            ns.pushViewController(terms, animated: true)
        }
    }

    @IBAction func dial(_ sender: Any) {
        if !self.sessionModel.canCall {
            let bs = self.sessionModel.billingSummary!
            let contract_type = bs["contract_type"] as! String
            if contract_type == "payg" {
                if !self.sessionModel.cardRegistered {
                    self.showPopup("Payment issue",
                                   "We have no credit/debit card on file.  Visit the billing details in settings to set up a payment mechanism.")
                }
                else {
                    self.showPopup("Payment issue",
                                   "There was a problem last time we tried to take a payment from your credit/debit card.  Please visit the billing details in settings to add a new card.")
                }
            }
            else {
                let billingPeriodEndStr = self.sessionModel.billingSummary!["billing_period_end"] as! String
                let billingPeriodEnd = dateFromString(billingPeriodEndStr)
                self.showPopup("No more minutes",
                               String(format: "No more minutes in this month's contract.  More minutes on %@, or contat the InSignLanguage team to arrange some more.", billingPeriodEnd))

            }
            return
        }
        self.performSegue(withIdentifier: "showInCall", sender: nil)
    }

    @IBAction func unwindToReadyToCall(segue: UIStoryboardSegue) {}
}

extension ReadyToCallController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == self.notesField {
            self.sessionModel.setNotes(textView.text)
        }
    }
}

extension ReadyToCallController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.numberField {
            self.sessionModel.setNumber(textField.text)
        }
    }
}
