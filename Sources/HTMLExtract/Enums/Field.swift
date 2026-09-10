//
//  Field.swift
//  HTMLExtract
//

import Foundation

/// One column of a ``HTMLExtract/record(from:fields:base:)`` request: what to
/// select and which part of the match to keep.
///
/// Every case names a selector; the first four take the first match, and
/// ``all(_:)`` takes every match. A field that matches nothing comes back as
/// ``ExtractedValue/missing`` rather than throwing, because a record is nine
/// good answers and one stale selector far more often than it is nothing.
public enum Field: Sendable, Hashable, Codable {

    /// The text of the first match, whitespace collapsed.
    case text(String)

    /// A named attribute of the first match — `href`, `src`, `data-id`.
    ///
    /// A match without the attribute is ``ExtractedValue/missing``; an empty
    /// attribute is an empty string, because `alt=""` is a statement.
    case attribute(String, String)

    /// The inner HTML of the first match, untouched.
    case html(String)

    /// The `href` of the first match, resolved to an absolute URL against
    /// the record's base. Without a base a relative link is
    /// ``ExtractedValue/missing`` rather than a fragment nobody can open.
    case link(String)

    /// The text of every match, as a list.
    case all(String)
}
