import CoreMotion
import Observation

/// Smoothed device tilt (radians, relative to how the phone was held when started) for depth parallax.
@MainActor @Observable
final class TiltMotion {
    private(set) var roll = 0.0
    private(set) var pitch = 0.0
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var reference: (roll: Double, pitch: Double)?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let a = motion?.attitude else { return }
            let (roll, pitch) = (a.roll, a.pitch)
            MainActor.assumeIsolated { self?.update(roll: roll, pitch: pitch) }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        reference = nil
        roll = 0
        pitch = 0
    }

    private func update(roll r: Double, pitch p: Double) {
        let ref = reference ?? (r, p)
        reference = ref
        let clamp = { (v: Double) in max(-0.4, min(0.4, v)) }
        // Low-pass so the layers glide instead of jitter.
        roll += (clamp(r - ref.roll) - roll) * 0.12
        pitch += (clamp(p - ref.pitch) - pitch) * 0.12
    }
}
