//
//  ViewController.swift
//  RufusApp
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 17/04/2017.
//
//

import UIKit
import OpenTok

class VideoDisplayController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var hangupButton: UIButton!
    
    //MARK: Properties
    var session: OTSession?
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    var subscriber: OTSubscriber?
    var subscribeToSelf = false // Set true to see your own video stream....
    
    var sessionModel = SessionModel.sharedInstance
    
    // MARK: Initialisation
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionModel.setOnDialSuccess {
            self.onDialSuccess()
        }
        sessionModel.setOnHangupSuccess {
            self.onHangup()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionModel.dial()
    }
    
    //MARK: Session/State transition functions
    func onDialSuccess() {
        session = OTSession(apiKey: API_KEY, sessionId: sessionModel.sessionId!, delegate: self)!

        var error: OTError?
        defer {
            processError(error)
        }
            
        session!.connect(withToken: sessionModel.token!, error: &error)
    }

    func onHangup() {
        session!.disconnect()
        cleanupSubscriber()
        cleanupPublisher()
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session!.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 50    , y: 450, width: 150, height: 150)
            view.addSubview(pubView)
        }
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
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
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session!.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    //MARK: UI Actions
    @IBAction func hangupClicked(_ sender: Any) {
    }
    
    //MARK: Error handling
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            showAlert(errorStr: err.localizedDescription)
        }
    }
    
    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
}


// MARK: - OTSession delegate callbacks
extension VideoDisplayController: OTSessionDelegate {
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
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension VideoDisplayController: OTPublisherDelegate {
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
extension VideoDisplayController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 40,
                                    y: 150,
                                    width: 300,
                                    height: 300)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}


