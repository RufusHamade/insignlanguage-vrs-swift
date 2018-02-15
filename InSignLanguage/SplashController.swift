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
            self.segueToReadyToCall()
        }
        else {
            self.segueToCompleteRegistration()
        }
    }

    func segueToCompleteRegistration() {
        // Push login controller onto stack so logout buttons can unwind to it.
        if let sb = self.storyboard {
            let login = sb.instantiateViewController(withIdentifier: "Login")
            self.present(login, animated: true)
            let register = sb.instantiateViewController(withIdentifier: "Settings")
            login.present(register, animated: true)
        }
    }

    func segueToReadyToCall() {
        // Push login controller onto stack so logout buttons can unwind to it.
        if let sb = self.storyboard {
            let login = sb.instantiateViewController(withIdentifier: "Login")
            self.present(login, animated: true)
            let register = sb.instantiateViewController(withIdentifier: "ReadyToCall")
            login.present(register, animated: true)
        }
    }

    func failure(_ message: String) {
        self.messages.text = message
        self.messages.textColor = .red
    }
}
