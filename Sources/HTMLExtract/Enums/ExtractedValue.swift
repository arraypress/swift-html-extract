//
//  ExtractedValue.swift
//  HTMLExtract
//

import Foundation

/// What one ``Field`` produced.
///
/// Three shapes and no optional, so a caller switches once and is done. A
/// missing field is a value, not an error and not `nil` — it goes into a
/// dictionary, a JSON row or a log line without a special case.
public enum ExtractedValue: Sendable, Hashable, Codable {

    /// One string: text, an attribute, HTML, or a resolved link.
    case text(String)

    /// Several strings, from ``Field/all(_:)``.
    case list([String])

    /// The selector matched nothing, or the match lacked what was asked for.
    case missing
}
