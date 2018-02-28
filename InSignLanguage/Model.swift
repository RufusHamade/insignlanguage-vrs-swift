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
let HAPPY_COLOR = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)

//MARK: SessionModel

protocol CheckTokenHandler {
    func tokenOk() -> Void
    func tokenNotOk() -> Void
    func failure(_ message: String) -> Void
}

protocol GetPersonalProfileHandler {
    func getPersonalProfileOk() -> Void
    func failure(_ message: String) -> Void
}

protocol UpdatePersonalProfileHandler {
    func updatePersonalProfileOk() -> Void
    func failure(_ message: String) -> Void
}

protocol GetBillingSummaryHandler {
    func getBillingSummaryOk() -> Void
    func failure(_ message: String) -> Void
}

protocol SessionHandler {
    func onCredentialsChange() -> Void
}

protocol AuthenticateHandler {
    func authenticateOk() -> Void
    func failure(_ message: String) -> Void
}

protocol RegisterHandler {
    func registerOk() -> Void
    func failure(_ message: String) -> Void
}

protocol ChangePasswordHandler {
    func changePasswordOk() -> Void
    func failure(_ message: String) -> Void
}

protocol ResetPasswordHandler {
    func resetPasswordOk() -> Void
    func failure(_ message: String) -> Void
}

protocol ProviderHandler {
    func onProviderAvailability(_ availableProviders: Int) -> Void
}

protocol DialHandler {
    func onDialSuccess() -> Void
    func onDialFailure(_ reason: String) -> Void
    func onHangupSuccess() -> Void
}

class SessionModel {
    static let sharedInstance = SessionModel();

    static let PROFILE_MANDATORY_FIELDS = [
        "first_name",
        "last_name",
        "email",
        "phone",
        "address1",
        "address3",
        "postcode"
    ]

    // MARK: Properties
    var serverUrl: String = SESSION_SERVER
    var name: String?
    var password: String?
    var sessionToken: String?
    var notes: String?
    var number: String?
    var personalProfile: [String: String?] = [:]
    var billingSummary: [String: Any?]?

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

    var sessionHandler: SessionHandler?
    var providerHandler: ProviderHandler?
    var dialHandler: DialHandler?

    let preferences = UserDefaults.standard

    // MARK: Initialization
    private init() {
        self.name = self.preferences.object(forKey: "name") as? String
        self.sessionToken = self.preferences.object(forKey: "sessionToken") as? String
        self.notes = self.preferences.object(forKey: "notes") as? String
    }

    func setSessionHandler(_ sh: SessionHandler) {
        self.sessionHandler = sh
    }

    func setProviderHandler(_ ph: ProviderHandler) {
        self.providerHandler = ph
    }

    func setDialHandler(_ dh: DialHandler ) {
        self.dialHandler = dh
    }

    func resetProviderAvailabilityCheck() {
        providersAvailable = -1
        self.checkProviderAvailability()
    }

    //MARK: Authentication functions
    func setName(_ name: String?) {
        if self.name != name {
            self.name = name
            self.sessionToken = nil
            self.preferences.set(self.name, forKey: "name")
            self.preferences.set(self.sessionToken, forKey: "sessionToken")
            self.sessionHandler?.onCredentialsChange()
        }
    }

