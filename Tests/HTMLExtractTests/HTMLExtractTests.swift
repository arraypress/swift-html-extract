//
//  HTMLExtractTests.swift
//  HTMLExtract
//
//  Every test is a fixed document and one right answer. Nothing here reaches
//  the network, and nothing depends on what a live page looked like on the
//  day the test was written.
//

import XCTest
@testable import HTMLExtract

final class TextTests: XCTestCase {

    func testHeadingTextCollapsesTheIndentationInsideIt() throws {
        XCTAssertEqual(try HTMLExtract.text(from: Fixtures.product, matching: "h1"), ["Blue Widget"])
    }

    func testFirstReturnsAtMostOneWhereAllReturnsEvery() throws {
        XCTAssertEqual(try HTMLExtract.text(from: Fixtures.product, matching: "a").count, 5)
        XCTAssertEqual(try HTMLExtract.text(from: Fixtures.product, matching: "a", first: true), ["Buy"])
    }

    func testEntitiesAreDecodedAndTheNoBreakSpaceBecomesASpace() throws {
        XCTAssertEqual(
            try HTMLExtract.text(from: Fixtures.product, matching: ".tagline"),
            ["Widgets & gadgets, 1 234 sold"]
        )
    }

    func testAPriceSplitAcrossASpanReadsAsOneString() throws {
        XCTAssertEqual(try HTMLExtract.text(from: Fixtures.product, matching: ".price"), ["£12.99"])
    }

    func testAnEmptyElementIsAnEmptyString() throws {
        XCTAssertEqual(try HTMLExtract.text(from: Fixtures.product, matching: ".empty"), [""])
    }

    func testNothingMatchingIsAnError() {
        XCTAssertThrowsError(try HTMLExtract.text(from: Fixtures.product, matching: ".nope")) { error in
            XCTAssertEqual(error as? HTMLExtractError, .noMatch(".nope"))
        }
    }

    func testABrokenSelectorIsItsOwnError() {
        // SwiftSoup forgives an unclosed bracket; a lone one and an empty
        // selector it refuses, and both arrive as the same error here.
        XCTAssertThrowsError(try HTMLExtract.text(from: Fixtures.product, matching: "[")) { error in
            XCTAssertEqual(error as? HTMLExtractError, .invalidSelector("["))
        }
        XCTAssertThrowsError(try HTMLExtract.text(from: Fixtures.product, matching: "")) { error in
            XCTAssertEqual(error as? HTMLExtractError, .invalidSelector(""))
        }
    }

    func testAttributesComeFromTheElementsThatHaveThem() throws {
        XCTAssertEqual(try HTMLExtract.attribute("title", from: Fixtures.product, matching: "a"), ["Buy now"])
        XCTAssertEqual(try HTMLExtract.attribute("alt", from: Fixtures.product, matching: "img").count, 2)
        // alt="" is a statement, and it stays.
        XCTAssertEqual(try HTMLExtract.attribute("alt", from: Fixtures.product, matching: "img").last, "")
    }

    func testInnerAndOuterHTMLAreMarkupNotText() throws {
        XCTAssertEqual(try HTMLExtract.html(from: Fixtures.product, matching: ".price"), ["£12<span>.99</span>"])
        XCTAssertEqual(
            try HTMLExtract.html(from: Fixtures.product, matching: ".price", inner: false),
            ["<p class=\"price\">£12<span>.99</span></p>"]
        )
    }
}

final class LinkTests: XCTestCase {

    func testRelativeLinksResolveAgainstTheBase() throws {
        let links = try HTMLExtract.links(from: Fixtures.product, base: Fixtures.base)
        XCTAssertEqual(links.count, 5)
        XCTAssertEqual(links[0].url?.absoluteString, "https://shop.example.com/checkout?sku=blue")
        XCTAssertEqual(links[0].href, "../checkout?sku=blue")
        XCTAssertEqual(links[0].text, "Buy")
        XCTAssertEqual(links[0].title, "Buy now")
        XCTAssertEqual(links[1].url?.absoluteString, "https://shop.example.com/products/blue-widget#reviews")
        XCTAssertEqual(links[2].url?.absoluteString, "mailto:sales@example.com")
        XCTAssertEqual(links[3].url?.absoluteString, "https://other.example.org/x")
        XCTAssertEqual(links[4].url?.scheme, "javascript")
        XCTAssertNil(links[1].title)
    }

