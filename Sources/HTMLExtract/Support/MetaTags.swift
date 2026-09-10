//
//  MetaTags.swift
//  HTMLExtract
//
//  Sorting a page's <meta> declarations into the shapes people ask for.
//

import Foundation

/// Classifying `<meta>` name/content pairs.
enum MetaTags {

    /// The Open Graph subset, with the `og:` prefix removed.
    ///
    /// `og:title` becomes `title`, because every consumer types the short
    /// form and the prefix carries no information once the pairs are in
    /// their own dictionary. The full name stays available in the unfiltered
    /// map.
    static func openGraph(from meta: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (name, content) in meta where name.hasPrefix("og:") {
            result[String(name.dropFirst(3))] = content
        }
        return result
    }

    /// A name/content pair worth keeping: a non-empty name with content
    /// present. Absent content is dropped rather than stored as an empty
    /// string, because `<meta name="robots">` with no content says nothing.
    static func pair(name: String, content: String?) -> (String, String)? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, let content else { return nil }
        return (key, Whitespace.normalized(content))
    }
}