    func setPassword(_ password: String?) {
        if self.password != password {
            self.password = password
            self.sessionToken = nil
            self.preferences.set(self.sessionToken, forKey: "sessionToken")
            self.sessionHandler?.onCredentialsChange()
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

    func isProfileOk() -> Bool {
        for i in SessionModel.PROFILE_MANDATORY_FIELDS {
            if self.personalProfile[i] == nil || self.personalProfile[i]! == "" {
                return false
            }
        }

        return true
    }
    
    func startProviderPoll() {
        if self.pollTimer != nil {
            return
        }

        self.pollTimer = Timer.scheduledTimer(timeInterval: 10,
                                              target: self,
                                              selector: #selector(self.checkProviderAvailability),
                                              userInfo: nil,
                                              repeats: true)
    }

    func stopProviderPoll() {
        if self.pollTimer != nil {
            self.pollTimer!.invalidate()
            self.pollTimer = nil
        }
    }

    func authenticateResult(_ token: String) {
        sessionToken = token
        self.preferences.set(self.sessionToken, forKey: "sessionToken")
    }

    func authenticate (_ handler: AuthenticateHandler) {
        if !self.isAuthenticable() {
            // no point doing anything.
            return
        }

        let parameters = [
            "username": self.name!,
            "password": self.password!
        ]

        Alamofire.request(self.serverUrl + "/api/account/token-auth/",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
            .responseJSON { response in
                if response.response == nil {
                    self.loginState = .unauthenticated
                    handler.failure(String(format:"Server\n%@\nUnavailable", self.serverUrl))
                    return
                }
                if response.response!.statusCode == 400 {
                    self.loginState = .unauthenticated
                    handler.failure("Invalid Credentials")
                }
                else if response.response!.statusCode != 200 {
                    self.loginState = .unauthenticated
                    handler.failure("Internal Server error")
                }
                else {
                    let jsonResult = response.result.value as! [String: Any]
                    self.authenticateResult(jsonResult["token"] as! String)
                    self.loginState = .authenticated
                    handler.authenticateOk()
                }
        }
    }

    func getAuthHeaders() -> HTTPHeaders {
        return [
            "Authorization": "Token " + self.sessionToken!,
            "Accept": "application/json"
        ]
    }

    func checkToken(_ handler: CheckTokenHandler) {
        if self.sessionToken == nil {
            handler.tokenNotOk()
            return
        }

        Alamofire.request(self.serverUrl + "/api/call/ping/",
                          headers: self.getAuthHeaders())
            .responseJSON { response in
                if response.response == nil {
                    handler.failure(String(format:"Server\n%@\nUnavailable", self.serverUrl))
                    self.loginState = .unauthenticated
                    return
                }
                if response.response?.statusCode == 200 {
                    handler.tokenOk()
                    self.loginState = .authenticated
                    return
                }
                handler.tokenNotOk()
                self.sessionToken = nil
                self.preferences.set(self.sessionToken, forKey: "sessionToken")
                self.loginState = .unauthenticated
        }
    }

    func logout () {
        self.loginState = .unauthenticated
        self.sessionToken = nil
        self.preferences.set(self.sessionToken, forKey: "sessionToken")
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

        let parameters:Parameters = ["notes": self.getNotes(),
                                     "number": self.getNumber()]

        Alamofire.request(self.serverUrl + "/api/call/call/",
                          method: .post,
                          parameters: parameters,
                          headers: self.getAuthHeaders())
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

        Alamofire.request(self.serverUrl + "/api/call/hangup/\(self.callId!)/", headers: self.getAuthHeaders())
            .responseJSON { response in
                self.hangupResult()
        }
    }

    @objc func checkProviderAvailability() {
        Alamofire.request(self.serverUrl + "/api/call/poll/", headers: self.getAuthHeaders())
            .responseJSON { response in

                switch response.result {
                case .success:
                    let jsonResult = response.result.value as! [String: Any]
                    let availableNow:Int = jsonResult["providers_available"] as! Int
                    if self.providersAvailable != availableNow {
                        self.providersAvailable = availableNow
                        if self.sessionHandler != nil {
                            self.providerHandler!.onProviderAvailability(availableNow)
                        }
                    }
                case .failure:
                    self.providersAvailable = -1
                    self.providerHandler!.onProviderAvailability(-1)
                }

        }
    }

    func setNotes(_ notes:String?) {
        self.notes = notes
        self.preferences.set(self.notes, forKey: "notes")
    }

    func getNotes() -> String {
        return self.notes != nil ? self.notes! : ""
    }

    func setNumber(_ number:String?) {
        self.number = number
    }

    func getNumber() -> String {
        return self.number != nil ? self.number! : ""
    }

    func resetPassword(_ email: String, _ handler: ResetPasswordHandler) {
        let parameters = [
            "email": email,
        ]

        Alamofire.request(self.serverUrl + "/api/account/request-password-reset/",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                }
                else if response.response!.statusCode == 400 {
                    let jsonResult = response.result.value as! [String: Any]
                    handler.failure(jsonResult["error"] as! String)
                }
                else if response.response!.statusCode != 200 {
                    handler.failure("Internal Server error")
                }
                else {
                    handler.resetPasswordOk()
                }
        }
    }

    func changePassword(_ oldPassword: String, _ newPassword: String, _ handler: ChangePasswordHandler) {
        let parameters = [
            "old_password": oldPassword,
            "new_password": newPassword
        ]

        Alamofire.request(self.serverUrl + "/api/account/change-password/",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: self.getAuthHeaders())
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                    return
                }
                let status = response.response!.statusCode
                print(response.result.value!)
                if status == 400 {
                    let jsonResult = response.result.value as! [String: Any]
                    handler.failure(jsonResult["error"] as! String)
                }
                else if status != 200 {
                    handler.failure("Internal Server error")
                }
                else {
                    let jsonResult = response.result.value as! [String: Any]
                    self.authenticateResult(jsonResult["token"] as! String)
                    handler.changePasswordOk()
                }
        }
    }

