//
//  Table.swift
//  HTMLExtract
//

import Foundation

/// A `<table>` read into cells.
///
/// ``headers`` come from `<thead>`, or from a first row made of `<th>` cells
/// when there is no `<thead>`; a table with neither has no headers and its
/// ``rows`` are everything. Cell text is whitespace-collapsed. Rows keyed by
/// header are ``records``.
public struct Table: Sendable, Hashable, Codable {

    /// The header cells, in column order. Empty when the table has none.
    public let headers: [String]

    /// Every body row, each a list of cell text in column order.
    ///
    /// Rows are not padded or truncated to the header count — a ragged
    /// table stays ragged here, and ``records`` copes.
    public let rows: [[String]]

    /// A table as read from the document.
    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }
}
