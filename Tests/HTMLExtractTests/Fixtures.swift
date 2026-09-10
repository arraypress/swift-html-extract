//
//  Fixtures.swift
//  HTMLExtract
//
//  Documents with known contents, so every test has one right answer.
//

import Foundation

enum Fixtures {

    /// A product page with the usual furniture: relative links, a scheme-
    /// relative script, pretty-printed text, an entity, Open Graph, JSON-LD.
    static let product = """
    <!doctype html>
    <html>
    <head>
      <title>
        Widget &amp; Sons — Blue Widget
      </title>
      <link rel="canonical" href="/products/blue-widget">
      <meta name="description" content="A   blue widget, with  extra
        spaces.">
      <meta property="og:title" content="Blue Widget">
      <meta property="og:image" content="https://cdn.example.com/blue.jpg">
      <meta name="twitter:card" content="summary">
      <meta name="robots">
      <script type="application/ld+json">
        {"@context":"https://schema.org","@type":"Product","name":"Blue Widget","offers":{"price":"12.99"}}
      </script>
      <script type="application/ld+json">{"@type":"BreadcrumbList"}</script>
      <script src="//cdn.example.com/app.js"></script>
    </head>
    <body>
      <h1>
        Blue
        Widget
      </h1>
      <p class="price">£12<span>.99</span></p>
      <p class="tagline">Widgets &amp; gadgets, 1&nbsp;234 sold</p>
      <a id="buy" class="button" href="../checkout?sku=blue" title="Buy now">Buy</a>
      <a href="#reviews">Reviews</a>
      <a href="mailto:sales@example.com">Email us</a>
      <a href="https://other.example.org/x">Elsewhere</a>
      <a href="javascript:void(0)">Nothing</a>
      <img src="images/blue.png" alt="The   blue widget" title="Blue">
      <img src="https://cdn.example.com/badge.png" alt="">
      <ul id="features">
        <li>Waterproof</li>
        <li>Two colours
          <ul><li>Blue</li><li>Bluer</li></ul>
        </li>
        <li>Guaranteed</li>
      </ul>
      <div id="specs">
        <table>
          <thead><tr><th>Name</th><th>Value</th><th></th><th>Value</th></tr></thead>
          <tbody>
            <tr><td>Weight</td><td>1.2 kg</td><td>a</td><td>x</td></tr>
            <tr><td>Width</td><td>10 cm</td></tr>
          </tbody>
          <tfoot><tr><td>Total</td><td>2 rows</td><td>b</td><td>y</td></tr></tfoot>
        </table>
      </div>
      <table id="plain">
        <tr><th>City</th><th>Pop</th></tr>
        <tr><td>Leeds</td><td>800k</td></tr>
      </table>
      <table id="bare">
        <tr><td>1</td><td>2</td></tr>
        <tr><td>3</td><td>4</td></tr>
      </table>
      <p class="empty"></p>
    </body>
    </html>
    """

    static let base = URL(string: "https://shop.example.com/products/blue-widget")!
}
