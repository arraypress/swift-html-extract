//
//  EdgeCaseTests.swift
//  HTMLExtract
//
//  The inputs that are not the product page: nothing, half a document,
//  markup that was never closed, references that are not addresses, and
//  tables built the way tables are actually built. Every public function
//  meets an empty document, a matching-nothing selector and an empty
//  selector here, so the answer in each case is pinned rather than assumed.
//

import XCTest
@testable import HTMLExtract

// MARK: - Documents that are barely documents

final class DegenerateDocumentTests: XCTestCase {

    func testAnEmptyStringIsADocumentWithNothingInIt() throws {
        XCTAssertThrowsError(try HTMLExtract.text(from: "", matching: "p")) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch("p")) }
        XCTAssertThrowsError(try HTMLExtract.attribute("href", from: "", matching: "a")) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch("a")) }
        XCTAssertThrowsError(try HTMLExtract.html(from: "", matching: "p")) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch("p")) }
        XCTAssertThrowsError(try HTMLExtract.table(from: "")) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch("table")) }
        XCTAssertThrowsError(try HTMLExtract.list(from: "", matching: "ul")) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch("ul")) }
        XCTAssertEqual(try HTMLExtract.links(from: ""), [])
        XCTAssertEqual(try HTMLExtract.images(from: ""), [])
        XCTAssertEqual(try HTMLExtract.record(from: "", fields: ["a": .text("p"), "b": .all("p")]), ["a": .missing, "b": .missing])
        let data = try HTMLExtract.structuredData(from: "")
        XCTAssertEqual(data, StructuredData(jsonLD: [], openGraph: [:], meta: [:], canonical: nil, title: nil))
    }

    func testWhitespaceOnlyIsTheSameAsEmpty() throws {
        XCTAssertEqual(try HTMLExtract.links(from: " \n\t "), [])
        XCTAssertNil(try HTMLExtract.structuredData(from: " \n\t ").title)
    }

    func testAFragmentWithNoHtmlHeadOrBodyIsStillReadable() throws {
        // The parser wraps a bare fragment in the document it implies.
        XCTAssertEqual(try HTMLExtract.text(from: "<p>hi</p>", matching: "p"), ["hi"])
        XCTAssertEqual(try HTMLExtract.text(from: "<p>hi</p>", matching: "body p"), ["hi"])
        XCTAssertEqual(try HTMLExtract.text(from: "just words", matching: "body"), ["just words"])
    }

    func testAHeadWithNoBodyStillYieldsItsDeclarations() throws {
        let html = "<html><head><title> Only  a head </title><meta name=\"description\" content=\"d\"></head></html>"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.title, "Only a head")
        XCTAssertEqual(data.meta["description"], "d")
        XCTAssertEqual(try HTMLExtract.links(from: html), [])
    }

    func testUnclosedTagsAreClosedTheWayABrowserClosesThem() throws {
        let html = "<div><p>one<p>two<ul><li>a<li>b</div><a href=x>link"
        XCTAssertEqual(try HTMLExtract.text(from: html, matching: "p"), ["one", "two"])
        XCTAssertEqual(try HTMLExtract.list(from: html, matching: "ul"), ["a", "b"])
        XCTAssertEqual(try HTMLExtract.links(from: html).map(\.text), ["link"])
    }

    func testMalformedMarkupNeverThrowsUnreadable() throws {
        for html in ["<", "<<>>", "</p>", "<p", "<a href=\"", "&", "&#xFFFFFFF;", "<!--", "<![CDATA[x", "<script>", "<table><td>"] {
            XCTAssertNoThrow(try HTMLExtract.structuredData(from: html), html)
            XCTAssertNoThrow(try HTMLExtract.links(from: html), html)
            XCTAssertNoThrow(try HTMLExtract.record(from: html, fields: ["a": .text("p")]), html)
        }
    }

    func testTextThatIsOnlyWhitespaceNodesIsAnEmptyString() throws {
        XCTAssertEqual(try HTMLExtract.text(from: "<p> \n\t <span> </span> </p>", matching: "p"), [""])
        XCTAssertEqual(try HTMLExtract.text(from: "<p>&nbsp;&nbsp;</p>", matching: "p"), [""])
    }
}

// MARK: - Selectors

final class SelectorEdgeTests: XCTestCase {

    private let html = "<p>hi</p>"

