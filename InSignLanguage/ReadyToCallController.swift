//
//  ReadyToCallController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 25/04/2017.
//
//

import Foundation

import UIKit

class ReadyToCallController: UIViewController {

    @IBOutlet weak var nameField: UILabel!
    @IBOutlet weak var notesField: UITextView!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.notesField.layer.borderWidth = 1.0;
        self.notesField.layer.cornerRadius = 5.0;
        self.notesField.text = sessionModel.getNotes()
        self.notesField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        self.nameField.text = sessionModel.name
        self.nameField.textAlignment = .center
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
