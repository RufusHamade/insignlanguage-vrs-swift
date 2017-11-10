//
//  Model.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 18/04/2017.
//
//

import Foundation
import Alamofire
import OpenTok

let API_KEY = Bundle.main.infoDictionary!["APP_API_KEY"] as! String
let SESSION_SERVER = Bundle.main.infoDictionary!["APP_SESSION_SERVER"] as! String


protocol DialHandler {
    func onDialSuccess() -> Void
    func onDialFailure(_ reason: String) -> Void
    func onHangupSuccess() -> Void
}

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
    var onProviderAvailability: ((_ providerAvailability: Int) -> Void)?
    var dialHandler: DialHandler?

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

    func setDialHandler(_ dh: DialHandler ) {
        self.dialHandler = dh
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
        self.dialHandler?.onDialFailure(error)
    }

    func dialResult(callId: Int, sessionId: String, token: String) {
        self.callId = callId
        self.sessionId = sessionId
        self.token = token
        self.videoState = .connected
        self.dialHandler?.onDialSuccess()
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
        
        self.dialHandler?.onHangupSuccess()
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


protocol VideoDisplayer {
    func displayVideo(_ publisherView: UIView) -> Void
    func displayInsert(_ subscriberView: UIView) -> Void
}

protocol ErrorHandler {
    func showAlert(_ err: String) -> Void
    func onHangupSuccess() -> Void
}

class ConnectionModel: NSObject {
    static let sharedInstance = ConnectionModel();

    var sessionModel = SessionModel.sharedInstance

    var session: OTSession?

    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()

    var subscriber: OTSubscriber?
    var subscribeToSelf = false // Set true to see your own video stream....

    var videoDisplayer: VideoDisplayer?
    var errorHandler: ErrorHandler?

    func setVideoDisplayer(_ vd: VideoDisplayer) {
        self.videoDisplayer = vd
    }
    func setErrorHandler(_ eh: ErrorHandler) {
        self.errorHandler = eh
    }

    func connect() {
        self.session = OTSession(apiKey: API_KEY, sessionId: sessionModel.sessionId!, delegate: self)!

        var error: OTError?
        defer {
            self.processOTError(error)
        }

        self.session!.connect(withToken: sessionModel.token!, error: &error)
    }

    func disconnect() {
        session?.disconnect()
        session = nil
    }

    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            self.processOTError(error)
        }

        session!.publish(publisher, error: &error)

        if let pubView = publisher.view {
            self.videoDisplayer?.displayInsert(pubView)
        }
    }

    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processOTError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)

        session!.subscribe(subscriber!, error: &error)
    }

    func cleanupSubscriber() {
        if let subscriber = self.subscriber {
            subscriber.view?.removeFromSuperview()
            var error: OTError?
            self.session!.unsubscribe(subscriber, error: &error)
            self.processOTError(error)
        }
        self.subscriber = nil
    }

    //MARK: Error handling
    fileprivate func processOTError(_ error: OTError?) {
        if let err = error {
            self.errorHandler?.showAlert(err.localizedDescription)
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ConnectionModel: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }

    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil && !subscribeToSelf {
            doSubscribe(stream)
        }
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            self.errorHandler?.onHangupSuccess()
        }
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }

}


// MARK: - OTPublisher delegate callbacks
extension ConnectionModel: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        if subscriber == nil && subscribeToSelf {
            doSubscribe(stream)
        }
    }

    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }

    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ConnectionModel: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            self.videoDisplayer?.displayVideo(subsView)
        }
    }

    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }

    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