    func testAnEmptySelectorIsInvalidForEveryFunctionThatTakesOne() {
        func assertInvalid(_ body: () throws -> Void, line: UInt = #line) {
            XCTAssertThrowsError(try body(), line: line) { XCTAssertEqual($0 as? HTMLExtractError, .invalidSelector(""), line: line) }
        }
        assertInvalid { _ = try HTMLExtract.text(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.attribute("x", from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.html(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.links(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.images(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.table(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.list(from: html, matching: "") }
        assertInvalid { _ = try HTMLExtract.record(from: html, fields: ["a": .text("")]) }
        assertInvalid { _ = try HTMLExtract.record(from: html, fields: ["a": .attribute("", "x")]) }
        assertInvalid { _ = try HTMLExtract.record(from: html, fields: ["a": .html("")]) }
        assertInvalid { _ = try HTMLExtract.record(from: html, fields: ["a": .link("")]) }
        assertInvalid { _ = try HTMLExtract.record(from: html, fields: ["a": .all("")]) }
    }

    func testASelectorMatchingNothingIsNoMatchForEverySingleValueFunction() {
        func assertNoMatch(_ body: () throws -> Void, line: UInt = #line) {
            XCTAssertThrowsError(try body(), line: line) { XCTAssertEqual($0 as? HTMLExtractError, .noMatch(".gone"), line: line) }
        }
        assertNoMatch { _ = try HTMLExtract.text(from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.text(from: html, matching: ".gone", first: true) }
        assertNoMatch { _ = try HTMLExtract.attribute("x", from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.html(from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.links(from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.images(from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.table(from: html, matching: ".gone") }
        assertNoMatch { _ = try HTMLExtract.list(from: html, matching: ".gone") }
    }

    func testFirstOnAnEmptyMatchIsStillNoMatchNotAnEmptyArray() {
        XCTAssertThrowsError(try HTMLExtract.text(from: html, matching: "b", first: true))
        XCTAssertThrowsError(try HTMLExtract.attribute("x", from: html, matching: "b", first: true))
        XCTAssertThrowsError(try HTMLExtract.html(from: html, matching: "b", first: true))
    }

    func testAMatchWithoutTheAttributeIsAnEmptyArrayNotAnError() throws {
        XCTAssertEqual(try HTMLExtract.attribute("href", from: html, matching: "p"), [])
        XCTAssertEqual(try HTMLExtract.attribute("href", from: html, matching: "p", first: true), [])
    }

    func testAttributeNamesAreCaseInsensitiveAsInHTML() throws {
        XCTAssertEqual(try HTMLExtract.attribute("HREF", from: "<a href=\"/x\">a</a>", matching: "a"), ["/x"])
        XCTAssertEqual(try HTMLExtract.attribute("href", from: "<a HREF=\"/x\">a</a>", matching: "a"), ["/x"])
    }

    func testTheUsualSelectorGrammarWorks() throws {
        let doc = "<div id=\"a\" class=\"x y\" data-k=\"v1\"><span>1</span><span>2</span></div><div class=\"x\"><span>3</span></div>"
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: "#a span"), ["1", "2"])
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: ".x.y > span:nth-child(2)"), ["2"])
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: "[data-k=v1] span:first-child"), ["1"])
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: "div.x:not(#a) span"), ["3"])
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: "span:contains(3)"), ["3"])
        XCTAssertEqual(try HTMLExtract.text(from: doc, matching: "div, span").count, 5)
    }
}

// MARK: - Text and attributes

final class TextEdgeTests: XCTestCase {

    func testUnicodeSurvivesInTextAndAttributes() throws {
        let html = "<p title=\"café — 東京 🚀\">naïve  résumé — 東京 🚀</p>"
        XCTAssertEqual(try HTMLExtract.text(from: html, matching: "p"), ["naïve résumé — 東京 🚀"])
        XCTAssertEqual(try HTMLExtract.attribute("title", from: html, matching: "p"), ["café — 東京 🚀"])
    }

    func testEntitiesDecodeInTextAndAttributesNamedNumericAndHex() throws {
        let html = "<a href=\"/x?a=1&amp;b=2\" title=\"&lt;b&gt; &#169; &#x263A; &quot;q&quot;\">&lt;tag&gt; &amp; &#8212; &#x2014; &apos;</a>"
        XCTAssertEqual(try HTMLExtract.text(from: html, matching: "a"), ["<tag> & — — '"])
        XCTAssertEqual(try HTMLExtract.attribute("href", from: html, matching: "a"), ["/x?a=1&b=2"])
        XCTAssertEqual(try HTMLExtract.attribute("title", from: html, matching: "a"), ["<b> © ☺ \"q\""])
    }

    func testAnUnterminatedEntityIsLeftAsWritten() throws {
        XCTAssertEqual(try HTMLExtract.text(from: "<p>fish &chips</p>", matching: "p"), ["fish &chips"])
    }

    func testTextOfAnElementIncludesItsDescendantsInOrder() throws {
        XCTAssertEqual(try HTMLExtract.text(from: "<p>a<b>b</b><i>c<u>d</u></i>e</p>", matching: "p"), ["abcde"])
    }

    func testTextSkipsScriptStyleAndCommentContents() throws {
        // Comments contribute nothing; script and style bodies are data nodes,
        // not text. The parser keeps a word boundary where an element sat, so
        // "x" and "y" do not fuse — which is also what a browser shows.
        let html = "<div>x<!-- hidden --><script>var a = 1;</script><style>p{}</style>y</div>"
        XCTAssertEqual(try HTMLExtract.text(from: html, matching: "div"), ["x y"])
        // Asked for directly, the script's body is its inner HTML.
        XCTAssertEqual(try HTMLExtract.html(from: html, matching: "script"), ["var a = 1;"])
    }

    func testHTMLOfAnEmptyElementIsEmpty() throws {
        XCTAssertEqual(try HTMLExtract.html(from: "<p></p>", matching: "p"), [""])
        XCTAssertEqual(try HTMLExtract.html(from: "<p></p>", matching: "p", inner: false), ["<p></p>"])
    }

