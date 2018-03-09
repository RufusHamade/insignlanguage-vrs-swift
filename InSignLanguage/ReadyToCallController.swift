//
//  ReadyToCallController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 25/04/2017.
//
//

import Foundation

import UIKit

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

    func dismissKeyboard() {
        view.endEditing(true)
    }


    func onProviderAvailability(_ availableProviders: Int,
                                _ minutesRemaining: Int?) {
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
            let cost_per_minute = Float(bs["cost_per_minute"] as! String)!
            var text: String
            if contract_type == "payg" {
                text = String(format: "Pay as you go: Calls cost £%.2f per minute,\nminimum %d minutes.",
                              cost_per_minute, minimum_minutes_charged)
            }
            else {
                let billingPeriodEndStr = self.sessionModel.billingSummary!["billing_period_end"] as! String
                let df = SessionModel.outputDateFormatter
                let dfi = SessionModel.jsonDateParser
                let billingPeriodEnd = df.string(from: dfi.date(from: billingPeriodEndStr)!)
                text = String(format: "Contract: You have %d minutes left.\nMore minutes on %@",
                              minutesRemaining!, billingPeriodEnd)
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
