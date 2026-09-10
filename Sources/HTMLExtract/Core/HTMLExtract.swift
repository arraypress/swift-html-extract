//
//  HTMLExtract.swift
//  HTMLExtract
//
//  The namespace: every extraction starts here, and the parser stays inside.
//

import Foundation
import SwiftSoup

/// Values out of HTML by CSS selector — text, attributes, links, tables,
/// lists and the page's structured data — offline, without a web view.
///
/// This is the tool for "the price in `.price`". For "the article as
/// Markdown" use `swift-markdownify`, which renders the page in a hidden web
/// view first; that answers a different question at a different cost.
///
/// Every function parses the HTML it is handed. Pass the same document to
/// ``record(from:fields:base:)`` to read ten fields from one parse.
public enum HTMLExtract {

    // MARK: - Single values

    /// The text of every element the selector matches, whitespace collapsed.
    ///
    /// `first` returns at most one — the way a heading or a price is asked
    /// for — without the caller writing `:first` selectors that SwiftSoup
    /// reads differently from a browser.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when nothing matches.
    public static func text(from html: String, matching selector: String, first: Bool = false) throws -> [String] {
        let elements = try matches(selector, in: parse(html), first: first)
        return try elements.map { Whitespace.normalized(try $0.text()) }
    }

    /// A named attribute of every matching element that carries it.
    ///
    /// Elements without the attribute are skipped, so the result can be
    /// shorter than the match count, or empty. `alt=""` is kept as an empty
    /// string: an author who wrote it meant it.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when nothing matches.
    public static func attribute(_ name: String, from html: String, matching selector: String, first: Bool = false) throws -> [String] {
        let elements = try matches(selector, in: parse(html), first: first)
        return try elements.compactMap { element in
            element.hasAttr(name) ? try element.attr(name) : nil
        }
    }

    /// The HTML of every matching element — inside the tag by default, or the
    /// element itself with `inner: false`.
    ///
    /// Not whitespace-collapsed: markup is handed back as markup, for a
    /// caller that will parse it again or store it.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when nothing matches.
    public static func html(from html: String, matching selector: String, inner: Bool = true, first: Bool = false) throws -> [String] {
        let elements = try matches(selector, in: parse(html), first: first)
        return try elements.map { inner ? try $0.html() : try $0.outerHtml() }
    }

    // MARK: - Links and images

    /// Every `<a href>` in the document, or within the elements a selector
    /// matches, with destinations resolved against `base`.
    ///
    /// Relative links are the norm on real pages and useless once the HTML
    /// has left its origin. With a base, `../pricing` becomes a URL that
    /// opens; without one, ``Link/url`` is `nil` and ``Link/href`` still says
    /// what was written.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when a selector was given and
    ///   matches nothing. A document with no links returns an empty array.
    public static func links(from html: String, matching selector: String? = nil, base: URL? = nil) throws -> [Link] {
        let document = try parse(html)
        let scope = try scopeElements(selector, in: document)
        var links: [Link] = []
        for element in scope {
            for anchor in try element.select("a[href]").array() {
                let href = try anchor.attr("href")
                links.append(Link(
                    url: URLResolution.resolve(href, against: base),
                    href: href,
                    text: Whitespace.normalized(try anchor.text()),
                    title: anchor.hasAttr("title") ? try anchor.attr("title") : nil
                ))
            }
        }
        return links
    }

    /// Every `<img src>` in the document, or within the elements a selector
    /// matches, with sources resolved against `base`.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when a selector was given and
    ///   matches nothing. A document with no images returns an empty array.
    public static func images(from html: String, matching selector: String? = nil, base: URL? = nil) throws -> [Image] {
        let document = try parse(html)
        let scope = try scopeElements(selector, in: document)
        var images: [Image] = []
        for element in scope {
            for image in try element.select("img[src]").array() {
                let src = try image.attr("src")
                images.append(Image(
                    url: URLResolution.resolve(src, against: base),
                    src: src,
                    alt: Whitespace.normalized(try image.attr("alt")),
                    title: image.hasAttr("title") ? try image.attr("title") : nil
                ))
            }
        }
        return images
    }