    func testWithoutABaseARelativeLinkHasNoURLButKeepsItsHref() throws {
        let links = try HTMLExtract.links(from: Fixtures.product)
        XCTAssertNil(links[0].url)
        XCTAssertEqual(links[0].href, "../checkout?sku=blue")
        XCTAssertEqual(links[3].url?.absoluteString, "https://other.example.org/x")
    }

    func testLinksCanBeScopedToASelector() throws {
        let links = try HTMLExtract.links(from: Fixtures.product, matching: "#buy", base: Fixtures.base)
        XCTAssertEqual(links.map(\.text), ["Buy"])
        XCTAssertThrowsError(try HTMLExtract.links(from: Fixtures.product, matching: "#missing"))
    }

    func testImagesResolveAndCollapseTheirAltText() throws {
        let images = try HTMLExtract.images(from: Fixtures.product, base: Fixtures.base)
        XCTAssertEqual(images.count, 2)
        XCTAssertEqual(images[0].url?.absoluteString, "https://shop.example.com/products/images/blue.png")
        XCTAssertEqual(images[0].alt, "The blue widget")
        XCTAssertEqual(images[0].title, "Blue")
        XCTAssertEqual(images[1].alt, "")
        XCTAssertNil(images[1].title)
    }
}

final class URLResolutionTests: XCTestCase {

    private let base = URL(string: "https://shop.example.com/a/b/page.html?x=1")!

    func testEachSpellingResolvesTheWayABrowserWould() {
        XCTAssertEqual(URLResolution.resolve("../c", against: base)?.absoluteString, "https://shop.example.com/a/c")
        XCTAssertEqual(URLResolution.resolve("/root", against: base)?.absoluteString, "https://shop.example.com/root")
        XCTAssertEqual(URLResolution.resolve("d.html", against: base)?.absoluteString, "https://shop.example.com/a/b/d.html")
        XCTAssertEqual(URLResolution.resolve("?q=2", against: base)?.absoluteString, "https://shop.example.com/a/b/page.html?q=2")
        XCTAssertEqual(URLResolution.resolve("#top", against: base)?.absoluteString, "https://shop.example.com/a/b/page.html?x=1#top")
        XCTAssertEqual(URLResolution.resolve("//cdn.example.com/a.js", against: base)?.absoluteString, "https://cdn.example.com/a.js")
        XCTAssertEqual(URLResolution.resolve("https://x.example.org/", against: base)?.absoluteString, "https://x.example.org/")
        XCTAssertEqual(URLResolution.resolve(" mailto:a@example.com ", against: base)?.absoluteString, "mailto:a@example.com")
    }

    func testRelativeReferencesWithoutABaseAreNil() {
        XCTAssertNil(URLResolution.resolve("../c", against: nil))
        XCTAssertNil(URLResolution.resolve("//cdn.example.com/a.js", against: nil))
        XCTAssertNil(URLResolution.resolve("", against: base))
        XCTAssertEqual(URLResolution.resolve("https://x.example.org/", against: nil)?.absoluteString, "https://x.example.org/")
    }

    func testASchemeIsLettersUpToTheFirstColon() {
        XCTAssertTrue(URLResolution.hasScheme("mailto:a@b"))
        XCTAssertTrue(URLResolution.hasScheme("data:text/plain,hi"))
        XCTAssertFalse(URLResolution.hasScheme("page.html?time=12:30"))
        XCTAssertFalse(URLResolution.hasScheme("../a:b"))
        XCTAssertFalse(URLResolution.hasScheme("1st:thing"))
    }
}

final class TableTests: XCTestCase {

