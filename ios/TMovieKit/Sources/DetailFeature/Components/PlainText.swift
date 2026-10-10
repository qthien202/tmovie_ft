import Foundation

/// PhimAPI `content` is light HTML (`<p>`, entities). Rendered as plain text in our own type style.
@MainActor func plainText(_ html: String) -> String {
    let attributed = try? NSAttributedString(
        data: Data(html.utf8),
        options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
        documentAttributes: nil
    )
    return (attributed?.string ?? html).trimmingCharacters(in: .whitespacesAndNewlines)
}
