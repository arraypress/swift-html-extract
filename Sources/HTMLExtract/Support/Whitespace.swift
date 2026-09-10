//
//  Whitespace.swift
//  HTMLExtract
//
//  Text as a person reads it, not as the markup was indented.
//

import Foundation

/// Collapsing the whitespace that HTML authors never meant.
enum Whitespace {

    /// Runs of any whitespace — spaces, tabs, newlines, and the no-break space
    /// that `&nbsp;` decodes to — become one space, and the ends are trimmed.
    ///
    /// A pretty-printed `<p>` carries the newline and eight spaces of its
    /// indentation inside the text node, and a price split across a line
    /// break reads as `£12\n        .99`. The browser collapses all of it
    /// before anyone sees it; this does the same. The no-break space is
    /// included because `1&nbsp;234` is a thousand-separated number, and a
    /// consumer that compares it to `"1 234"` should get a match.
    static func normalized(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var pendingSpace = false
        for character in text {
            if character.isWhitespace {
                pendingSpace = !result.isEmpty
            } else {
                if pendingSpace {
                    result.append(" ")
                    pendingSpace = false
                }
                result.append(character)
            }
        }
        return result
    }
}
