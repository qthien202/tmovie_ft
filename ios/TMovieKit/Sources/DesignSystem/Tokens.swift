import SwiftUI

// Brand: Transformative Teal. Dark-first; the app forces `.dark`.
extension Color {
    public static let brand = Color(red: 0.06, green: 0.57, blue: 0.56)
    public static let brandLight = Color(red: 0.4, green: 0.9, blue: 0.8)
    public static let canvas = Color(red: 0.02, green: 0.03, blue: 0.04)
}

extension ShapeStyle where Self == LinearGradient {
    /// Teal wordmark gradient.
    public static var brandGradient: LinearGradient {
        LinearGradient(colors: [.brand, .brandLight], startPoint: .leading, endPoint: .trailing)
    }
}

extension Animation {
    /// Page / hero motion.
    public static let cinematic = Animation.spring(response: 0.45, dampingFraction: 0.85)
}
