import SwiftUI

// Brand: electric blue #3D8BFF (was teal). Dark-first; the app forces `.dark`.
extension Color {
    public static let brand = Color(red: 0.24, green: 0.545, blue: 1.0)
    public static let brandLight = Color(red: 0.54, green: 0.74, blue: 1.0)
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
