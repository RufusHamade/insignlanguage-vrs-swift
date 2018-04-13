//
//  SplashController.swift
//  InSignLanguage
//
//  Created by Developer on 09/02/2018.
//  Copyright © 2018 Yvonne Eva Hannah Louise DeBrett. All rights reserved.
//

import UIKit

class SplashController: UIViewController, CheckTokenHandler, GetPersonalProfileHandler, GetBillingSummaryHandler {

    @IBOutlet weak var messages: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    var sessionModel = SessionModel.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionModel.connectToServer(self)
        self.retryButton.isHidden = true
        self.retryButton.isEnabled = false
    }

    func tokenOk() {
        self.messages.text = "Checking profile..."
        self.sessionModel.getBillingSummary(self)
    }

    func tokenNotOk() {
        self.performSegue(withIdentifier: "login", sender: self)
    }

    func getBillingSummaryOk() {
        self.sessionModel.getPersonalProfile(self)
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
        if let sb = self.storyboard, let ns = self.navigationController {
            let login = sb.instantiateViewController(withIdentifier: "Login")
            let register = sb.instantiateViewController(withIdentifier: "Settings")
            login.loadViewIfNeeded()
            ns.pushViewController(register, animated: true)
            ns.viewControllers.insert(login, at: ns.viewControllers.count - 1)
        }
    }

    func segueToReadyToCall() {
        // Push login controller onto stack so logout buttons can unwind to it.
        if let sb = self.storyboard, let ns = self.navigationController {
            let login = sb.instantiateViewController(withIdentifier: "Login")
            let readyToCall = sb.instantiateViewController(withIdentifier: "ReadyToCall")
            login.loadViewIfNeeded()
            ns.pushViewController(readyToCall, animated: true)
            ns.viewControllers.insert(login, at: ns.viewControllers.count - 1)
        }
    }

    func failure(_ message: String) {
        self.messages.text = message
        self.messages.textColor = .red
        self.retryButton.isHidden = false
        self.retryButton.isEnabled = true
        self.retryButton.alpha = 1.0
    }

    @IBAction func retryClicked(_ sender: Any) {
        self.messages.text = "Trying again..."
        self.messages.textColor = HAPPY_COLOR
        self.sessionModel.connectToServer(self)
        self.retryButton.isEnabled = false
        self.retryButton.alpha = 0.5
    }
}