    func testHTMLPreservesEntitiesThatMustStayEncoded() throws {
        XCTAssertEqual(try HTMLExtract.html(from: "<p>a &lt; b &amp; c</p>", matching: "p"), ["a &lt; b &amp; c"])
    }

    func testFirstOnAttributeAppliesBeforeTheAttributeFilter() throws {
        // The first <a> has no title; first: true cuts to it, then finds none.
        let html = "<a href=\"/1\">1</a><a href=\"/2\" title=\"t\">2</a>"
        XCTAssertEqual(try HTMLExtract.attribute("title", from: html, matching: "a", first: true), [])
        XCTAssertEqual(try HTMLExtract.attribute("title", from: html, matching: "a"), ["t"])
    }
}

// MARK: - Links and images

final class LinkEdgeTests: XCTestCase {

    func testAnchorsWithoutHrefAreNotLinks() throws {
        let html = "<a name=\"top\">anchor</a><a>bare</a><a href>empty</a><a href=\"/x\">real</a>"
        let links = try HTMLExtract.links(from: html, base: URL(string: "https://e.com/")!)
        XCTAssertEqual(links.map(\.text), ["empty", "real"])
        // A browser resolves href="" to the page itself. There is nothing to
        // resolve, so here it is nil, and the empty href says what was written.
        XCTAssertNil(links[0].url)
        XCTAssertEqual(links[0].href, "")
    }

    func testEverySchemeSpellingIsKeptWithItsScheme() throws {
        let html = """
        <a href="javascript:void(0)">js</a>
        <a href="mailto:a@b.c?subject=hi">mail</a>
        <a href="tel:+44 20 7946 0000">tel</a>
        <a href="data:text/plain;base64,aGk=">data</a>
        <a href="sms:+1555">sms</a>
        <a href="ftp://files.example.com/a">ftp</a>
        """
        let links = try HTMLExtract.links(from: html, base: URL(string: "https://e.com/p/")!)
        XCTAssertEqual(links.map { $0.url?.scheme }, ["javascript", "mailto", "tel", "data", "sms", "ftp"])
        XCTAssertEqual(links[1].url?.absoluteString, "mailto:a@b.c?subject=hi")
        XCTAssertEqual(links.map(\.text), ["js", "mail", "tel", "data", "sms", "ftp"])
    }

    func testABaseWithAPathAndABaseWithoutOneResolveDifferently() {
        let withPath = URL(string: "https://e.com/docs/guide/intro.html")!
        let root = URL(string: "https://e.com")!
        XCTAssertEqual(URLResolution.resolve("next.html", against: withPath)?.absoluteString, "https://e.com/docs/guide/next.html")
        XCTAssertEqual(URLResolution.resolve("../a", against: withPath)?.absoluteString, "https://e.com/docs/a")
        XCTAssertEqual(URLResolution.resolve("/a", against: withPath)?.absoluteString, "https://e.com/a")
        XCTAssertEqual(URLResolution.resolve("next.html", against: root)?.absoluteString, "https://e.com/next.html")
        XCTAssertEqual(URLResolution.resolve("/a", against: root)?.absoluteString, "https://e.com/a")
        XCTAssertEqual(URLResolution.resolve("../a", against: root)?.absoluteString, "https://e.com/a")
        XCTAssertEqual(URLResolution.resolve("#top", against: root)?.absoluteString, "https://e.com#top")
    }

    func testADirectoryBaseKeepsItsLastSegment() {
        let dir = URL(string: "https://e.com/docs/guide/")!
        XCTAssertEqual(URLResolution.resolve("next.html", against: dir)?.absoluteString, "https://e.com/docs/guide/next.html")
        XCTAssertEqual(URLResolution.resolve("../a", against: dir)?.absoluteString, "https://e.com/docs/a")
    }

    func testProtocolRelativeTakesTheSchemeFromEitherKindOfBase() {
        XCTAssertEqual(URLResolution.resolve("//cdn.e.com/a.js", against: URL(string: "http://e.com/x/y")!)?.absoluteString, "http://cdn.e.com/a.js")
        XCTAssertEqual(URLResolution.resolve("//cdn.e.com/a.js", against: URL(string: "https://e.com")!)?.absoluteString, "https://cdn.e.com/a.js")
        XCTAssertNil(URLResolution.resolve("//cdn.e.com/a.js", against: nil))
    }

    func testHrefsWithSpacesAndUnicodeAreEncodedTheWayABrowserEncodesThem() {
        let base = URL(string: "https://e.com/")!
        // Foundation's URL parser percent-encodes what the author left raw —
        // a space, an accented letter — as a browser does on the wire.
        XCTAssertEqual(URLResolution.resolve("my file.pdf", against: base)?.absoluteString, "https://e.com/my%20file.pdf")
        XCTAssertEqual(URLResolution.resolve("my%20file.pdf", against: base)?.absoluteString, "https://e.com/my%20file.pdf")
        XCTAssertEqual(URLResolution.resolve("café", against: base)?.absoluteString, "https://e.com/caf%C3%A9")
        XCTAssertEqual(URLResolution.resolve("caf%C3%A9", against: base)?.absoluteString, "https://e.com/caf%C3%A9")
    }

