import UIKit

/// The app is portrait; the player unlocks landscape while it is on screen.
/// The app delegate returns `mask` from `supportedInterfaceOrientationsFor`.
@MainActor
public enum OrientationLock {
    public private(set) static var mask: UIInterfaceOrientationMask = .portrait

    public static func rotate(to target: UIInterfaceOrientationMask) {
        mask = target == .portrait ? .portrait : .allButUpsideDown
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: target))
    }
}
