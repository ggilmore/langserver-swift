//
//  LineCollection.swift
//  langserver-swift
//
//  Created by Ryan Lovelett on 11/22/16.
//
//

import Foundation

fileprivate let lf: UInt8 = 0x0A

fileprivate func buildLineRangeCollection(from data: Data) -> [Range<Data.Index>] {
    var array: [Range<Data.Index>] = []
    var lower: Data.Index = data.startIndex
    for (upper, datum) in data.enumerated() where datum == lf {
        array.append(Range<Data.Index>(lower...upper))
        // The next lowest is greater than the current index
        lower = (upper + 1)
    }
    return array
}

struct LineCollection {

    let data: Data

    let lines: [Range<Data.Index>]

    init(for file: URL) throws {
        data = try Data(contentsOf: file, options: .mappedIfSafe)
        lines = buildLineRangeCollection(from: data)
    }

    init?(for string: String) {
        guard let d = string.data(using: .utf8) else {
            return nil
        }
        data = d
        lines = buildLineRangeCollection(from: data)
    }

    func byteOffset(at: Position) throws -> Int {
        guard at.line < lines.count else { throw WorkspaceError.positionNotFound }
        let lineRange = lines[at.line]
        let offset = lineRange.lowerBound.advanced(by: at.character)
        guard offset < lineRange.upperBound else { throw WorkspaceError.positionNotFound }
        return offset
    }

    func position(for offset: Int) throws -> Position {
        guard let lineIndex = lines.index(where: { $0.contains(offset) }) else { throw WorkspaceError.positionNotFound }
        let lineRange = lines[lineIndex]
        let x = offset - lineRange.lowerBound
        let position = Position(line: lineIndex, character: x)
        return position
    }

    func selection(startAt offset: Int, length: Int) throws -> TextDocumentRange {
        let endOffset = Int(offset + length)
        let start = try position(for: offset)
        let end = try position(for: endOffset)
        return TextDocumentRange(start: start, end: end)
    }

}