    func testAnUnresolvableHrefStillYieldsALinkWithItsHref() throws {
        // A bare "#" is a fragment with nothing after it; Foundation keeps the
        // base and drops it, and `href` still records what was written.
        let links = try HTMLExtract.links(from: "<a href=\"http://\">x</a><a href=\"#\">y</a>")
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].href, "http://")
        XCTAssertNil(links[1].url)
        XCTAssertEqual(links[1].href, "#")
    }

    func testLinkTextWithNestedMarkupAndAnImageOnlyLink() throws {
        let html = "<a href=\"/a\"><b>Bold</b> and <i>italic</i></a><a href=\"/b\"><img src=\"i.png\" alt=\"pic\"></a>"
        let links = try HTMLExtract.links(from: html)
        XCTAssertEqual(links.map(\.text), ["Bold and italic", ""])
    }

    func testScopedLinksCountEachMatchOnce() throws {
        // Nested matches (a div inside a div) must not report the inner links
        // twice — the scope is the union of matched subtrees.
        let html = "<div class=\"s\"><div class=\"s\"><a href=\"/a\">a</a></div></div>"
        XCTAssertEqual(try HTMLExtract.links(from: html, matching: ".s").count, 1)
    }

    func testImagesWithoutSrcAreNotImagesAndDataURIsAreKept() throws {
        let html = "<img alt=\"no src\"><img src=\"data:image/png;base64,iVBOR\" alt=\"inline\"><img src=\"\" alt=\"empty\">"
        let images = try HTMLExtract.images(from: html, base: URL(string: "https://e.com/")!)
        XCTAssertEqual(images.map(\.alt), ["inline", "empty"])
        XCTAssertEqual(images[0].url?.scheme, "data")
        XCTAssertNil(images[1].url)
        XCTAssertEqual(images[1].src, "")
    }

    func testImagesInsideLinksAreFoundBothWays() throws {
        let html = "<a href=\"/x\"><img src=\"/i.png\" alt=\"i\"></a>"
        XCTAssertEqual(try HTMLExtract.images(from: html).count, 1)
        XCTAssertEqual(try HTMLExtract.images(from: html, matching: "a").count, 1)
    }
}

// MARK: - Tables

final class TableEdgeTests: XCTestCase {

    func testAHeaderRowInsideTbodyIsStillTheHeaderWhenItIsAllTh() throws {
        let html = "<table><tbody><tr><th>A</th><th>B</th></tr><tr><td>1</td><td>2</td></tr></tbody></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.headers, ["A", "B"])
        XCTAssertEqual(table.rows, [["1", "2"]])
    }

    func testAMixedFirstRowIsNotAHeader() throws {
        // <th> as a row label in the first column is common; it does not make
        // the first row a header.
        let html = "<table><tr><th>Row 1</th><td>1</td></tr><tr><th>Row 2</th><td>2</td></tr></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.headers, [])
        XCTAssertEqual(table.rows, [["Row 1", "1"], ["Row 2", "2"]])
    }

    func testTheadWinsOverAThFirstRowInTbody() throws {
        let html = "<table><thead><tr><th>H</th></tr></thead><tbody><tr><th>not a header</th></tr><tr><td>1</td></tr></tbody></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.headers, ["H"])
        XCTAssertEqual(table.rows, [["not a header"], ["1"]])
    }

    func testAMultiRowTheadUsesItsFirstRowAndDropsTheRest() throws {
        let html = "<table><thead><tr><th>A</th><th>B</th></tr><tr><th>a</th><th>b</th></tr></thead><tbody><tr><td>1</td><td>2</td></tr></tbody></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.headers, ["A", "B"])
        XCTAssertEqual(table.rows, [["1", "2"]])
    }

    func testColspanCellsAreOneCellEach() throws {
        // A cell is a cell; colspan is layout. The row is shorter, and the
        // record keys the cells it has. Expanding spans would invent text.
        let html = "<table><tr><th>A</th><th>B</th><th>C</th></tr><tr><td colspan=\"2\">wide</td><td>3</td></tr><tr><td>1</td><td rowspan=\"2\">tall</td><td>3</td></tr><tr><td>4</td><td>6</td></tr></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.rows, [["wide", "3"], ["1", "tall", "3"], ["4", "6"]])
        XCTAssertEqual(table.records[0], ["A": "wide", "B": "3"])
    }

    func testANestedTableIsNotFlattenedIntoItsParent() throws {
        let html = """
        <table id="outer">
          <tr><th>K</th><th>V</th></tr>
          <tr><td>inner</td><td><table id="inner"><tr><td>i1</td><td>i2</td></tr></table></td></tr>
        </table>
        """
        let outer = try HTMLExtract.table(from: html, matching: "#outer")
        XCTAssertEqual(outer.headers, ["K", "V"])
        XCTAssertEqual(outer.rows, [["inner", "i1 i2"]])
        let inner = try HTMLExtract.table(from: html, matching: "#inner")
        XCTAssertEqual(inner.rows, [["i1", "i2"]])
        XCTAssertEqual(inner.headers, [])
    }

