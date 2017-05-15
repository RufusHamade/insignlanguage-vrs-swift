//
//  ViewController.swift
//  InSignLanguage
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
        sessionModel.setOnDialSuccess(self.onDialSuccess)
        sessionModel.setOnHangupSuccess(self.doHangup)
        sessionModel.setOnDialFailure(self.onDialFailure)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionModel.dial()
    }

    func onDialFailure(_ reason: String) {
        showAlert(errorStr: "Couldn't find a translator: " + reason)
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

    func doHangup() {
        self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
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
            let width = view.frame.size.width/4
            let height = view.frame.size.height/4
            let insetTop = hangupButton.frame.origin.y - (height + 12)
            let baseView = UIView(frame: CGRect(x:4.0, y: insetTop, width: width + 2, height: height + 2))
            baseView.backgroundColor = .white
            view.addSubview(baseView)
            pubView.frame = CGRect(x: 5.0, y: insetTop + 1, width: width, height: height)
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
        if let subscriber = self.subscriber {
            subscriber.view?.removeFromSuperview()
            var error: OTError?
            session!.unsubscribe(subscriber, error: &error)
            processError(error)
        }
        subscriber = nil
    }
    
    //MARK: UI Actions
    @IBAction func hangupClicked(_ sender: Any) {
        if session == nil {
            // This is probably the second time we've hit hangup.  So just segue
            self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
            return
        }

        cleanupSubscriber()
        cleanupPublisher()
        session?.disconnect()
        session = nil
        sessionModel.hangUp()
    }
    
    //MARK: Error handling
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            showAlert(errorStr: err.localizedDescription)
        }
    }

    fileprivate func handleAlert(action:UIAlertAction) {
        doHangup()
    }

    fileprivate func showAlert(errorStr err: String) {
        print("Alert: " + err)
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.handleAlert))
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
            doHangup()
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
            let insetTop = CGFloat(80.0)
            let insetBottom = view.frame.size.height - hangupButton.frame.origin.y + CGFloat(8)
            subsView.frame = CGRect(x: 2.0, y: insetTop,
                                    width: view.frame.size.width - 4,
                                    height: view.frame.size.height - insetTop - insetBottom)
            view.insertSubview(subsView, at: 0)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}


