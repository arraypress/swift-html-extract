//
//  Table+Records.swift
//  HTMLExtract
//

import Foundation

extension Table {

    /// Each row as a dictionary keyed by header — see ``TableAssembly`` for
    /// how empty, repeated and ragged columns are handled.
    ///
    /// Empty when the table has no headers.
    public var records: [[String: String]] {
        TableAssembly.records(headers: headers, rows: rows)
    }
}
