//
//  HTMLExtractError.swift
//  HTMLExtract
//

import Foundation

/// What went wrong, in words a caller can print unchanged.
public enum HTMLExtractError: Error, LocalizedError, Equatable, Sendable {

    /// The selector is not CSS the parser can read — an unbalanced bracket,
    /// an empty string, a pseudo-class that does not exist.
    case invalidSelector(String)

    /// The selector is valid and matched nothing in this document.
    ///
    /// Thrown by the single-purpose functions only. ``HTMLExtract/record(from:fields:base:)``
    /// reports a missing field as ``ExtractedValue/missing`` instead, so one
    /// wrong selector cannot sink the other nine.
    case noMatch(String)

    /// The selector matched, but neither the element nor anything inside it
    /// is a `<table>`.
    case notATable(String)

    /// The parser could not read the text as HTML at all — which takes
    /// effort, since HTML parsers are built to swallow almost anything.
    case unreadable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSelector(let selector):
            return "not a CSS selector: \(selector.isEmpty ? "(empty)" : selector)\ntry h1, .price, a[href], table.results, or article > p"
        case .noMatch(let selector):
            return "nothing matches \(selector)"
        case .notATable(let selector):
            return "\(selector) is not a table and contains none"
        case .unreadable(let reason):
            return "could not read the HTML: \(reason)"
        }
    }
}