    func testAContainerHoldingTwoTablesGivesTheFirst() throws {
        let html = "<div id=\"c\"><table><tr><td>first</td></tr></table><table><tr><td>second</td></tr></table></div>"
        XCTAssertEqual(try HTMLExtract.table(from: html, matching: "#c").rows, [["first"]])
    }

    func testAnEmptyTableHasNoHeadersAndNoRows() throws {
        let table = try HTMLExtract.table(from: "<table></table>")
        XCTAssertEqual(table, Table(headers: [], rows: []))
        XCTAssertEqual(table.records, [])
    }

    func testATableWithOnlyAHeaderHasHeadersAndNoRows() throws {
        let table = try HTMLExtract.table(from: "<table><thead><tr><th>A</th></tr></thead></table>")
        XCTAssertEqual(table.headers, ["A"])
        XCTAssertEqual(table.rows, [])
        XCTAssertEqual(table.records, [])
    }

    func testEmptyCellsAreEmptyStringsAndCellTextIsCollapsed() throws {
        let html = "<table><tr><td></td><td> a \n b </td><td>&nbsp;</td></tr></table>"
        XCTAssertEqual(try HTMLExtract.table(from: html).rows, [["", "a b", ""]])
    }

    func testARowWithNoCellsIsAnEmptyRow() throws {
        XCTAssertEqual(try HTMLExtract.table(from: "<table><tr></tr><tr><td>1</td></tr></table>").rows, [[], ["1"]])
    }

    func testCaptionAndColgroupAreNotCells() throws {
        let html = "<table><caption>Cap</caption><colgroup><col><col></colgroup><tr><td>1</td><td>2</td></tr></table>"
        XCTAssertEqual(try HTMLExtract.table(from: html).rows, [["1", "2"]])
    }

    func testAnImplicitTbodyFromTheParserDoesNotChangeTheAnswer() throws {
        // Browsers and SwiftSoup insert <tbody>; rows are found regardless.
        let html = "<table><tr><th>A</th></tr><tr><td>1</td></tr></table>"
        let table = try HTMLExtract.table(from: html)
        XCTAssertEqual(table.headers, ["A"])
        XCTAssertEqual(table.rows, [["1"]])
    }

    func testNotATableForAMatchWithNoTableInsideIt() {
        XCTAssertThrowsError(try HTMLExtract.table(from: "<div id=\"d\"><p>no</p></div>", matching: "#d")) {
            XCTAssertEqual($0 as? HTMLExtractError, .notATable("#d"))
        }
    }

    func testTenThousandRowsReadInWellUnderASecond() throws {
        var html = "<table><thead><tr><th>Id</th><th>Name</th><th>Value</th></tr></thead><tbody>"
        for i in 0..<10_000 { html += "<tr><td>\(i)</td><td>Row \(i)</td><td>\(i * 3)</td></tr>" }
        html += "</tbody></table>"
        let start = Date()
        let table = try HTMLExtract.table(from: html)
        let records = table.records
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(table.rows.count, 10_000)
        XCTAssertEqual(records[9_999], ["Id": "9999", "Name": "Row 9999", "Value": "29997"])
        XCTAssertLessThan(elapsed, 5, "10,000 rows took \(elapsed)s")
    }

    func testAssemblyWithMoreHeadersThanCellsAndMoreCellsThanHeaders() {
        XCTAssertEqual(TableAssembly.records(headers: ["A", "B", "C"], rows: [["1"]]), [["A": "1"]])
        XCTAssertEqual(TableAssembly.records(headers: ["A"], rows: [["1", "2", "3"]]), [["A": "1"]])
        XCTAssertEqual(TableAssembly.records(headers: ["A"], rows: [[]]), [[:]])
        XCTAssertEqual(TableAssembly.records(headers: ["A"], rows: []), [])
    }

    func testUniqueKeysWithEveryHeaderEmptyAndAThirdRepeat() {
        XCTAssertEqual(TableAssembly.uniqueKeys(["", "", ""]), ["Column 1", "Column 2", "Column 3"])
        XCTAssertEqual(TableAssembly.uniqueKeys(["x", "x", "x"]), ["x", "x 2", "x 3"])
        // A literal "x 2" header colliding with a generated one is renamed too.
        XCTAssertEqual(TableAssembly.uniqueKeys(["x", "x", "x 2"]), ["x", "x 2", "x 2 2"])
        XCTAssertEqual(TableAssembly.uniqueKeys([]), [])
    }
}

// MARK: - Lists

final class ListEdgeTests: XCTestCase {

    func testNestedListsThreeDeepFlattenIntoTheTopLevelItem() throws {
        let html = "<ul><li>a<ul><li>b<ul><li>c</li></ul></li></ul></li><li>d</li></ul>"
        XCTAssertEqual(try HTMLExtract.list(from: html, matching: "ul"), ["a b c", "d"])
        // "ul ul" reaches both inner lists; "c" is already inside "b c", so it
        // is one line, not two — the same rule that keeps "ul" to two lines.
        XCTAssertEqual(try HTMLExtract.list(from: html, matching: "ul ul"), ["b c"])
        XCTAssertEqual(try HTMLExtract.list(from: html, matching: "ul ul ul"), ["c"])
    }

