//
//  ExtractedValue+Access.swift
//  HTMLExtract
//

import Foundation

extension ExtractedValue {

    /// The single string, or `nil` for a list or a missing value.
    public var text: String? {
        if case .text(let value) = self { return value }
        return nil
    }

    /// The strings: one for ``text(_:)``, all of them for ``list(_:)``, none
    /// for ``missing``.
    public var values: [String] {
        switch self {
        case .text(let value): return [value]
        case .list(let values): return values
        case .missing: return []
        }
    }

    /// Whether the field found anything.
    public var isMissing: Bool {
        if case .missing = self { return true }
        return false
    }
}
