//
//  Model.swift
//  RufusApp
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
    var name: String?
    var password: String?
    var sessionToken: String?
    
    enum LoginState: Int {
        case authenticated, unauthenticated
    }
    var loginState: LoginState
    
    enum VideoState: Int {
        case disconnected, connected
    }
    var videoState: VideoState

    var callId: Int?
    var sessionId: String?
    var token: String?
    
    var onAuthChange: (() -> Void)?
    var onAuthFailure: ((_ reason: String) -> Void)?
    var onDialSuccess: (() -> Void)?
    var onHangupSuccess: (() -> Void)?
    
    // MARK: Initialization
    private init() {
        let preferences = UserDefaults.standard
        self.name = preferences.object(forKey: "name") as? String
        self.sessionToken = preferences.object(forKey: "sessionToken") as? String
        
        loginState = LoginState.unauthenticated
        videoState = VideoState.disconnected
        
        checkToken()
    }
    
    func setOnAuthChange(_ onAuthChange: @escaping () -> Void ) {
        self.onAuthChange = onAuthChange
    }
    
    func setOnAuthFailure(_ function: @escaping (_ reason: String) -> Void ) {
        self.onAuthFailure = function
    }
    
    func setOnDialSuccess(_ onDialSuccess: @escaping () -> Void ) {
        self.onDialSuccess = onDialSuccess
    }
    
    func setOnHangupSuccess(_ onHangupSuccess: @escaping () -> Void ) {
        self.onHangupSuccess = onHangupSuccess
    }
    
    //MARK: Authentication functions
    func setName(_ name: String?) {
        if self.name != name {
            self.name = name
            self.sessionToken = nil
            let preferences = UserDefaults.standard
            preferences.set(self.name, forKey: "name")
            preferences.set(self.sessionToken, forKey: "sessionToken")
            self.onAuthChange?()
        }
    }

    func setPassword(_ password: String?) {
        if self.password != password {
            self.password = password
            self.sessionToken = nil
            let preferences = UserDefaults.standard
            preferences.set(self.sessionToken, forKey: "sessionToken")
            self.onAuthChange?()
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
    
    func authenticateResult(token: String) {
        sessionToken = token
        let preferences = UserDefaults.standard
        preferences.set(self.sessionToken, forKey: "sessionToken")
        loginState = .authenticated
        self.onAuthChange?()
    }
    
    func authenticateFailure(_ reason: String){
        loginState = .unauthenticated
        self.onAuthFailure?(reason)
    }
    
    func authenticate () {
        if !self.isAuthenticable() {
            // no point doing anything.
            loginState = LoginState.unauthenticated
            self.onAuthChange?()
        }
        
        let parameters = [
            "username": self.name!,
            "password": self.password!
        ]
        
        Alamofire.request(SESSION_SERVER + "/api-token-auth/",
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
            self.loginState = .unauthenticated
            self.onAuthChange?()
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]
        Alamofire.request(SESSION_SERVER + "/ping/",
                          headers: headers)
            .responseJSON { response in
                if response.response == nil {
                    self.authenticateFailure("Server Unavailable")
                    return
                }
                if response.response?.statusCode == 200 {
                    self.loginState = .authenticated
                }
                else {
                    self.sessionToken = nil
                    let preferences = UserDefaults.standard
                    preferences.set(self.sessionToken, forKey: "sessionToken")
                    self.loginState = .unauthenticated
                }
                self.onAuthChange?()
        }
    }
    
    func logout () {
        self.loginState = .unauthenticated
        self.sessionToken = nil
        let preferences = UserDefaults.standard
        preferences.set(self.sessionToken, forKey: "sessionToken")
        self.onAuthChange?()
    }
    
    //MARK: Execute dial
    func dialFailure(_ error: String) {

    }

    func dialResult(callId: Int, sessionId: String, token: String) {
        self.callId = callId
        self.sessionId = sessionId
        self.token = token
        self.videoState = .connected
        
        print("session ID: " + sessionId)
        print("token: " + token)
        
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

        Alamofire.request(SESSION_SERVER + "/call/", headers: headers)
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

        Alamofire.request(SESSION_SERVER + "/hangup/" + String(describing: self.callId) + "/", headers: headers)
            .responseJSON { response in
                self.hangupResult()
        }
    }
}