    func register(_ email: String, _ password: String, _ handler: RegisterHandler) {
        let parameters = [
            "email": email,
            "password": password
        ]

        Alamofire.request(self.serverUrl + "/api/account/register/",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                }
                else if response.response!.statusCode == 400 {
                    let jsonResult = response.result.value as! [String: Any]
                    handler.failure((jsonResult["error"] as! String))
                }
                else if response.response!.statusCode != 200 {
                    handler.failure("Internal Server error")
                }
                else {
                    let jsonResult = response.result.value as! [String: Any]
                    self.authenticateResult(jsonResult["token"] as! String)
                    self.name = email
                    self.preferences.set(self.name, forKey: "name")
                    handler.registerOk()
                }
        }
    }

    func getPersonalProfile(_ handler: GetPersonalProfileHandler) {
        Alamofire.request(self.serverUrl + "/api/account/get-personal-profile/",
                          encoding: JSONEncoding.default,
                          headers: self.getAuthHeaders())
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                    return
                }
                else if response.response!.statusCode != 200 {
                    handler.failure("Internal Server error")
                    return
                }

                self.personalProfile = response.result.value as! [String: String?]
                handler.getPersonalProfileOk()
        }
    }

    func updatePersonalProfile(_ handler: UpdatePersonalProfileHandler) {
        var params = [String: String]()
        for (k, v) in self.personalProfile {
            if v != nil {
                params[k] = v
            }
        }

        Alamofire.request(self.serverUrl + "/api/account/update-personal-profile/",
                          method: .post,
                          parameters: params,
                          encoding: JSONEncoding.default,
                          headers: self.getAuthHeaders())
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                    return
                }
                let status = response.response!.statusCode
                if  status == 400 {
                    let jsonResult = response.result.value as! [String: Any]
                    handler.failure(jsonResult["error"] as! String)
                }
                else if status != 200 {
                    handler.failure("Internal Server error")
                }
                else {
                    self.name = self.personalProfile["email"]!
                    self.preferences.set(self.name, forKey: "name")
                    handler.updatePersonalProfileOk()
                }
        }

    }

    func getBillingSummary(_ handler: GetBillingSummaryHandler) {
        Alamofire.request(self.serverUrl + "/api/account/get-billing-summary/",
                          encoding: JSONEncoding.default,
                          headers: self.getAuthHeaders())
            .responseJSON { response in
                if response.response == nil {
                    handler.failure("Server Unavailable")
                    return
                }
                else if response.response!.statusCode != 200 {
                    handler.failure("Internal Server error")
                    return
                }

                self.billingSummary = response.result.value as? [String: Any?]
                handler.getBillingSummaryOk()
        }
    }
}


protocol VideoDisplayer {
    func displayVideo(_ publisherView: UIView) -> Void
    func displayInsert(_ subscriberView: UIView) -> Void
    func onDisconnectComplete() -> Void
}

protocol ErrorHandler {
    func showAlert(_ err: String) -> Void
}

class ConnectionModel: NSObject {
    static let sharedInstance = ConnectionModel();

    var sessionModel = SessionModel.sharedInstance

    var otSession: OTSession?
    var connectionId: String?

    lazy var otPublisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    var publisherIsActive = false

    var otSubscriber: OTSubscriber?
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
        self.otSession = OTSession(apiKey: API_KEY, sessionId: sessionModel.sessionId!, delegate: self)!

        var error: OTError?
        defer {
            self.processOTError(error)
        }

        self.otSession!.connect(withToken: sessionModel.token!, error: &error)
    }

    func disconnect() {
        self.otSession?.disconnect(nil)
        self.otSession = nil
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

        self.otSession!.publish(self.otPublisher, error: &error)

        if let pubView = self.otPublisher.view {
            self.videoDisplayer?.displayInsert(pubView)
        }
        self.publisherIsActive = true
        print("doing publish")
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
        self.otSubscriber = OTSubscriber(stream: stream, delegate: self)
        self.otSession!.subscribe(self.otSubscriber!, error: &error)
        print("doing subscribe")
    }

    func cleanupPublisher(){
        if !publisherIsActive {
            return
        }
        print("cleanup publisher")
        self.otPublisher.view?.removeFromSuperview()
        var error: OTError?
        self.otSession!.unpublish(self.otPublisher, error: &error)
        processOTError(error)
        self.publisherIsActive = false
    }

    func cleanupSubscriber(streamDestroyed: Bool) {
        if let subscriber = self.otSubscriber {
            print("cleanup subscriber")
            subscriber.view?.removeFromSuperview()
            if !streamDestroyed {
                print("Unsubscribing")
                var error: OTError?
                self.otSession!.unsubscribe(subscriber, error: &error)
                self.processOTError(error)
            }
        }
        self.otSubscriber = nil
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
        self.connectionId = self.otSession?.connection?.connectionId
    }

    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
        self.connectionId = nil
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if self.otSubscriber == nil && !subscribeToSelf {
            self.doSubscribe(stream)
            self.doPublish()
        }
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = self.otSubscriber?.stream, subStream.streamId == stream.streamId {
            print("they disconnected")
            self.cleanupPublisher()
            self.cleanupSubscriber(streamDestroyed:true)
            self.disconnect()
            self.videoDisplayer?.onDisconnectComplete()
        }
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
}


// MARK: - OTPublisher delegate callbacks
extension ConnectionModel: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        if self.otSubscriber == nil && subscribeToSelf {
            print("self subscribing")
            doSubscribe(stream)
        }
    }

    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        if let subStream = self.otSubscriber?.stream, subStream.streamId == stream.streamId {
            print("self subscribing cleanup")
            self.cleanupPublisher()
            self.cleanupSubscriber(streamDestroyed:true)
            self.videoDisplayer?.onDisconnectComplete()
        }
    }

    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ConnectionModel: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = self.otSubscriber?.view {
            print("displaying remote video")
            self.videoDisplayer?.displayVideo(subsView)
        }
    }

    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }

    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