    func testAHeadedTableGivesHeadersRowsAndRecords() throws {
        let table = try HTMLExtract.table(from: Fixtures.product, matching: "#specs")
        XCTAssertEqual(table.headers, ["Name", "Value", "", "Value"])
        XCTAssertEqual(table.rows.count, 3)
        XCTAssertEqual(table.rows[0], ["Weight", "1.2 kg", "a", "x"])
        XCTAssertEqual(table.rows[1], ["Width", "10 cm"])
        // The footer is data too; it comes last and the caller can drop it.
        XCTAssertEqual(table.rows[2].first, "Total")
    }

    func testRecordsNameEmptyAndRepeatedHeadersAndCopeWithShortRows() throws {
        let table = try HTMLExtract.table(from: Fixtures.product, matching: "#specs")
        XCTAssertEqual(table.records[0], ["Name": "Weight", "Value": "1.2 kg", "Column 3": "a", "Value 2": "x"])
        XCTAssertEqual(table.records[1], ["Name": "Width", "Value": "10 cm"])
    }

    func testAFirstRowOfHeaderCellsIsTheHeaderWhenThereIsNoThead() throws {
        let table = try HTMLExtract.table(from: Fixtures.product, matching: "#plain")
        XCTAssertEqual(table.headers, ["City", "Pop"])
        XCTAssertEqual(table.rows, [["Leeds", "800k"]])
        XCTAssertEqual(table.records, [["City": "Leeds", "Pop": "800k"]])
    }

    func testATableWithNoHeadersHasRowsAndNoRecords() throws {
        let table = try HTMLExtract.table(from: Fixtures.product, matching: "#bare")
        XCTAssertEqual(table.headers, [])
        XCTAssertEqual(table.rows, [["1", "2"], ["3", "4"]])
        XCTAssertEqual(table.records, [])
    }

    func testTheDefaultSelectorIsTheFirstTable() throws {
        XCTAssertEqual(try HTMLExtract.table(from: Fixtures.product).headers.first, "Name")
    }

    func testSomethingThatIsNotATableSaysSo() {
        XCTAssertThrowsError(try HTMLExtract.table(from: Fixtures.product, matching: "#features")) { error in
            XCTAssertEqual(error as? HTMLExtractError, .notATable("#features"))
        }
    }

    func testAssemblyRulesDirectly() {
        XCTAssertEqual(TableAssembly.uniqueKeys(["A", "", "A", "A"]), ["A", "Column 2", "A 2", "A 3"])
        XCTAssertEqual(TableAssembly.records(headers: [], rows: [["1"]]), [])
        XCTAssertEqual(TableAssembly.records(headers: ["A"], rows: [["1", "2"]]), [["A": "1"]])
    }
}

final class ListTests: XCTestCase {

    func testAListGivesItsTopLevelItemsWithNestedListsFlattenedIn() throws {
        XCTAssertEqual(
            try HTMLExtract.list(from: Fixtures.product, matching: "#features"),
            ["Waterproof", "Two colours Blue Bluer", "Guaranteed"]
        )
    }

    func testItemsCanBeSelectedDirectly() throws {
        XCTAssertEqual(try HTMLExtract.list(from: Fixtures.product, matching: "#features > li > ul > li"), ["Blue", "Bluer"])
    }

    func testAContainerWithNoItemsIsNoMatch() {
        XCTAssertThrowsError(try HTMLExtract.list(from: Fixtures.product, matching: "#specs")) { error in
            XCTAssertEqual(error as? HTMLExtractError, .noMatch("#specs"))
        }
    }
}

final class RecordTests: XCTestCase {

    func testAWholeRecordFromOneParseWithAMissingFieldKeptAsMissing() throws {
        let record = try HTMLExtract.record(from: Fixtures.product, fields: [
            "name": .text("h1"),
            "price": .text(".price"),
            "buy": .link("#buy"),
            "sku": .attribute("#buy", "data-sku"),
            "image": .attribute("img", "src"),
            "blurb": .html(".price"),
            "features": .all("#features > li"),
            "rating": .text(".rating"),
        ], base: Fixtures.base)

        XCTAssertEqual(record["name"], .text("Blue Widget"))
        XCTAssertEqual(record["price"], .text("£12.99"))
        XCTAssertEqual(record["buy"], .text("https://shop.example.com/checkout?sku=blue"))
        XCTAssertEqual(record["sku"], .missing)
        XCTAssertEqual(record["image"], .text("images/blue.png"))
        XCTAssertEqual(record["blurb"], .text("£12<span>.99</span>"))
        XCTAssertEqual(record["features"], .list(["Waterproof", "Two colours Blue Bluer", "Guaranteed"]))
        XCTAssertEqual(record["rating"], .missing)
    }