    // MARK: - Tables and lists

    /// The first table the selector reaches, read into cells.
    ///
    /// The match may be the `<table>` itself or something that contains one
    /// — `#results` around a table is the usual shape. Headers come from
    /// `<thead>`, or from a first row of `<th>` cells; cells are
    /// whitespace-collapsed; ``Table/records`` keys each row by header.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``,
    ///   ``HTMLExtractError/noMatch(_:)``, or
    ///   ``HTMLExtractError/notATable(_:)`` when the match holds no table.
    public static func table(from html: String, matching selector: String = "table") throws -> Table {
        let document = try parse(html)
        guard let match = try matches(selector, in: document, first: true).first else {
            throw HTMLExtractError.noMatch(selector)
        }
        let table: Element
        if match.tagName() == "table" {
            table = match
        } else if let inner = try match.select("table").first() {
            table = inner
        } else {
            throw HTMLExtractError.notATable(selector)
        }
        return try read(table: table)
    }

    /// The items of a list.
    ///
    /// The selector may name the `<ul>` or `<ol>`, the `<li>` elements
    /// directly, or a container; in each case the answer is the text of the
    /// list items, one string each, nested lists flattened into their parent
    /// item's text.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``, or
    ///   ``HTMLExtractError/noMatch(_:)`` when no items are reached.
    public static func list(from html: String, matching selector: String) throws -> [String] {
        let document = try parse(html)
        var items: [Element] = []
        for element in try matches(selector, in: document, first: false) {
            switch element.tagName() {
            case "ul", "ol":
                items += element.children().array().filter { $0.tagName() == "li" }
            case "li":
                items.append(element)
            default:
                items += try element.select("li").array()
            }
        }
        guard !items.isEmpty else { throw HTMLExtractError.noMatch(selector) }
        return try items.map { Whitespace.normalized(try $0.text()) }
    }

    // MARK: - Records

    /// Several fields from one parse of the document.
    ///
    /// The shape a scraper actually wants: a name per selector, a dictionary
    /// back. A field whose selector matches nothing is ``ExtractedValue/missing``
    /// — the other fields are still answered, and the caller decides whether
    /// a missing price is fatal. Only a selector that cannot be parsed at
    /// all throws, because that is a bug in the request, not a change on the
    /// page.
    ///
    /// - Throws: ``HTMLExtractError/invalidSelector(_:)``.
    public static func record(from html: String, fields: [String: Field], base: URL? = nil) throws -> [String: ExtractedValue] {
        let document = try parse(html)
        var result: [String: ExtractedValue] = [:]
        for (name, field) in fields {
            result[name] = try value(of: field, in: document, base: base)
        }
        return result
    }

    // MARK: - Structured data

