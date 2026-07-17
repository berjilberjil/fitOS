import Foundation
import LocalAuthentication

/// Optional Face ID / Touch ID app lock. The preference is device-local
/// (UserDefaults), not synced — it's a per-device security choice.
enum BiometricLock {
    static let key = "fitos.faceIDLock"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var biometryName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "biometrics"
        }
    }

    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Prompt for biometric (falls back to device passcode). Returns success.
    static func authenticate(reason: String = "Unlock fitOS") async -> Bool {
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return true }
        return await withCheckedContinuation { cont in
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, _ in
                cont.resume(returning: ok)
            }
        }
    }
}
