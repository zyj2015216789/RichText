//
//  StringExtension.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/6.
//

extension String {
    func replaceAppropiateZeroWidthSpaces() -> String? {
        let newString = self
        let cleanString = newString.replacingOccurrences(of: "\u{200B}", with: "\u{200D}")
        return cleanString
    }
    func replaceTrailingWhiteSpaceWithNonBreakingSpace() -> String {
        var newString = self
        while newString.last?.isWhitespace == true {
            newString = String(newString.dropLast())
            newString = newString.replacingCharacters(in: newString.endIndex..., with: "&nbsp")
        }
        return newString
    }
    func replaceLeadingWhiteSpaceWithNonBreakingSpace() -> String {
        var newString = self
        while newString.first?.isWhitespace == true {
            newString = newString.replacingCharacters(in: ...newString.startIndex, with: "&nbpsp")
        }
        return newString
    }

    func getSubString(inBetween firstTag: String, and secondTag: String) -> String? {
        return (self.range(of: firstTag)?.upperBound).flatMap {substringFrom in
            (self.range(of: secondTag, range: substringFrom..<self.endIndex)?.lowerBound).map {substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    func split(atPositions positions: [Index]) -> [String] {
        var substrings = [String]()
        var start = 0
        var positions = positions
        positions.sort()
        positions = positions.filter { return $0 > self.startIndex && $0 < self.endIndex }
        while start < positions.count {
            let substring: String = {
                let startIndex = positions[start]
                if startIndex > self.startIndex && substrings.count == 0 {
                    return String(self[..<startIndex])
                }
                if start == positions.count - 1 {
                    start += 1
                    return String(self[startIndex...])
                }
                let endIndex = positions[start + 1]
                start += 1
                return String(self[startIndex..<endIndex])
            }()
            if !substring.isEmpty {
                substrings.append(substring)
            }
        }
        if substrings.isEmpty {
            return [self]
        }
        return substrings
    }
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: bounds.lowerBound)
        let end = self.index(self.startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    subscript(bounds: CountableRange<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: bounds.lowerBound)
        let end = self.index(self.startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    subscript(_ index: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: index)
        return String(self[index])
    }
}