    func testALinkWithoutABaseIsMissingRatherThanAFragment() throws {
        let record = try HTMLExtract.record(from: Fixtures.product, fields: ["buy": .link("#buy"), "away": .link("a[href^=https]")])
        XCTAssertEqual(record["buy"], .missing)
        XCTAssertEqual(record["away"], .text("https://other.example.org/x"))
    }

    func testOnlyABrokenSelectorThrows() {
        XCTAssertThrowsError(try HTMLExtract.record(from: Fixtures.product, fields: ["x": .text("[")])) { error in
            XCTAssertEqual(error as? HTMLExtractError, .invalidSelector("["))
        }
    }

    func testTheValueAccessors() {
        XCTAssertEqual(ExtractedValue.text("a").text, "a")
        XCTAssertNil(ExtractedValue.list(["a"]).text)
        XCTAssertEqual(ExtractedValue.list(["a", "b"]).values, ["a", "b"])
        XCTAssertEqual(ExtractedValue.text("a").values, ["a"])
        XCTAssertEqual(ExtractedValue.missing.values, [])
        XCTAssertTrue(ExtractedValue.missing.isMissing)
        XCTAssertFalse(ExtractedValue.text("").isMissing)
    }
}

final class StructuredDataTests: XCTestCase {

    func testJSONLDBlocksComeBackAsTextInOrder() throws {
        let data = try HTMLExtract.structuredData(from: Fixtures.product)
        XCTAssertEqual(data.jsonLD.count, 2)
        XCTAssertTrue(data.jsonLD[0].contains("\"price\":\"12.99\""))
        XCTAssertEqual(data.jsonLD[1], "{\"@type\":\"BreadcrumbList\"}")
    }

    func testOpenGraphDropsItsPrefixAndMetaKeepsEverythingNamed() throws {
        let data = try HTMLExtract.structuredData(from: Fixtures.product)
        XCTAssertEqual(data.openGraph, ["title": "Blue Widget", "image": "https://cdn.example.com/blue.jpg"])
        XCTAssertEqual(data.meta["og:title"], "Blue Widget")
        XCTAssertEqual(data.meta["twitter:card"], "summary")
        XCTAssertEqual(data.meta["description"], "A blue widget, with extra spaces.")
        // <meta name="robots"> with no content says nothing, and is not kept.
        XCTAssertNil(data.meta["robots"])
    }

    func testCanonicalResolvesAgainstTheBaseAndTitleIsCollapsed() throws {
        let data = try HTMLExtract.structuredData(from: Fixtures.product, base: Fixtures.base)
        XCTAssertEqual(data.canonical?.absoluteString, "https://shop.example.com/products/blue-widget")
        XCTAssertEqual(data.title, "Widget & Sons — Blue Widget")
        XCTAssertNil(try HTMLExtract.structuredData(from: Fixtures.product).canonical)
    }

    func testAPageWithNothingDeclaredIsEmptyNotAnError() throws {
        let data = try HTMLExtract.structuredData(from: "<p>hi</p>")
        XCTAssertEqual(data.jsonLD, [])
        XCTAssertEqual(data.openGraph, [:])
        XCTAssertEqual(data.meta, [:])
        XCTAssertNil(data.canonical)
        XCTAssertNil(data.title)
    }
}

final class WhitespaceTests: XCTestCase {

    func testRunsCollapseAndEndsTrim() {
        XCTAssertEqual(Whitespace.normalized("  a \n\t b  "), "a b")
        XCTAssertEqual(Whitespace.normalized("1\u{00A0}234"), "1 234")
        XCTAssertEqual(Whitespace.normalized("\n\n"), "")
        XCTAssertEqual(Whitespace.normalized("one"), "one")
    }
}
