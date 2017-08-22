//
//  Model.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 18/04/2017.
//
//

import Foundation
import Alamofire

let API_KEY = Bundle.main.infoDictionary!["APP_API_KEY"] as! String
let SESSION_SERVER = Bundle.main.infoDictionary!["APP_SESSION_SERVER"] as! String

class SessionModel {
    static let sharedInstance = SessionModel();
    
    // MARK: Properties
    var server: String? = SESSION_SERVER
    var name: String?
    var password: String?
    var sessionToken: String?
    var notes: String?

    var providersAvailable: Int = -1
    var pollTimer: Timer?

    enum LoginState: Int {
        case authenticated, unauthenticated
    }
    var loginState: LoginState = .unauthenticated
    
    enum VideoState: Int {
        case disconnected, connected
    }
    var videoState: VideoState = .disconnected

    var callId: Int?
    var sessionId: String?
    var token: String?
    
    var onCredentialsChange: (() -> Void)?
    var onAuthSuccess: (() -> Void)?
    var onAuthFailure: ((_ reason: String) -> Void)?
    var onDialSuccess: (() -> Void)?
    var onDialFailure: ((_ reason: String) -> Void)?
    var onHangupSuccess: (() -> Void)?
    var onProviderAvailability: ((_ providerAvailability: Int) -> Void)?
    
    // MARK: Initialization
    private init() {
        let preferences = UserDefaults.standard
        self.name = preferences.object(forKey: "name") as? String
        self.sessionToken = preferences.object(forKey: "sessionToken") as? String
        self.notes = preferences.object(forKey: "notes") as? String
    }

    func setOnCredentialsChange(_ function: @escaping () -> Void ) {
        self.onCredentialsChange = function
    }

    func setOnAuthSuccess(_ function: @escaping () -> Void ) {
        self.onAuthSuccess = function
    }

    func setOnAuthFailure(_ function: @escaping (_ reason: String) -> Void ) {
        self.onAuthFailure = function
    }

    func setOnDialSuccess(_ function: @escaping () -> Void ) {
        self.onDialSuccess = function
    }

    func setOnDialFailure(_ function: @escaping (_ reason: String) -> Void ) {
        self.onDialFailure = function
    }

    func setOnHangupSuccess(_ function: @escaping () -> Void ) {
        self.onHangupSuccess = function
    }

    func setOnProviderAvailability(_ function: @escaping (_ providersAvailable: Int) -> Void) {
        self.onProviderAvailability = function
        if self.providersAvailable >= 0 {
            self.onProviderAvailability!(self.providersAvailable)
        }
    }
    //MARK: Authentication functions
    func setName(_ name: String?) {
        if self.name != name {
            self.name = name
            self.sessionToken = nil
            let preferences = UserDefaults.standard
            preferences.set(self.name, forKey: "name")
            preferences.set(self.sessionToken, forKey: "sessionToken")
            self.onCredentialsChange?()
        }
    }

    func setPassword(_ password: String?) {
        if self.password != password {
            self.password = password
            self.sessionToken = nil
            let preferences = UserDefaults.standard
            preferences.set(self.sessionToken, forKey: "sessionToken")
            self.onCredentialsChange?()
        }
    }

    func isAuthenticable() -> Bool {
        if self.name == nil || self.name == "" {
            return false
        }
        if self.password == nil {
            return false
        }
        return true
    }

    func authSuccess() -> Void {
        loginState = .authenticated
        self.pollTimer = Timer.scheduledTimer(timeInterval: 5,
                                              target: self,
                                              selector: #selector(self.checkProviderAvailability),
                                              userInfo: nil,
                                              repeats: true)
        self.onAuthSuccess?()
    }

    func authenticateResult(token: String) {
        sessionToken = token
        let preferences = UserDefaults.standard
        preferences.set(self.sessionToken, forKey: "sessionToken")
        self.authSuccess()
    }
    
