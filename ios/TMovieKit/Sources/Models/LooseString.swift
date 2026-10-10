import Foundation

/// A value PhimAPI sends as either a string or a number (`episode_total`, `tmdb.id`).
public struct LooseString: Codable, Hashable, Sendable, CustomStringConvertible {
    public let value: String
    public var description: String { value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { value = s }
        else if let i = try? c.decode(Int.self) { value = String(i) }
        else { value = String(try c.decode(Double.self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}
