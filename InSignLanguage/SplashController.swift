//
//  SplashController.swift
//  InSignLanguage
//
//  Created by Developer on 09/02/2018.
//  Copyright © 2018 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class SplashController: UIViewController, CheckTokenHandler, GetPersonalProfileHandler {

    @IBOutlet weak var messages: UILabel!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionModel.checkToken(self)
    }

    func tokenOk() {
        self.messages.text = "Checking profile..."
        self.sessionModel.getPersonalProfile(self)
    }

    func tokenNotOk() {
        //self.performSegue(withIdentifier: "completeRegistration", sender: self)
        self.performSegue(withIdentifier: "login", sender: self)
    }

    func getPersonalProfileOk() {
        if (self.sessionModel.isProfileOk()) {
            self.performSegue(withIdentifier: "readyToCall", sender: self)
        }
        else {
            self.performSegue(withIdentifier: "completeRegistration", sender: self)
        }
    }

    func failure(_ message: String) {
        self.messages.text = message
        self.messages.textColor = .red
    }
}
