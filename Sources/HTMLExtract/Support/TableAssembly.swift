//
//  TableAssembly.swift
//  HTMLExtract
//
//  From cells in column order to rows a caller can address by name.
//

import Foundation

/// Building ``Table/records`` out of headers and rows.
enum TableAssembly {

    /// Each row as a dictionary keyed by its header.
    ///
    /// Three things a `zip` gets wrong:
    ///
    /// - **An empty header** is named `Column N` (1-based), so the column is
    ///   reachable instead of every unlabelled column landing on the key `""`.
    /// - **A repeated header** — two `Total` columns — gets a suffix from the
    ///   second onwards (`Total`, `Total 2`), so neither overwrites the other.
    /// - **A ragged row** keeps the cells it has: a short row omits the
    ///   trailing keys, a long row drops the cells past the last header.
    ///
    /// A table with no headers has no records; ``Table/rows`` is the
    /// only honest reading of it.
    static func records(headers: [String], rows: [[String]]) -> [[String: String]] {
        guard !headers.isEmpty else { return [] }
        let keys = uniqueKeys(headers)
        return rows.map { row in
            var record: [String: String] = [:]
            for (key, cell) in zip(keys, row) {
                record[key] = cell
            }
            return record
        }
    }

    /// Header names made unique and non-empty, in column order.
    ///
    /// A generated name can collide with one the author wrote — a `Total`
    /// twice and a literal `Total 2` — so a candidate is checked against
    /// every key taken so far, not only against its own count.
    static func uniqueKeys(_ headers: [String]) -> [String] {
        var taken = Set<String>()
        var keys: [String] = []
        for (index, header) in headers.enumerated() {
            let name = header.isEmpty ? "Column \(index + 1)" : header
            var candidate = name
            var suffix = 2
            while taken.contains(candidate) {
                candidate = "\(name) \(suffix)"
                suffix += 1
            }
            taken.insert(candidate)
            keys.append(candidate)
        }
        return keys
    }
}