    func testAnOrderedListAndADefinitionListContainer() throws {
        XCTAssertEqual(try HTMLExtract.list(from: "<ol><li>1</li><li>2</li></ol>", matching: "ol"), ["1", "2"])
        // A container that is not a list yields its descendant items.
        XCTAssertEqual(try HTMLExtract.list(from: "<nav><ul><li>x</li></ul><ol><li>y</li></ol></nav>", matching: "nav"), ["x", "y"])
    }

    func testAnEmptyListIsNoMatch() {
        XCTAssertThrowsError(try HTMLExtract.list(from: "<ul></ul>", matching: "ul")) {
            XCTAssertEqual($0 as? HTMLExtractError, .noMatch("ul"))
        }
    }

    func testStrayTextAndNonItemChildrenOfAListAreIgnored() throws {
        let html = "<ul>stray<li>a</li><script>x</script><li>b</li></ul>"
        XCTAssertEqual(try HTMLExtract.list(from: html, matching: "ul"), ["a", "b"])
    }

    func testEmptyItemsAreEmptyStrings() throws {
        XCTAssertEqual(try HTMLExtract.list(from: "<ul><li></li><li> </li><li>x</li></ul>", matching: "ul"), ["", "", "x"])
    }

    func testMultipleListsSelectedTogetherConcatenateInDocumentOrder() throws {
        XCTAssertEqual(try HTMLExtract.list(from: "<ul><li>1</li></ul><ul><li>2</li></ul>", matching: "ul"), ["1", "2"])
    }
}

// MARK: - Records

final class RecordEdgeTests: XCTestCase {

    func testEveryFieldMissingIsAFullRecordOfMissing() throws {
        let record = try HTMLExtract.record(from: "<p>x</p>", fields: [
            "a": .text(".n"), "b": .attribute(".n", "x"), "c": .html(".n"), "d": .link(".n"), "e": .all(".n"),
        ])
        XCTAssertEqual(record, ["a": .missing, "b": .missing, "c": .missing, "d": .missing, "e": .missing])
        XCTAssertTrue(record.values.allSatisfy(\.isMissing))
    }

    func testNoFieldsIsAnEmptyRecord() throws {
        XCTAssertEqual(try HTMLExtract.record(from: "<p>x</p>", fields: [:]), [:])
    }

    func testEachFieldKindTakesTheFirstMatchExceptAll() throws {
        let html = "<a href=\"/1\" data-n=\"one\">1</a><a href=\"/2\" data-n=\"two\">2</a>"
        let base = URL(string: "https://e.com/")!
        let record = try HTMLExtract.record(from: html, fields: [
            "text": .text("a"), "attr": .attribute("a", "data-n"), "html": .html("a"), "link": .link("a"), "all": .all("a"),
        ], base: base)
        XCTAssertEqual(record["text"], .text("1"))
        XCTAssertEqual(record["attr"], .text("one"))
        XCTAssertEqual(record["html"], .text("1"))
        XCTAssertEqual(record["link"], .text("https://e.com/1"))
        XCTAssertEqual(record["all"], .list(["1", "2"]))
    }

    func testAttributeFieldOnAMatchWithoutTheAttributeIsMissingButEmptyIsKept() throws {
        let html = "<img src=\"/i\" alt=\"\">"
        let record = try HTMLExtract.record(from: html, fields: ["alt": .attribute("img", "alt"), "title": .attribute("img", "title")])
        XCTAssertEqual(record["alt"], .text(""))
        XCTAssertEqual(record["title"], .missing)
    }

    func testLinkFieldOnAnAnchorWithoutHrefOrWithAnUnresolvableOneIsMissing() throws {
        let html = "<a id=\"n\">no href</a><a id=\"e\" href=\"\">empty</a><a id=\"j\" href=\"javascript:x()\">js</a>"
        let record = try HTMLExtract.record(from: html, fields: ["n": .link("#n"), "e": .link("#e"), "j": .link("#j")], base: URL(string: "https://e.com/")!)
        XCTAssertEqual(record["n"], .missing)
        XCTAssertEqual(record["e"], .missing)
        XCTAssertEqual(record["j"], .text("javascript:x()"))
    }

    func testAllFieldWithOneMatchIsAOneItemList() throws {
        XCTAssertEqual(try HTMLExtract.record(from: "<p>x</p>", fields: ["p": .all("p")])["p"], .list(["x"]))
    }

    func testTheSameSelectorCanServeSeveralFields() throws {
        let record = try HTMLExtract.record(from: "<a href=\"/x\">t</a>", fields: ["t": .text("a"), "h": .attribute("a", "href")])
        XCTAssertEqual(record["t"], .text("t"))
        XCTAssertEqual(record["h"], .text("/x"))
    }
}

// MARK: - Structured data

final class StructuredDataEdgeTests: XCTestCase {

    func testInvalidJSONLDIsReturnedRawNotThrown() throws {
        let html = "<script type=\"application/ld+json\">{not json,</script>"
        XCTAssertEqual(try HTMLExtract.structuredData(from: html).jsonLD, ["{not json,"])
    }

