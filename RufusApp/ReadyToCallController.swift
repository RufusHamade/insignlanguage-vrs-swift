//
//  ReadyToCallController.swift
//  RufusApp
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 25/04/2017.
//
//

import Foundation

import UIKit

class ReadyToCallController: UIViewController {

    @IBOutlet weak var nameField: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
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
