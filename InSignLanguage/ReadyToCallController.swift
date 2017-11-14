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
    @IBOutlet weak var providerAvailabilityField: UILabel!
    @IBOutlet weak var callButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.notesField.layer.borderWidth = 1.0;
        self.notesField.layer.cornerRadius = 5.0;
        self.notesField.text = sessionModel.getNotes()
        self.notesField.delegate = self
        self.sessionModel.setProviderHandler(self)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        view.endEditing(true)
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
        sessionModel.setNotes(textView.text)
    }
}