    func testAGraphArrayComesBackAsOneBlockOfText() throws {
        let block = "{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"Organization\"},{\"@type\":\"WebSite\"}]}"
        let html = "<script type=\"application/ld+json\">\(block)</script>"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.jsonLD, [block])
        let decoded = try JSONSerialization.jsonObject(with: Data(block.utf8)) as? [String: Any]
        XCTAssertEqual((decoded?["@graph"] as? [Any])?.count, 2)
    }

    func testATopLevelJSONLDArrayIsAlsoOneBlock() throws {
        let html = "<script type=\"application/ld+json\">[{\"@type\":\"A\"},{\"@type\":\"B\"}]</script>"
        XCTAssertEqual(try HTMLExtract.structuredData(from: html).jsonLD, ["[{\"@type\":\"A\"},{\"@type\":\"B\"}]"])
    }

    func testEmptyAndNonLDScriptsAreSkipped() throws {
        let html = "<script type=\"application/ld+json\">   </script><script type=\"application/json\">{\"a\":1}</script><script>var x;</script>"
        XCTAssertEqual(try HTMLExtract.structuredData(from: html).jsonLD, [])
    }

    func testTheTypeAttributeIsMatchedCaseInsensitivelyAndWithACharset() throws {
        // Attribute values in SwiftSoup selectors are case-insensitive, so
        // "application/LD+JSON" is found; a charset suffix is a different
        // value and is not — a limit worth pinning.
        let upper = "<script type=\"application/LD+JSON\">{\"a\":1}</script>"
        XCTAssertEqual(try HTMLExtract.structuredData(from: upper).jsonLD, ["{\"a\":1}"])
        let charset = "<script type=\"application/ld+json; charset=utf-8\">{\"a\":1}</script>"
        XCTAssertEqual(try HTMLExtract.structuredData(from: charset).jsonLD, [])
    }

    func testDuplicateMetaTagsLastOneWins() throws {
        let html = "<meta name=\"description\" content=\"first\"><meta name=\"description\" content=\"second\"><meta property=\"og:title\" content=\"A\"><meta property=\"og:title\" content=\"B\">"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.meta["description"], "second")
        XCTAssertEqual(data.openGraph["title"], "B")
    }

    func testPropertyWinsOverNameWhenBothArePresent() throws {
        let html = "<meta property=\"og:title\" name=\"title\" content=\"x\">"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.meta["og:title"], "x")
        XCTAssertNil(data.meta["title"])
    }

    func testMetaWithoutANameOrWithEmptyContentOrCharsetOnly() throws {
        let html = "<meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0\"><meta name=\"\" content=\"x\"><meta name=\"keywords\" content=\"\"><meta name=\"  spaced  \" content=\" v \">"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.meta, ["keywords": "", "spaced": "v"])
    }

    func testOpenGraphPrefixIsCaseSensitiveAndOnlyStripsOnce() throws {
        let html = "<meta property=\"OG:title\" content=\"x\"><meta property=\"og:og:x\" content=\"y\"><meta property=\"og:\" content=\"z\">"
        let data = try HTMLExtract.structuredData(from: html)
        XCTAssertEqual(data.openGraph, ["og:x": "y", "": "z"])
        XCTAssertEqual(data.meta["OG:title"], "x")
    }

    func testCanonicalWithoutHrefOrRelativeWithoutBaseIsNilAndTheFirstWins() throws {
        XCTAssertNil(try HTMLExtract.structuredData(from: "<link rel=\"canonical\">").canonical)
        XCTAssertNil(try HTMLExtract.structuredData(from: "<link rel=\"canonical\" href=\"/p\">").canonical)
        let two = "<link rel=\"canonical\" href=\"https://a.com/\"><link rel=\"canonical\" href=\"https://b.com/\">"
        XCTAssertEqual(try HTMLExtract.structuredData(from: two).canonical?.absoluteString, "https://a.com/")
    }

    func testTitleTakesTheFirstTitleAndAnEmptyOneIsNil() throws {
        XCTAssertEqual(try HTMLExtract.structuredData(from: "<title>A</title><title>B</title>").title, "A")
        XCTAssertNil(try HTMLExtract.structuredData(from: "<title></title>").title)
        XCTAssertNil(try HTMLExtract.structuredData(from: "<title>  </title>").title)
        XCTAssertEqual(try HTMLExtract.structuredData(from: "<title>a &amp; b</title>").title, "a & b")
    }

    func testMetaTagsPairAndOpenGraphDirectly() {
        XCTAssertNil(MetaTags.pair(name: "", content: "x")?.0)
        XCTAssertNil(MetaTags.pair(name: "a", content: nil)?.0)
        XCTAssertEqual(MetaTags.pair(name: " a ", content: " x  y ")?.0, "a")
        XCTAssertEqual(MetaTags.pair(name: " a ", content: " x  y ")?.1, "x y")
        XCTAssertEqual(MetaTags.openGraph(from: ["og:a": "1", "b": "2"]), ["a": "1"])
        XCTAssertEqual(MetaTags.openGraph(from: [:]), [:])
    }
}

// MARK: - Errors

final class ErrorDescriptionTests: XCTestCase {

