//
//  URLResolution.swift
//  HTMLExtract
//
//  Turning what the author wrote in href into something that can be opened.
//

import Foundation

/// Resolving the references a document makes against the address it lives at.
enum URLResolution {

    /// The absolute URL a reference names, or `nil` when it cannot be one.
    ///
    /// Four spellings need four answers, and a browser gets all of them
    /// right silently:
    ///
    /// - `https://…`, `mailto:`, `tel:`, `data:` — already absolute; the base
    ///   is irrelevant.
    /// - `//cdn.example.com/a.js` — scheme-relative; it takes the base's
    ///   scheme and nothing else.
    /// - `../a`, `/a`, `a`, `?q=1`, `#top` — relative; meaningful only
    ///   against a base, so without one the answer is `nil` rather than a
    ///   `URL` whose `absoluteString` is still `../a`.
    /// - `javascript:void(0)` and friends — a scheme, so it parses, and a
    ///   caller can drop it by scheme if it wants links it can fetch.
    static func resolve(_ reference: String, against base: URL?) -> URL? {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("//") {
            guard let scheme = base?.scheme else { return nil }
            return URL(string: "\(scheme):\(trimmed)")
        }
        if hasScheme(trimmed) {
            return URL(string: trimmed)
        }
        guard let base else { return nil }
        return URL(string: trimmed, relativeTo: base)?.absoluteURL
    }

    /// Whether the reference starts with a URL scheme (`https:`, `mailto:`).
    ///
    /// A scheme is letters, digits, `+`, `-` and `.` up to the first colon,
    /// starting with a letter. `C:\path` qualifies, which is the correct
    /// reading of a string that starts that way — the browser agrees.
    static func hasScheme(_ reference: String) -> Bool {
        guard let colon = reference.firstIndex(of: ":") else { return false }
        let candidate = reference[..<colon]
        guard let first = candidate.first, first.isLetter else { return false }
        return candidate.allSatisfy { $0.isLetter || $0.isNumber || $0 == "+" || $0 == "-" || $0 == "." }
    }
}
