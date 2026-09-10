# Swift HTML Extract

Values out of HTML by CSS selector — text, attributes, links, tables, lists and the page's structured data — as typed values, offline, without a web view.

```swift
import HTMLExtract

try HTMLExtract.text(from: html, matching: "h1", first: true)          // ["Blue Widget"]
try HTMLExtract.text(from: html, matching: ".price")                    // ["£12.99"] — even when the pence sit in a <span>

let record = try HTMLExtract.record(from: html, fields: [
    "name":     .text("h1"),
    "price":    .text(".price"),
    "buy":      .link("#buy"),                 // resolved against the base
    "features": .all("#features > li"),
    "rating":   .text(".rating"),              // not on this page
], base: URL(string: "https://shop.example.com/products/blue-widget"))

record["buy"]      // .text("https://shop.example.com/checkout?sku=blue")
record["rating"]   // .missing — the other five are still answered

try HTMLExtract.table(from: html, matching: "#specs").records
// [["Name": "Weight", "Value": "1.2 kg"], ["Name": "Width", "Value": "10 cm"]]
```

## Why

The questions a page answers, and the way they usually get asked wrong:

| Question | The wrong answer, and why it is tempting |
|---|---|
| The price on this page | A regular expression over the source. It works on Tuesday; on Wednesday the price gains a `<span>`, or a comment, or a second currency, and the pattern matches the wrong number or nothing. A parser reads the tree the browser reads. |
| Ten fields from one page | Ten calls, ten parses, and the first stale selector throws and takes the other nine with it. One parse, one record, and a missing field is a value. |
| Where does this link go | `href` as written. It is `../checkout?sku=blue`, which opens nothing once the HTML has left its origin. Resolved against the page's address it opens; without one it is honestly `nil`. |
| The second column of the table | `cells[1]`, until somebody inserts a column. Rows keyed by their header survive that; empty and repeated headers are named so every column stays reachable. |
| The text of a paragraph | The text node, carrying the newline and eight spaces of indentation the author's editor put there, and the no-break space that `&nbsp;` decodes to. Collapsed here the way a browser collapses it. |
| The product's price, author, date, share image | Selectors, when the page already says all of it in JSON-LD and Open Graph, in a form that survives the redesign that breaks the selectors. Read the structured data first. |

## Installation

```swift
.package(url: "https://github.com/arraypress/swift-html-extract.git", from: "0.1.0")
```

One dependency: [SwiftSoup](https://github.com/scinfu/SwiftSoup). Every Apple platform, macOS 14+. No WebKit, so it runs in a command-line tool, a background task and an intent.

## Text, attributes, markup

```swift
try HTMLExtract.text(from: html, matching: "article p")                // every paragraph
try HTMLExtract.text(from: html, matching: "h1", first: true)          // at most one
try HTMLExtract.attribute("href", from: html, matching: "a.download")   // from the elements that have it
try HTMLExtract.attribute("data-id", from: html, matching: "[data-id]")
try HTMLExtract.html(from: html, matching: ".bio")                      // inner HTML, untouched
try HTMLExtract.html(from: html, matching: ".bio", inner: false)        // the element itself
```

Text is whitespace-collapsed and entity-decoded: `Widgets &amp; gadgets` is `Widgets & gadgets`. Markup is not touched. An attribute an element lacks is skipped; `alt=""` is kept as an empty string, because an author who wrote it meant it.

A selector that matches nothing throws ``noMatch``; a selector the parser cannot read throws ``invalidSelector``. They are different mistakes and the message says which.

## Links and images

```swift
let base = URL(string: "https://shop.example.com/products/blue-widget")!

try HTMLExtract.links(from: html, base: base)                  // every <a href>
try HTMLExtract.links(from: html, matching: "nav", base: base) // within the elements a selector matches
try HTMLExtract.images(from: html, base: base)
```

Each `Link` carries `url` (absolute, when it can be), `href` (as written), `text` and `title`; each `Image` carries `url`, `src`, `alt` and `title`. The four spellings of a reference resolve the way a browser resolves them: `https://…` and `mailto:` stand alone, `//cdn.example.com/a.js` takes the base's scheme, `../a` and `#top` need the base, and without one they are `nil` rather than a `URL` whose string is still `../a`.

## Tables

```swift
let table = try HTMLExtract.table(from: html, matching: "#results")
table.headers    // ["Name", "Value"]
table.rows       // [["Weight", "1.2 kg"], ["Width", "10 cm"]]
table.records    // [["Name": "Weight", "Value": "1.2 kg"], …]
```

The selector may name the `<table>` or something around it. Headers come from `<thead>`, or from a first row of `<th>` cells when there is none; a table with neither has rows and no records. A `<tfoot>` total is a row too — it is data, and the caller can drop it by position.

`records` handles the three things a `zip` gets wrong: an empty header is named `Column N`, a repeated header gets a suffix (`Total`, `Total 2`), and a ragged row keeps the cells it has.

## Lists

```swift
try HTMLExtract.list(from: html, matching: "#features")          // the <ul> or <ol>
try HTMLExtract.list(from: html, matching: "#features > li > a") // or the items
```

One string per top-level item; a nested list is flattened into its parent's text.

## A record from one parse

```swift
try HTMLExtract.record(from: html, fields: [
    "title":   .text("h1"),
    "price":   .text(".price"),
    "sku":     .attribute("[data-sku]", "data-sku"),
    "image":   .attribute("img.hero", "src"),
    "buy":     .link("a.buy"),
    "blurb":   .html(".description"),
    "tags":    .all(".tag"),
], base: base)
```

Five `Field` shapes: `.text`, `.attribute`, `.html` and `.link` take the first match; `.all` takes every match. Each answer is an `ExtractedValue` — `.text(String)`, `.list([String])` or `.missing` — with `text`, `values` and `isMissing` accessors, so a caller switches once and is done.

A field that matches nothing is `.missing`, never a throw. A record is nine good answers and one stale selector far more often than it is nothing, and the caller decides whether a missing price is fatal. Only a selector the parser cannot read throws, because that is a bug in the request, not a change on the page.

## What the page says about itself

```swift
let data = try HTMLExtract.structuredData(from: html, base: base)
data.jsonLD        // each <script type="application/ld+json"> body, as JSON text
data.openGraph     // ["title": "Blue Widget", "image": "https://cdn.example.com/blue.jpg"]
data.meta          // every named <meta>: "description", "twitter:card", "og:title", …
data.canonical     // the <link rel="canonical"> destination
data.title         // the <title>, collapsed
```

JSON-LD stays as text: a caller knows which schema it expects and `Codable` is the right tool for that, and a page with three blocks may have three different ones. Open Graph loses its `og:` prefix in its own dictionary and keeps it in `meta`.

## When markdownify is the right tool

`swift-markdownify` renders the page in a hidden web view, runs Readability and Turndown, and hands back the article as Markdown. That is the answer to "what does this page say"; it costs a web view and needs the main thread. This package answers "what is in `.price`", costs a parse, and runs anywhere. A JavaScript-rendered page has nothing in its HTML for a selector to find — use markdownify, then extract from what it rendered if you need to.

## Tested

35 tests, every one a fixed document and one right answer: the first-versus-all cut, an entity and a no-break space, a price split across a span, each of the four link spellings with and without a base, headed, `th`-first and headerless tables, empty and repeated headers, ragged rows, nested lists, a record with a missing field, JSON-LD in order, Open Graph with and without its prefix, a `<meta>` with no content, and the two selector errors. Nothing reaches the network.

## Licence

MIT.