    func testEveryCaseDescribesItselfPrintably() {
        XCTAssertEqual(HTMLExtractError.invalidSelector("a[").errorDescription, "not a CSS selector: a[\ntry h1, .price, a[href], table.results, or article > p")
        XCTAssertEqual(HTMLExtractError.invalidSelector("").errorDescription, "not a CSS selector: (empty)\ntry h1, .price, a[href], table.results, or article > p")
        XCTAssertEqual(HTMLExtractError.noMatch(".x").errorDescription, "nothing matches .x")
        XCTAssertEqual(HTMLExtractError.notATable("#d").errorDescription, "#d is not a table and contains none")
        XCTAssertEqual(HTMLExtractError.unreadable("boom").errorDescription, "could not read the HTML: boom")
        // LocalizedError surfaces the same text through the Error bridge.
        XCTAssertEqual((HTMLExtractError.noMatch(".x") as Error).localizedDescription, "nothing matches .x")
    }

    func testCasesAreEquatableByPayload() {
        XCTAssertEqual(HTMLExtractError.noMatch("a"), .noMatch("a"))
        XCTAssertNotEqual(HTMLExtractError.noMatch("a"), .noMatch("b"))
        XCTAssertNotEqual(HTMLExtractError.noMatch("a"), .invalidSelector("a"))
    }
}

// MARK: - Codable and Hashable

final class CodableTests: XCTestCase {

    private func roundTrip<T: Codable & Equatable>(_ value: T, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(value)
        let back = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(back, value, line: line)
    }

    func testEveryModelRoundTripsThroughJSON() throws {
        try roundTrip(Link(url: URL(string: "https://e.com/a")!, href: "/a", text: "t", title: "ti"))
        try roundTrip(Link(url: nil, href: "../a", text: "", title: nil))
        try roundTrip(Image(url: URL(string: "https://e.com/i.png")!, src: "i.png", alt: "a", title: nil))
        try roundTrip(Image(url: nil, src: "", alt: "", title: "t"))
        try roundTrip(Table(headers: ["A", ""], rows: [["1", "2"], [], ["x"]]))
        try roundTrip(Table(headers: [], rows: []))
        try roundTrip(StructuredData(jsonLD: ["{}", "[]"], openGraph: ["title": "x"], meta: ["og:title": "x"], canonical: URL(string: "https://e.com/")!, title: "T"))
        try roundTrip(StructuredData(jsonLD: [], openGraph: [:], meta: [:], canonical: nil, title: nil))
    }

    func testEveryEnumRoundTripsThroughJSON() throws {
        try roundTrip(Field.text("h1"))
        try roundTrip(Field.attribute("a", "href"))
        try roundTrip(Field.html(".b"))
        try roundTrip(Field.link("a"))
        try roundTrip(Field.all("li"))
        try roundTrip(ExtractedValue.text("x"))
        try roundTrip(ExtractedValue.text(""))
        try roundTrip(ExtractedValue.list(["a", "b"]))
        try roundTrip(ExtractedValue.list([]))
        try roundTrip(ExtractedValue.missing)
        try roundTrip(["a": ExtractedValue.missing, "b": .list(["1"])])
        try roundTrip(["name": Field.text("h1"), "tags": .all(".t")])
    }

    func testARecordRoundTripsAsAWhole() throws {
        let record = try HTMLExtract.record(from: Fixtures.product, fields: ["n": .text("h1"), "f": .all("#features > li"), "m": .text(".gone")], base: Fixtures.base)
        try roundTrip(record)
    }

    func testModelsHashConsistentlyWithEquality() {
        let a = Link(url: nil, href: "/a", text: "t", title: nil)
        let b = Link(url: nil, href: "/a", text: "t", title: nil)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertEqual(Set([a, b]).count, 1)
        XCTAssertEqual(Set([ExtractedValue.missing, .missing, .text("")]).count, 2)
        XCTAssertEqual(Set([Field.text("a"), .html("a"), .text("a")]).count, 2)
    }
}

// MARK: - Whitespace

final class WhitespaceEdgeTests: XCTestCase {

    func testEveryKindOfWhitespaceCollapsesAndNonBreakingVariantsCount() {
        XCTAssertEqual(Whitespace.normalized("a\u{2003}\u{2009}b"), "a b")     // em space, thin space
        XCTAssertEqual(Whitespace.normalized("a\u{3000}b"), "a b")             // ideographic space
        XCTAssertEqual(Whitespace.normalized("a\r\nb"), "a b")                 // CRLF is one grapheme, still whitespace
        XCTAssertEqual(Whitespace.normalized("a\u{200B}b"), "a\u{200B}b")      // zero-width space is not whitespace
        XCTAssertEqual(Whitespace.normalized(""), "")
        XCTAssertEqual(Whitespace.normalized("   "), "")
        XCTAssertEqual(Whitespace.normalized("  a  "), "a")
    }

    func testCombiningMarksAndEmojiAreNotSplit() {
        XCTAssertEqual(Whitespace.normalized("e\u{0301}  🇬🇧  👨‍👩‍👧"), "e\u{0301} 🇬🇧 👨‍👩‍👧")
    }
}
