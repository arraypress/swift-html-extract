//
//  Link.swift
//  HTMLExtract
//

import Foundation

/// An `<a href>` as found, with its destination resolved.
public struct Link: Sendable, Hashable, Codable {

    /// The destination as an absolute URL, when it can be one.
    ///
    /// `nil` when the `href` is relative and no base was given, or is not a
    /// URL at all (`javascript:void(0)`). ``href`` keeps the original text
    /// either way.
    public let url: URL?

    /// The `href` exactly as written in the document.
    public let href: String

    /// The link's text, whitespace collapsed. Empty for an image-only link.
    public let text: String

    /// The `title` attribute, when present.
    public let title: String?

    /// A link as read from the document.
    public init(url: URL?, href: String, text: String, title: String?) {
        self.url = url
        self.href = href
        self.text = text
        self.title = title
    }
}
