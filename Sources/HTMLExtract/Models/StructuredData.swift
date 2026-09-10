//
//  StructuredData.swift
//  HTMLExtract
//

import Foundation

/// The machine-readable layer of a page: what it says about itself when
/// nobody is looking at the layout.
///
/// Most of what a scraper wants — a product's price, an article's author, the
/// canonical URL, the share image — is declared here in a stable form long
/// before it is rendered into markup that changes with every redesign. Read
/// this first; reach for selectors when it is incomplete.
public struct StructuredData: Sendable, Hashable, Codable {

    /// Each `<script type="application/ld+json">` body, as JSON text, in
    /// document order.
    ///
    /// Kept as text rather than decoded, because a caller knows which schema
    /// it expects and `Codable` is the right tool for that — and a page with
    /// three blocks may have three different ones.
    public let jsonLD: [String]

    /// Open Graph properties with the `og:` prefix removed: `title`,
    /// `description`, `image`, `url`, `type`, `site_name`.
    public let openGraph: [String: String]

    /// Every `<meta>` with a `name` or `property`, keyed by that name as
    /// written — `description`, `twitter:card`, `og:title` (again, with its
    /// prefix), `article:published_time`.
    public let meta: [String: String]

    /// The `<link rel="canonical">` destination, when present and a URL.
    public let canonical: URL?

    /// The `<title>`, whitespace collapsed. `nil` when absent or empty.
    public let title: String?

    /// The declarations as read from the document.
    public init(jsonLD: [String], openGraph: [String: String], meta: [String: String], canonical: URL?, title: String?) {
        self.jsonLD = jsonLD
        self.openGraph = openGraph
        self.meta = meta
        self.canonical = canonical
        self.title = title
    }
}