    /// What the page declares about itself: JSON-LD, Open Graph, every
    /// `<meta>` with a name, the canonical URL and the title.
    ///
    /// Read this before writing selectors. A product page's price, an
    /// article's author and date, the share image and the canonical address
    /// are usually here in a form that survives redesigns.
    ///
    /// - Parameter base: resolves a relative canonical link; optional.
    public static func structuredData(from html: String, base: URL? = nil) throws -> StructuredData {
        let document = try parse(html)

        let jsonLD = try document.select("script[type=application/ld+json]").array()
            .map { $0.data().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var meta: [String: String] = [:]
        for element in try document.select("meta").array() {
            let name = element.hasAttr("property") ? try element.attr("property") : try element.attr("name")
            let content = element.hasAttr("content") ? try element.attr("content") : nil
            if let (key, value) = MetaTags.pair(name: name, content: content) {
                meta[key] = value
            }
        }

        let canonical = try document.select("link[rel=canonical][href]").first()
            .flatMap { try URLResolution.resolve(try $0.attr("href"), against: base) }

        let title = Whitespace.normalized(try document.title())

        return StructuredData(
            jsonLD: jsonLD,
            openGraph: MetaTags.openGraph(from: meta),
            meta: meta,
            canonical: canonical,
            title: title.isEmpty ? nil : title
        )
    }

    // MARK: - Internals

    /// The parsed document. SwiftSoup is lenient to the point of never
    /// refusing, so a throw here is genuinely unusual and reported as such.
    static func parse(_ html: String) throws -> Document {
        do {
            return try SwiftSoup.parse(html)
        } catch {
            throw HTMLExtractError.unreadable(String(describing: error))
        }
    }

    /// The elements a selector matches, or a typed error for a selector the
    /// parser cannot read. SwiftSoup reports that as its own exception type;
    /// callers here get one error enum.
    static func select(_ selector: String, in root: Element) throws -> [Element] {
        do {
            return try root.select(selector).array()
        } catch {
            throw HTMLExtractError.invalidSelector(selector)
        }
    }

    /// The matches, requiring at least one, cut to the first when asked.
    static func matches(_ selector: String, in root: Element, first: Bool) throws -> [Element] {
        let elements = try select(selector, in: root)
        guard !elements.isEmpty else { throw HTMLExtractError.noMatch(selector) }
        return first ? Array(elements.prefix(1)) : elements
    }

    /// The whole document when no selector is given, otherwise the matches.
    static func scopeElements(_ selector: String?, in document: Document) throws -> [Element] {
        guard let selector else { return [document] }
        return try matches(selector, in: document, first: false)
    }

    /// One field's answer.
    static func value(of field: Field, in document: Document, base: URL?) throws -> ExtractedValue {
        switch field {
        case .text(let selector):
            guard let element = try select(selector, in: document).first else { return .missing }
            return .text(Whitespace.normalized(try element.text()))
        case .attribute(let selector, let name):
            guard let element = try select(selector, in: document).first, element.hasAttr(name) else { return .missing }
            return .text(try element.attr(name))
        case .html(let selector):
            guard let element = try select(selector, in: document).first else { return .missing }
            return .text(try element.html())
        case .link(let selector):
            guard let element = try select(selector, in: document).first, element.hasAttr("href"),
                  let url = URLResolution.resolve(try element.attr("href"), against: base) else { return .missing }
            return .text(url.absoluteString)
        case .all(let selector):
            let elements = try select(selector, in: document)
            guard !elements.isEmpty else { return .missing }
            return .list(try elements.map { Whitespace.normalized(try $0.text()) })
        }
    }

    /// A `<table>` element into a ``Table``.
    ///
    /// Header rows are found in `<thead>` first; failing that, a first row
    /// whose cells are all `<th>` is the header. Every other `<tr>` is a body
    /// row, whatever section it sits in, so a `<tfoot>` total is a row too —
    /// it is data, and the caller can drop it by position.
    static func read(table: Element) throws -> Table {
        let allRows = try table.select("tr").array()
        var headers: [String] = []
        var bodyRows = allRows

        if let headRow = try table.select("thead tr").first() {
            headers = try cells(of: headRow)
            bodyRows = allRows.filter { $0 !== headRow && !isInHead($0) }
        } else if let firstRow = allRows.first,
                  !firstRow.children().isEmpty(),
                  firstRow.children().array().allSatisfy({ $0.tagName() == "th" }) {
            headers = try cells(of: firstRow)
            bodyRows = Array(allRows.dropFirst())
        }

        return Table(headers: headers, rows: try bodyRows.map(cells(of:)))
    }

    /// The text of each `<td>` or `<th>` in a row.
    static func cells(of row: Element) throws -> [String] {
        try row.children().array()
            .filter { $0.tagName() == "td" || $0.tagName() == "th" }
            .map { Whitespace.normalized(try $0.text()) }
    }

    /// Whether a row lives in `<thead>`.
    static func isInHead(_ row: Element) -> Bool {
        var current = row.parent()
        while let element = current {
            if element.tagName() == "thead" { return true }
            if element.tagName() == "table" { return false }
            current = element.parent()
        }
        return false
    }
}
