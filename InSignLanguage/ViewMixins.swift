import UIKit

protocol PopupManager {
    func showPopup(_ title: String, _ message: String)
    func showPopupCompletion()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

extension PopupManager {
    func showPopup(_ title: String, _ message: String) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) {
            (result : UIAlertAction) -> Void in self.showPopupCompletion()
        }

        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    func showPopupCompletion() {
        print("You pressed OK")
    }
}
