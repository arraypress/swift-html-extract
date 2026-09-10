//
//  Image.swift
//  HTMLExtract
//

import Foundation

/// An `<img src>` as found, with its source resolved.
public struct Image: Sendable, Hashable, Codable {

    /// The source as an absolute URL, when it can be one.
    ///
    /// `nil` when the `src` is relative and no base was given. ``src`` keeps
    /// the original text either way.
    public let url: URL?

    /// The `src` exactly as written in the document.
    public let src: String

    /// The `alt` text, whitespace collapsed. Empty when the attribute is
    /// empty or absent — the two mean different things to a screen reader,
    /// but not to somebody harvesting captions.
    public let alt: String

    /// The `title` attribute, when present.
    public let title: String?

    /// An image as read from the document.
    public init(url: URL?, src: String, alt: String, title: String?) {
        self.url = url
        self.src = src
        self.alt = alt
        self.title = title
    }
}