    func authenticateFailure(_ reason: String){
        loginState = .unauthenticated
        self.onAuthFailure?(reason)
    }
    
    func authenticate () {
        if !self.isAuthenticable() {
            // no point doing anything.
            return
        }
        
        let parameters = [
            "username": self.name!,
            "password": self.password!
        ]
        
        Alamofire.request(self.server! + "/api-token-auth/",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
            .responseJSON { response in
                if response.response == nil {
                    self.authenticateFailure("Server Unavailable")
                    return
                }
                if response.response!.statusCode == 400 {
                    self.authenticateFailure("Invalid Credentials")
                }
                else if response.response!.statusCode != 200 {
                    self.authenticateFailure("Internal Server error")
                }
                else {
                    let jsonResult = response.result.value as! [String: Any]
                    self.authenticateResult(token: jsonResult["token"] as! String)
                }
        }
    }
    
    func checkToken () {
        if self.sessionToken == nil {
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]
        Alamofire.request(self.server! + "/ping/",
                          headers: headers)
            .responseJSON { response in
                if response.response == nil {
                    self.authenticateFailure("Server Unavailable")
                    return
                }
                if response.response?.statusCode == 200 {
                    self.authSuccess()
                }
                else {
                    self.sessionToken = nil
                    let preferences = UserDefaults.standard
                    preferences.set(self.sessionToken, forKey: "sessionToken")
                    self.loginState = .unauthenticated
                }
        }
    }
    
    func logout () {
        self.loginState = .unauthenticated
        self.sessionToken = nil
        let preferences = UserDefaults.standard
        if self.pollTimer != nil {
            self.pollTimer!.invalidate()
            self.pollTimer = nil
        }
        preferences.set(self.sessionToken, forKey: "sessionToken")
    }
    
    //MARK: Execute dial
    func dialFailure(_ error: String) {
        self.onDialFailure?(error)
    }

    func dialResult(callId: Int, sessionId: String, token: String) {
        self.callId = callId
        self.sessionId = sessionId
        self.token = token
        self.videoState = .connected
        self.onDialSuccess?()
    }
    
    func dial() {
        if self.videoState != .disconnected {
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]

        let parameters:Parameters = ["notes": self.getNotes()]

        Alamofire.request(self.server! + "/call/",
                          method: .post,
                          parameters: parameters,
                          headers: headers)
            .responseJSON { response in
                if response.result.value == nil {
                    self.dialFailure("Server Error")
                    return
                }
                let jsonResult = response.result.value as! [String: Any]
                self.dialResult(callId: jsonResult["call_id"] as! Int,
                                sessionId: jsonResult["session_id"] as! String,
                                token: jsonResult["token"] as! String)
        }
    }
    
    //MARK: Execute hangup
    func hangupResult() {
        self.callId = nil
        self.videoState = .disconnected
        
        self.onHangupSuccess?()
    }
    
    func hangUp() {
        if self.videoState != .connected {
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]

        Alamofire.request(self.server! + "/hangup/\(self.callId!)/", headers: headers)
            .responseJSON { response in
                self.hangupResult()
        }
    }

    @objc func checkProviderAvailability() {
        let headers: HTTPHeaders = [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]

        Alamofire.request(self.server! + "/poll/", headers: headers)
            .responseJSON { response in
                if response.result.value == nil {
                    return
                }
                let jsonResult = response.result.value as! [String: Any]
                let availableNow:Int = jsonResult["providers_available"] as! Int
                if self.providersAvailable != availableNow {
                    self.providersAvailable = availableNow
                    if self.onProviderAvailability != nil {
                        self.onProviderAvailability!(availableNow)
                    }
                }
        }

    }
    func setNotes(_ notes:String?) {
        self.notes = notes
        let preferences = UserDefaults.standard
        preferences.set(self.notes, forKey: "notes")
    }

    func getNotes() -> String {
        return self.notes != nil ? self.notes! : ""
    }
}
