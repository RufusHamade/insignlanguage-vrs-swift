//
//  ViewController.swift
//  InSignLanguage
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 17/04/2017.
//
//

import UIKit
import OpenTok

extension UIView {
    func rotate360Degrees(duration:CFTimeInterval = 1.0, completionDelegate: CAAnimationDelegate? = nil) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = CGFloat(.pi * 2.0)
        animation.duration = 1.0
        if let delegate: CAAnimationDelegate = completionDelegate {
            animation.delegate = delegate
        }
        self.layer.add(animation, forKey: nil)
    }
}

class VideoDisplayController: UIViewController, ErrorHandler, DialHandler, CAAnimationDelegate {

    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var placeholder: UIImageView!
    @IBOutlet weak var placeholderText: UILabel!
    var mainView: UIView?
    var insertView: UIView?

    //MARK: Properties
    var sessionModel = SessionModel.sharedInstance
    var connectionModel = ConnectionModel.sharedInstance
    
    // MARK: Initialisation
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionModel.setDialHandler(self)
        self.hangupButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.connectionModel.setVideoDisplayer(self)
        self.connectionModel.setErrorHandler(self)
        self.sessionModel.dial()
        self.placeholder.isHidden = false
        self.placeholderText.isHidden = false
        self.placeholder.rotate360Degrees(duration: 2.0, completionDelegate: self)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.connectionModel.otSubscriber == nil {
            self.placeholder.rotate360Degrees(duration: 2.0, completionDelegate: self)
        }
        else {
            self.placeholder.isHidden = true
            self.placeholderText.isHidden = true
        }
    }

    func onDialFailure(_ reason: String) {
        showAlert("Couldn't find a translator: " + reason)
    }

    //MARK: Session/State transition functions
    func onDialSuccess() {
        self.hangupButton.isEnabled = true
        self.connectionModel.connect()
    }

    func onHangupSuccess() {
        UIApplication.shared.isIdleTimerDisabled = false
        self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
    }

    func onDisconnectComplete() {
        self.sessionModel.hangUp()
    }

    //MARK: UI Actions
    @IBAction func hangupClicked(_ sender: Any) {
        if self.connectionModel.otSession == nil {
            // This is probably the second time we've hit hangup.  So just segue
            UIApplication.shared.isIdleTimerDisabled = false
            self.performSegue(withIdentifier: "unwindToReadyToCall", sender: self)
            return
        }

        self.connectionModel.cleanupPublisher()
        self.connectionModel.cleanupSubscriber(streamDestroyed: false)
        self.connectionModel.disconnect()
        self.onDisconnectComplete()
    }

    //MARK: Error handling
    fileprivate func handleAlert(action:UIAlertAction) {
        self.onHangupSuccess()
    }

    func showAlert(_ err: String) {
        print("Alert: " + err)
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: self.handleAlert))
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension VideoDisplayController: VideoDisplayer {
    func displayVideo(_ subscriberView: UIView) {
        let insetTop = CGFloat(80.0)
        let insetBottom = view.frame.size.height - hangupButton.frame.origin.y + CGFloat(8)
        subscriberView.frame = CGRect(x: 2.0, y: insetTop,
                                      width: view.frame.size.width - 4,
                                      height: view.frame.size.height - insetTop - insetBottom)
        view.insertSubview(subscriberView, at: 0)
        self.mainView = subscriberView
    }

    func displayInsert(_ publisherView: UIView) {
        let width = view.frame.size.width/4
        let height = view.frame.size.height/4
        let insetTop = hangupButton.frame.origin.y - (height + 12)
        let baseView = UIView(frame: CGRect(x:4.0, y: insetTop, width: width + 2, height: height + 2))
        baseView.backgroundColor = .white
        view.addSubview(baseView)
        publisherView.frame = CGRect(x: 5.0, y: insetTop + 1, width: width, height: height)
        view.addSubview(publisherView)
        self.insertView = publisherView
    }
}
